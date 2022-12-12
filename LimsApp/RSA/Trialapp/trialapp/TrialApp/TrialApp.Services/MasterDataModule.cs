using SQLite;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using TrialApp.Common;
using TrialApp.DataAccess;
using TrialApp.Entities;
using TrialApp.Entities.Master;
using TrialApp.Entities.ServiceResponse;
using TrialApp.ServiceClient;

namespace TrialApp.Services
{
    public class MasterDataModule
    {
        private static Dictionary<string, string> dictTableSequence = new Dictionary<string, string>();
        private static int recordsFrmWS;
        private SequenceTableService sequenceTableService;
        private FieldSetService fieldSetService;
        private SoapClient soapClient;
        private readonly CropTraitRepository cropTraitRepository;
        private readonly CropLovRepository cropLovRepository;
        private readonly FieldSetRepository fieldSetRepository;
        private readonly CountryRepository countryRepository;
        private readonly CropGroupRepository cropGroupRepository;
        private readonly CropRdRepository cropRdRepository;
        private readonly EntityTypeRepository entityTypeRepository;
        private readonly PropertyOfEntityRepository propertyOfEntityRepository;
        private readonly TraitRepository traitRepository;
        private readonly TraitInFieldSetRepository traitInFieldSetRepository;
        private readonly TraitTypeRepository traitTypeRepository;
        private readonly TrialRegionRepository trialRegionRepository;
        private readonly TrialTypeRepository trialTypeRepository;
        private readonly TraitValueRepository traitValueRepository;
        private readonly CropSegmentRepository cropSegmentRepository;

        public int maxVal;

        public MasterDataModule()
        {
            sequenceTableService = new SequenceTableService();
            fieldSetService = new FieldSetService();
            soapClient = WebserviceTasks.GetSoapClient();
            cropTraitRepository = new CropTraitRepository(new SQLiteAsyncConnection(DbPath.GetMasterDbPath()));
            cropLovRepository = new CropLovRepository(new SQLiteAsyncConnection(DbPath.GetMasterDbPath()));
            fieldSetRepository = new FieldSetRepository(new SQLiteAsyncConnection(DbPath.GetMasterDbPath()));
            countryRepository = new CountryRepository(new SQLiteAsyncConnection(DbPath.GetMasterDbPath()));
            cropGroupRepository = new CropGroupRepository(new SQLiteAsyncConnection(DbPath.GetMasterDbPath()));
            cropRdRepository = new CropRdRepository(new SQLiteAsyncConnection(DbPath.GetMasterDbPath()));
            entityTypeRepository = new EntityTypeRepository(new SQLiteAsyncConnection(DbPath.GetMasterDbPath()));
            propertyOfEntityRepository = new PropertyOfEntityRepository(new SQLiteAsyncConnection(DbPath.GetMasterDbPath()));
            traitRepository = new TraitRepository(new SQLiteAsyncConnection(DbPath.GetMasterDbPath()));
            traitInFieldSetRepository = new TraitInFieldSetRepository(new SQLiteAsyncConnection(DbPath.GetMasterDbPath()));
            traitTypeRepository = new TraitTypeRepository(new SQLiteAsyncConnection(DbPath.GetMasterDbPath()));
            trialRegionRepository = new TrialRegionRepository(new SQLiteAsyncConnection(DbPath.GetMasterDbPath()));
            trialTypeRepository = new TrialTypeRepository(new SQLiteAsyncConnection(DbPath.GetMasterDbPath()));
            traitValueRepository = new TraitValueRepository(new SQLiteAsyncConnection(DbPath.GetMasterDbPath()));
            cropSegmentRepository = new CropSegmentRepository(new SQLiteAsyncConnection(DbPath.GetMasterDbPath()));
        }
        public async Task<bool> getMetaInfo()
        {
            var masterTableMetaInfoReqObj = new getMetaInfoForMasterDataTables()
            {
                TablesInfo = new TablesInfo1
                {
                    tables =
                        new List<TablesName>
                        {
                                new TablesName {table = "Country"},
                                new TablesName {table = "CropGroup"},
                                new TablesName {table = "CropRD"},
                                new TablesName {table = "EntityType"},
                                new TablesName {table = "FieldSet"},
                                new TablesName {table = "PropertyOfEntity"},
                                new TablesName {table = "View_Trait_TDM"},
                                new TablesName {table = "TraitInFieldSet"},
                                new TablesName {table = "TraitType"},
                                new TablesName {table = "TrialRegion"},
                                new TablesName {table = "TrialType"},
                                new TablesName {table = "View_TraitValue_TDM"},
                                new TablesName {table = "CropSegment"},
                                new TablesName {table = "View_CropTrait_TDM"},
                                new TablesName {table = "View_CropLov_TDM"}
                        }
                }
            };

            try
            {
                var resp = await
                    soapClient.GetResponse<getMetaInfoForMasterDataTables, getMetaInfoForMasterDataTablesResponse>(
                        masterTableMetaInfoReqObj, WebserviceTasks.AdToken);
                var data = resp.Tables.Table;
                dictTableSequence.Clear();
                foreach (var _val in data)
                {
                    dictTableSequence.Add(_val.Name.Trim(), _val.MTSeqMax);
                }
                return true;
            }
            catch (Exception es)
            {
                var mgs = es.Message;
                return false;
            }
        }

        public async Task<bool> InitializeInput()
        {
            var maxNrOfRq = 2000;
            var req = new GetMasterData_V3
            {
                AppName = "TrailApp",
                DatabaseVersion = WebserviceTasks.dbVersion,
                DeviceID = DeviceInfo.GetUniqueDeviceID(),
                SoftwareVersion = WebserviceTasks.appVersion,
                UserID = WebserviceTasks.UsernameWS,
                NrOfRecords = "2000",
                onlyActiveRecords = "0",
                orderBy = "MTSeq",
                isAscending = "1"
            };

            foreach (var tableName in dictTableSequence)
            {
                if (
                    !await
                        DownloadInsertMasterData(soapClient, tableName, req, maxNrOfRq))
                {
                    return false;
                }
            }
            return true;
        }

        private async Task<bool> DownloadInsertMasterData(SoapClient client,
            KeyValuePair<string, string> tableName, GetMasterData_V3 req,
            int maxNrOfRq)
        {
            //using (var db = new SQLiteConnection(DbPath.GetMasterDbPath()))
            //{
                maxVal = await sequenceTableService.GetMaxSequence(tableName.Key);

                if (maxVal >= Convert.ToInt32(tableName.Value)) return true;
                req.MTSeq = maxVal.ToString();
                req.TableName = tableName.Key; //tableName;
                var exception = new Exception();

                try
                {
                    var result = await client.GetResponse<GetMasterData_V3, GetMasterData_V3Response>(req, WebserviceTasks.AdToken);
                    recordsFrmWS = result.GetMasterDataOutput.Tuple.Count();
                    //if (db.IsInTransaction)
                        //db.Rollback();
                    //db.BeginTransaction();
                    await ParseMasterData(result.GetMasterDataOutput.Tuple, tableName.Key);
                    await sequenceTableService.SetMaxVal(tableName.Key, maxVal);
                    //db.Commit();
                    while (recordsFrmWS == maxNrOfRq)
                    {
                        req.MTSeq = maxVal.ToString();
                        var Nextresult = await client.GetResponse<GetMasterData_V3, GetMasterData_V3Response>(req, WebserviceTasks.AdToken);
                        recordsFrmWS = Nextresult.GetMasterDataOutput.Tuple.Count();
                        if (!(Nextresult.GetMasterDataOutput.Tuple.Count == 1 && Nextresult.GetMasterDataOutput.Tuple[0].Old == null))
                        {
                            //if (db.IsInTransaction)
                            //    db.Rollback();
                            //db.BeginTransaction();
                            await ParseMasterData(Nextresult.GetMasterDataOutput.Tuple, tableName.Key);
                            await sequenceTableService.SetMaxVal(tableName.Key, maxVal);
                            //db.Commit();
                        }
                        else
                            break;
                    }
                }
                catch (Exception)
                {
                }
                return true;
            //}
        }


        public async Task<bool> getMetaInfoV2()
        {
            var masterTableMetaInfoReqObj = new GetMetaInfoForMasterDataTables_v1()
            {
                TablesInfo = new TablesInfo1
                {
                    tables =
                       new List<TablesName>
                        {
                                new TablesName {table = "Country"},
                                new TablesName {table = "CropGroup"},
                                new TablesName {table = "CropRD"},
                                new TablesName {table = "EntityType"},
                                new TablesName {table = "FieldSet"},
                                new TablesName {table = "PropertyOfEntity"},
                                new TablesName {table = "View_Trait_TDM"},
                                new TablesName {table = "TraitInFieldSet"},
                                new TablesName {table = "TraitType"},
                                new TablesName {table = "TrialRegion"},
                                new TablesName {table = "TrialType"},
                                new TablesName {table = "View_TraitValue_TDM"},
                                new TablesName {table = "CropSegment"},
                                new TablesName {table = "View_CropTrait_TDM"},
                                new TablesName {table = "View_CropLov_TDM"}
                        }
                }
            };

            try
            {
                var resp = await
                    soapClient.GetResponse<GetMetaInfoForMasterDataTables_v1, GetMetaInfoForMasterDataTables_v1Response>(
                        masterTableMetaInfoReqObj, WebserviceTasks.AdToken);
                var data = resp.Tables.Table;
                dictTableSequence.Clear();
                foreach (var _val in data)
                {
                    dictTableSequence.Add(_val.Name.Trim(), _val.MTSeqMax);
                }
                return true;
            }
            catch (Exception es)
            {
                var mgs = es.Message;
                return false;
            }
        }

        public async Task<bool> InitializeInputV2()
        {
            var maxNrOfRq = 2000;
            var req = new GetMasterData_V4
            {
                AppName = "TrailApp",
                DatabaseVersion = WebserviceTasks.dbVersion,
                DeviceID = DeviceInfo.GetUniqueDeviceID(),
                SoftwareVersion = WebserviceTasks.appVersion,
                UserID = WebserviceTasks.UsernameWS,
                NrOfRecords = "2000",
                onlyActiveRecords = "0",
                orderBy = "MTSeq",
                isAscending = "1"
            };

            foreach (var tableName in dictTableSequence)
            {
                if (
                    !await
                        DownloadInsertMasterDataV2(soapClient, tableName, req, maxNrOfRq))
                {
                    return false;
                }
            }
            return true;
        }

        private async Task<bool> DownloadInsertMasterDataV2(SoapClient client,
            KeyValuePair<string, string> tableName, GetMasterData_V4 req,
            int maxNrOfRq)
        {
            //using (var db = new SQLiteConnection(DbPath.GetMasterDbPath()))
            //{
                maxVal = await sequenceTableService.GetMaxSequence(tableName.Key);

                if (maxVal >= Convert.ToInt32(tableName.Value)) return true;
                req.MTSeq = maxVal.ToString();
                req.TableName = tableName.Key; //tableName;
                //var exception = new Exception();

                try
                {
                    var result = await client.GetResponse<GetMasterData_V4, GetMasterData_V4Response>(req, WebserviceTasks.AdToken);
                    recordsFrmWS = result.GetMasterDataOutput.Tuple.Count();
                    //if (db.IsInTransaction)
                    //    db.Rollback();
                    //db.BeginTransaction();
                    await ParseMasterData(result.GetMasterDataOutput.Tuple, tableName.Key);
                    await sequenceTableService.SetMaxVal(tableName.Key, maxVal);
                    //db.Commit();
                    while (recordsFrmWS == maxNrOfRq)
                    {
                        req.MTSeq = maxVal.ToString();
                        var Nextresult = await client.GetResponse<GetMasterData_V4, GetMasterData_V4Response>(req, WebserviceTasks.AdToken);
                        recordsFrmWS = Nextresult.GetMasterDataOutput.Tuple.Count();
                        if (!(Nextresult.GetMasterDataOutput.Tuple.Count == 1 && Nextresult.GetMasterDataOutput.Tuple[0].Old == null))
                        {
                            //if (db.IsInTransaction)
                            //    db.Rollback();
                            //db.BeginTransaction();
                            await ParseMasterData(Nextresult.GetMasterDataOutput.Tuple, tableName.Key);
                            await sequenceTableService.SetMaxVal(tableName.Key, maxVal);
                            //db.Commit();
                        }
                        else
                            break;
                    }
                }
                catch
                {
                }
                return true;
            //}
        }


        /// <summary>
        /// prepares the list of corresponding table data and inset in the db
        /// </summary>
        /// <param name="tuple : zero or more parent node "></param>
        /// <param name="sqlite connection"></param>
        /// <param name="tableName"></param>
        ///

        private async Task ParseMasterData(List<Entities.ServiceResponse.Tuple> tuple, string tableName)
        {
            switch (tableName)
            {
                case "View_CropTrait_TDM":
                    var cropTraitList = tuple.Select(t => new CropTrait()
                    {
                        CropCode = t.Old.CropTrait.CropCode,
                        TraitID = t.Old.CropTrait.TraitID,
                        MTSeq = t.Old.CropTrait.MTSeq,
                        MTStat = t.Old.CropTrait.MTStat
                    }).ToList();

                    var cropTraitINS = cropTraitList.Where(o => o.MTStat == "INS" || o.MTStat == "UPD");
                    var cropTraitDEL = cropTraitList.Where(o => o.MTStat == "DEL" || o.MTStat == "UPD");
                    //foreach (var crd in cropTraitDEL)
                    //{
                    //    db.Query<CropTrait>("delete from CropTrait where CropCode = ? and TraitID = ?", crd.CropCode, crd.TraitID);
                    //}
                    //db.InsertAll(cropTraitINS);

                    foreach (var crd in cropTraitDEL)
                    {
                        await cropTraitRepository.DbContextAsync().ExecuteScalarAsync<CropTrait>("delete from CropTrait where CropCode = ? and TraitID = ?", crd.CropCode, crd.TraitID);
                    }
                    await cropTraitRepository.DbContextAsync().InsertAllAsync(cropTraitINS);

                    maxVal = cropTraitList.Max(o => o.MTSeq);
                    break;

                case "View_CropLov_TDM":
                    var cropLovList = tuple.Select(t => new CropLov()
                    {
                        CropCode = t.Old.CropLov.CropCode,
                        TraitValueID = t.Old.CropLov.TraitValueID,
                        MTSeq = t.Old.CropLov.MTSeq,
                        MTStat = t.Old.CropLov.MTStat
                    }).ToList();

                    var cropLovINS = cropLovList.Where(o => o.MTStat == "INS" || o.MTStat == "UPD");
                    var cropLovDEL = cropLovList.Where(o => o.MTStat == "DEL" || o.MTStat == "UPD");
                    //foreach (var crd in cropLovDEL)
                    //{
                    //    db.Query<CropLov>("delete from CropLov where CropCode = ? and TraitValueID = ?", crd.CropCode, crd.TraitValueID);
                    //}
                    //db.InsertAll(cropLovINS);
                    
                    foreach (var crd in cropLovDEL)
                    {
                        await cropLovRepository.DbContextAsync().ExecuteScalarAsync<CropLov>("delete from CropLov where CropCode = ? and TraitValueID = ?", crd.CropCode, crd.TraitValueID);
                    }
                    await cropLovRepository.DbContextAsync().InsertAllAsync(cropLovINS);

                    maxVal = cropLovList.Max(o => o.MTSeq);
                    break;
                    

                case "FieldSet":
                    var fieldSetList = tuple.Select(t => new FieldSet()
                    {
                        FieldSetID = t.Old.FieldSet.FieldSetID,
                        FieldSetCode = t.Old.FieldSet.FieldSetCode,
                        FieldSetName = t.Old.FieldSet.FieldSetName,
                        CropCode = t.Old.FieldSet.CropCode,
                        Property = t.Old.FieldSet.Property,
                        NormalTrait = t.Old.FieldSet.NormalTrait,
                        MTSeq = t.Old.FieldSet.MTSeq,
                        MTStat = t.Old.FieldSet.MTStat
                    }).ToList();

                    var fieldSetINS = fieldSetList.Where(o => o.MTStat == "INS" || o.MTStat == "UPD");
                    var fieldSetDEL = fieldSetList.Where(o => o.MTStat == "DEL" || o.MTStat == "UPD");
                    //foreach (var crd in fieldSetDEL)
                    //{
                    //    db.Query<FieldSet>("delete from FieldSet where FieldSetID = ?", crd.FieldSetID);
                    //}
                    //db.InsertAll(fieldSetINS);
                    foreach (var crd in fieldSetDEL)
                    {
                        await fieldSetRepository.DbContextAsync().ExecuteScalarAsync<FieldSet>("delete from FieldSet where FieldSetID = ?", crd.FieldSetID);
                    }
                    await fieldSetRepository.DbContextAsync().InsertAllAsync(fieldSetINS);

                    maxVal = fieldSetList.Max(o => o.MTSeq);
                    break;
                case "Country":
                    var countryINS = tuple.Select(t => t.Old.Country).Where(o => o.MTStat == "INS" || o.MTStat == "UPD").Select(c => new Country
                    {
                        CountryCode = c.CountryCode,
                        CountryName = c.CountryName,
                        MTSeq = c.MTSeq
                    });
                    var countryDEL = tuple.Select(t => t.Old.Country).Where(o => o.MTStat == "DEL" || o.MTStat == "UPD");
                    //foreach (var crd in countryDEL)
                    //{
                    //    db.Query<Country>("delete from Country where CountryCode = ?", crd.CountryCode);
                    //}
                    //db.InsertAll(countryINS);
                    foreach (var crd in countryDEL)
                    {
                        await countryRepository.DbContextAsync().ExecuteScalarAsync<Country>("delete from Country where CountryCode = ?", crd.CountryCode);
                    }
                    await countryRepository.DbContextAsync().InsertAllAsync(countryINS);
                    maxVal = tuple.Select(t => t.Old.Country).Max(o => Convert.ToInt32(o.MTSeq));
                    break;
                case "CropGroup":
                    var cropGroupINS = tuple.Select(t => t.Old.CropGroup).Where(o => o.MTStat == "INS" || o.MTStat == "UPD").Select(c => new CropGroup()
                    {
                        CropGroupID = c.CropGroupID,
                        CropGroupName = c.CropGroupName,
                        MTSeq = c.MTSeq

                    });
                    var cropGroupDEL = tuple.Select(t => t.Old.CropGroup).Where(o => o.MTStat == "DEL" || o.MTStat == "UPD");

                    //foreach (var crd in cropGroupDEL)
                    //{
                    //    db.Query<CropGroup>(
                    //        "delete from CropGroup where CropGroupID = ? ", crd.CropGroupID);
                    //}
                    //db.InsertAll(cropGroupINS);
                    foreach (var crd in cropGroupDEL)
                    {
                        await cropGroupRepository.DbContextAsync().ExecuteScalarAsync<CropGroup>(
                            "delete from CropGroup where CropGroupID = ? ", crd.CropGroupID);
                    }
                    await cropGroupRepository.DbContextAsync().InsertAllAsync(cropGroupINS);
                    maxVal = tuple.Select(t => t.Old.CropGroup).Max(o => Convert.ToInt32(o.MTSeq));
                    break;
                case "CropRD":
                    var cropRdINS = tuple.Select(t => t.Old.CropRD).Where(o => o.MTStat == "INS" || o.MTStat == "UPD").Select(c => new CropRD
                    {
                        CropCode = c.CropCode,
                        CropGroupID = c.CropGroupID,
                        CropName = c.CropName,
                        MTSeq = c.MTSeq
                    });
                    var cropRdDEL = tuple.Select(t => t.Old.CropRD).Where(o => o.MTStat == "DEL" || o.MTStat == "UPD");
                    //foreach (var crd in cropRdDEL)
                    //{
                    //    db.Query<CropRD>("delete from CropRD where CropCode = ?", crd.CropCode);
                    //}
                    //db.InsertAll(cropRdINS);
                    foreach (var crd in cropRdDEL)
                    {
                        await cropRdRepository.DbContextAsync().ExecuteScalarAsync<CropRD>("delete from CropRD where CropCode = ?", crd.CropCode);
                    }
                    await cropRdRepository.DbContextAsync().InsertAllAsync(cropRdINS);
                    maxVal = tuple.Select(t => t.Old.CropRD).Max(o => Convert.ToInt32(o.MTSeq));
                    break;
                case "EntityType":
                    var entityTypeINS = tuple.Select(t => t.Old.EntityType).Where(o => o.MTStat == "INS" || o.MTStat == "UPD");
                    var entityTypeDEL = tuple.Select(t => t.Old.EntityType).Where(o => o.MTStat == "DEL" || o.MTStat == "UPD");
                    //foreach (var crd in entityTypeDEL)
                    //{
                    //    db.Query<EntityType>("delete from EntityType where EntityTypeCode = ?", crd.EntityTypeCode);
                    //}
                    //db.InsertAll(entityTypeINS);
                    foreach (var crd in entityTypeDEL)
                    {
                        await entityTypeRepository.DbContextAsync().ExecuteScalarAsync<EntityType>("delete from EntityType where EntityTypeCode = ?", crd.EntityTypeCode);
                    }
                    await entityTypeRepository.DbContextAsync().InsertAllAsync(entityTypeINS);

                    maxVal = tuple.Select(t => t.Old.EntityType).Max(o => Convert.ToInt32(o.MTSeq));
                    break;
                case "PropertyOfEntity":
                    var propertyOfEntityINS = tuple.Select(t => t.Old.PropertyOfEntity).Where(o => o.MTStat == "INS" || o.MTStat == "UPD");
                    var propertyOfEntityDEL = tuple.Select(t => t.Old.PropertyOfEntity).Where(o => o.MTStat == "DEL" || o.MTStat == "UPD");
                    //foreach (var crd in propertyOfEntityDEL)
                    //{
                    //    db.Query<PropertyOfEntity>(
                    //        "delete from PropertyOfEntity where PropertyID = ?",
                    //        crd.PropertyID);
                    //}
                    //db.InsertAll(propertyOfEntityINS);
                    foreach (var crd in propertyOfEntityDEL)
                    {
                        await propertyOfEntityRepository.DbContextAsync().ExecuteScalarAsync<PropertyOfEntity>(
                            "delete from PropertyOfEntity where PropertyID = ?",
                            crd.PropertyID);
                    }
                    await propertyOfEntityRepository.DbContextAsync().InsertAllAsync(propertyOfEntityINS);
                    maxVal = tuple.Select(t => t.Old.PropertyOfEntity).Max(o => Convert.ToInt32(o.MTSeq));
                    break;
                case "View_Trait_TDM":
                    var traitList = tuple.Select(t => new Trait()
                    {
                        TraitID = t.Old.Trait.TraitID,
                        TraitTypeID = t.Old.Trait.TraitTypeID,
                        TraitName = t.Old.Trait.TraitName,
                        ColumnLabel = t.Old.Trait.ColumnLabel,
                        DataType = t.Old.Trait.DataType,
                        Updatable = t.Old.Trait.Updatable,
                        DisplayFormat = t.Old.Trait.DisplayFormat,
                        Editor = t.Old.Trait.Editor,
                        ListOfValues = t.Old.Trait.ListOfValues,
                        MinValue = t.Old.Trait.MinValue,
                        MaxValue = t.Old.Trait.MaxValue,
                        Property = t.Old.Trait.Property,
                        MTSeq = t.Old.Trait.MTSeq,
                        MTStat = t.Old.Trait.MTStat,
                        BaseUnitImp = t.Old.Trait.BaseUnitImp,
                        BaseUnitMet = t.Old.Trait.BaseUnitMet,
                        ShowSum = t.Old.Trait.ShowSum,
                        Description = t.Old.Trait.Description
                    }).ToList();
                    var traitINS = traitList.Where(o => o.MTStat == "INS" || o.MTStat == "UPD");
                    var traitDEL = traitList.Where(o => o.MTStat == "DEL" || o.MTStat == "UPD");
                    //foreach (var crd in traitDEL)
                    //{
                    //    db.Query<Trait>(
                    //        "delete from Trait where TraitID = ? ",
                    //        crd.TraitID);
                    //}
                    //db.InsertAll(traitINS);

                    foreach (var crd in traitDEL)
                    {
                        await traitRepository.DbContextAsync().ExecuteScalarAsync<Trait>(
                            "delete from Trait where TraitID = ? ",
                            crd.TraitID);
                    }
                    await traitRepository.DbContextAsync().InsertAllAsync(traitINS);
                    maxVal = traitList.Max(o => Convert.ToInt32(o.MTSeq));
                    break;
                case "TraitInFieldSet":
                    var traitInFieldSet = tuple.Select(t => new TraitInFieldSet
                    {
                        FieldSetID = t.Old.TraitInFieldSet.FieldSetID,
                        TraitID = t.Old.TraitInFieldSet.TraitID,
                        SortingOrder = t.Old.TraitInFieldSet.SortingOrder,
                        MTSeq = t.Old.TraitInFieldSet.MTSeq,
                        MTStat = t.Old.TraitInFieldSet.MTStat
                    });

                    var traitInFieldSetINS = traitInFieldSet.Where(o => o.MTStat == "INS" || o.MTStat == "UPD");
                    var traitInFieldSetDEL = traitInFieldSet.Where(o => o.MTStat == "DEL" || o.MTStat == "UPD");
                    //foreach (var crd in traitInFieldSetDEL)
                    //{
                    //    db.Query<TraitInFieldSet>(
                    //        "delete from TraitInFieldSet where FieldSetID = ? and TraitID = ?", crd.FieldSetID, crd.TraitID);
                    //}
                    //db.InsertAll(traitInFieldSetINS);
                    foreach (var crd in traitInFieldSetDEL)
                    {
                        await traitInFieldSetRepository.DbContextAsync().ExecuteScalarAsync<TraitInFieldSet>(
                            "delete from TraitInFieldSet where FieldSetID = ? and TraitID = ?", crd.FieldSetID, crd.TraitID);
                    }
                    await traitInFieldSetRepository.DbContextAsync().InsertAllAsync(traitInFieldSetINS);
                    maxVal = traitInFieldSet.Max(o => o.MTSeq);
                    break;
                case "TraitType":
                    var traitTypeList = tuple.Select(t => new TraitType
                    {
                        TraitTypeID = t.Old.TraitType.TraitTypeID,
                        TraitTypeName = t.Old.TraitType.TraitTypeName,
                        MTSeq = t.Old.TraitType.MTSeq,
                        MTStat = t.Old.TraitType.MTStat
                    });
                    var traitTypeINS = traitTypeList.Where(o => o.MTStat == "INS" || o.MTStat == "UPD");
                    var traitTypeDEL = traitTypeList.Where(o => o.MTStat == "DEL" || o.MTStat == "UPD");
                    //foreach (var crd in traitTypeDEL)
                    //{
                    //    db.Query<TraitType>(
                    //        "delete from TraitType where TraitTypeID = ?",
                    //        crd.TraitTypeID);
                    //}
                    //db.InsertAll(traitTypeINS);
                    foreach (var crd in traitTypeDEL)
                    {
                        await traitTypeRepository.DbContextAsync().ExecuteScalarAsync<TraitType>(
                            "delete from TraitType where TraitTypeID = ?",
                            crd.TraitTypeID);
                    }
                    await traitTypeRepository.DbContextAsync().InsertAllAsync(traitTypeINS);
                    maxVal = traitTypeList.Max(o => o.MTSeq);
                    break;
                case "TrialRegion":
                    var trialRegionINS = tuple.Select(t => t.Old.TrialRegion).Where(o => o.MTStat == "INS" || o.MTStat == "UPD");
                    var trialRegionDEL = tuple.Select(t => t.Old.TrialRegion).Where(o => o.MTStat == "DEL" || o.MTStat == "UPD");
                    //foreach (var crd in trialRegionDEL)
                    //{
                    //    db.Query<TrialRegion>(
                    //        "delete from TrialRegion where TrialRegionID = ?", crd.TrialRegionID);
                    //}
                    //db.InsertAll(trialRegionINS);
                    foreach (var crd in trialRegionDEL)
                    {
                        await trialRegionRepository.DbContextAsync().ExecuteScalarAsync<TrialRegion>(
                            "delete from TrialRegion where TrialRegionID = ?", crd.TrialRegionID);
                    }
                    await trialRegionRepository.DbContextAsync().InsertAllAsync(trialRegionINS);
                    maxVal = tuple.Select(t => t.Old.TrialRegion).Max(o => o.MTSeq);
                    break;
                case "TrialType":
                    var trialTypeINS = tuple.Select(t => t.Old.TrialType).Where(o => o.MTStat == "INS" || o.MTStat == "UPD");
                    var trialTypeDEL = tuple.Select(t => t.Old.TrialType).Where(o => o.MTStat == "DEL" || o.MTStat == "UPD");

                    //foreach (var crd in trialTypeDEL)
                    //{
                    //    db.Query<TrialType>(
                    //        "delete from TrialType where TrialTypeID = ?",
                    //        crd.TrialTypeID);
                    //}
                    //db.InsertAll(trialTypeINS);
                    foreach (var crd in trialTypeDEL)
                    {
                        await trialTypeRepository.DbContextAsync().ExecuteScalarAsync<TrialType>(
                            "delete from TrialType where TrialTypeID = ?",
                            crd.TrialTypeID);
                    }
                    await trialTypeRepository.DbContextAsync().InsertAllAsync(trialTypeINS);
                    maxVal = tuple.Select(t => t.Old.TrialType).Max(o => o.MTSeq);
                    break;
                case "View_TraitValue_TDM":
                    var traitValueList = tuple.Select(t => new TraitValue
                    {
                        TraitValueID = t.Old.TraitValue.TraitValueID,
                        TraitValueCode = t.Old.TraitValue.TraitValueCode,
                        TraitValueName = t.Old.TraitValue.TraitValueName,
                        TraitID = t.Old.TraitValue.TraitID,
                        SortingOrder = t.Old.TraitValue.SortingOrder,
                        MTSeq = t.Old.TraitValue.MTSeq,
                        MTStat = t.Old.TraitValue.MTStat
                    });

                    var traitValueINS = traitValueList.Where(o => o.MTStat == "INS" || o.MTStat == "UPD");
                    var traitValueDEL = traitValueList.Where(o => o.MTStat == "DEL" || o.MTStat == "UPD");
                    //foreach (var crd in traitValueDEL)
                    //{
                    //    db.Query<TraitValue>(
                    //        "delete from TraitValue where TraitValueID = ?", crd.TraitValueID);
                    //}
                    //db.InsertAll(traitValueINS);
                    foreach (var crd in traitValueDEL)
                    {
                        await traitValueRepository.DbContextAsync().ExecuteScalarAsync<TraitValue>(
                            "delete from TraitValue where TraitValueID = ?", crd.TraitValueID);
                    }
                    await traitValueRepository.DbContextAsync().InsertAllAsync(traitValueINS);
                    maxVal = traitValueList.Max(o => o.MTSeq);
                    break;

                case "CropSegment":
                    var cropSegmentList = tuple.Select(t => new CropSegment
                    {
                        CropSegmentCode = t.Old.CropSegment.CropSegmentCode,
                        CropSegmentName = t.Old.CropSegment.CropSegmentName,
                        CropCode = t.Old.CropSegment.CropCode,
                        MTSeq = t.Old.CropSegment.MTSeq,
                        MTStat = t.Old.CropSegment.MTStat
                    });
                    
                    var cropSegmentINS = cropSegmentList.Where(o => o.MTStat == "INS" || o.MTStat == "UPD");
                    var cropSegmenteDEL = cropSegmentList.Where(o => o.MTStat == "DEL" || o.MTStat == "UPD");
                    //foreach (var crd in cropSegmenteDEL)
                    //{
                    //    db.Query<CropSegment>(
                    //        "delete from CropSegment where CropSegmentCode = ?", crd.CropSegmentCode);
                    //}
                    //db.InsertAll(cropSegmentINS); 
                    foreach (var crd in cropSegmenteDEL)
                    {
                        await cropSegmentRepository.DbContextAsync().ExecuteScalarAsync<CropSegment>(
                            "delete from CropSegment where CropSegmentCode = ?", crd.CropSegmentCode);
                    }
                    await cropSegmentRepository.DbContextAsync().InsertAllAsync(cropSegmentINS);
                    maxVal = cropSegmentList.Max(o => o.MTSeq);
                    break;
                default:
                    break;
            }
        }
    }
}

