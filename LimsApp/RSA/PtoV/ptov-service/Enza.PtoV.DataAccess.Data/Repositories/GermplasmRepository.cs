using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using Enza.PtoV.DataAccess.Data.Interfaces;
using Enza.PtoV.Entities.Args;
using Enza.PtoV.DataAccess.Abstract;
using Enza.PtoV.DataAccess.Interfaces;
using Enza.PtoV.Common.Extensions;
using Enza.PtoV.Entities.Results;
using System.Linq;
using System;

namespace Enza.PtoV.DataAccess.Data.Repositories
{
    public class GermplasmRepository : Repository<object>, IGermplasmRepository
    {
        public GermplasmRepository(IDatabase dbContext):base(dbContext)
        {

        }
        public async Task<GermplasmsImportResult> GetGermplasmAsync(GetGermplasmRequestArgs requestargs)
        {
            var result = new GermplasmsImportResult
            {
                Status = "1",
                FileName = requestargs.FileName
            };
            var germPlasmTVP = new DataTable();
            germPlasmTVP.Columns.Add("GermplasmID", typeof(int));
            //Get Germplasm without parent
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_GERMPLASM, CommandType.StoredProcedure, args =>
             {
                 args.Add("@FileName", requestargs.FileName);
                 args.Add("@PageNumber", requestargs.PageNumber);
                 args.Add("@PageSize", requestargs.PageSize);
                 args.Add("@TVP_GermPlasm", germPlasmTVP);
                 args.Add("@FilterQuery", requestargs.ToFilterString());
                 args.Add("@Sort", requestargs.ToSortString());
                 args.Add("@IsHybrid", requestargs.IsHybrid);
             });
            if (data.Tables.Count == 2)
            {
                var table0 = data.Tables[0];
                var tblColumns = data.Tables[1];

                //this method is used to give a camelcase key value to columns equivalent to serialized value from json serializer.
                tblColumns.Columns.Add("ColumnLabel2", typeof(object));
                foreach (DataRow dr in tblColumns.Rows)
                {
                    var value = (dr["TraitID"].ToValueOrNull() ?? dr["ColumnLabel"]).ToText();
                    dr["ColumnLabel2"] = value.ToCamelCaseColumnName();
                }

                if (table0.Columns.Contains("TotalRows"))
                {
                    if (table0.Rows.Count > 0)
                    {
                        result.Total = table0.Rows[0]["TotalRows"].ToInt32();
                    }
                    table0.Columns.Remove("TotalRows");
                }
                result.Data = new GermplasmsData
                {
                    Data = table0,
                    Columns = tblColumns
                };
                result.Status = "1";
                result.FileName = requestargs.FileName;

                if (requestargs.IsHybrid)
                {
                    //add parenttype column to sync schema with parentDatatable which is used to give different icon to frontend.
                    table0.Columns.Add("ParentType", typeof(string));
                    //get parent                
                    foreach (DataRow row in table0.Rows)
                    {
                        var dr = germPlasmTVP.NewRow();
                        dr["GermplasmID"] = row["GID"];
                        germPlasmTVP.Rows.Add(dr);
                    }

                    var parentGermPlasmDS = await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_GERMPLASM, CommandType.StoredProcedure, args =>
                    {
                        args.Add("@FileName", requestargs.FileName);
                        args.Add("@PageNumber", requestargs.PageNumber);
                        args.Add("@PageSize", requestargs.PageSize);
                        args.Add("@TVP_GermPlasm", germPlasmTVP);
                        args.Add("@FilterQuery", "");
                        args.Add("@Sort", "");
                    });
                    if (parentGermPlasmDS.Tables.Count == 1)
                    {
                        var parentGermPlasmDT = parentGermPlasmDS.Tables[0];
                        //add parent type column to show different type of icon on frontend grid.
                        parentGermPlasmDT.Columns.Add("ParentType", typeof(string));
                        var table = table0.Clone();
                        //table.Columns.Add("ParentType", typeof(string));

                        DataRow dr1;
                        for (int i = 0; i < table0.Rows.Count; i++)
                        {
                            var dr = table0.Rows[i];
                            table.Rows.Add(dr.ItemArray);

                            //var maintainer = dr["Maintainer"].ToInt32();
                            var male = dr["MalePar"].ToInt32();
                            var female = dr["FemalePar"].ToInt32();
                            if (female > 0)
                            {
                                var femaleDR = parentGermPlasmDT.Select($"GID = {female}").FirstOrDefault();
                                if (femaleDR != null)
                                {
                                    //first add female and then maintainer
                                    var maintainer = femaleDR["Maintainer"].ToInt32();
                                    femaleDR["ParentType"] = "Female";
                                    femaleDR["TransferType"] = "Female";
                                    table.Rows.Add(femaleDR.ItemArray);

                                    if (maintainer > 0)
                                    {
                                        var maintainerDR = parentGermPlasmDT.Select($"GID = {maintainer}").FirstOrDefault();
                                        if (maintainerDR != null)
                                        {
                                            maintainerDR["ParentType"] = "maintainer";
                                            table.Rows.Add(maintainerDR.ItemArray);
                                        }
                                    }
                                }
                            }

                            if (male > 0)
                            {
                                dr1 = parentGermPlasmDT.Select($"GID = {male}").FirstOrDefault();
                                if (dr1 == null)
                                    continue;
                                dr1["ParentType"] = "male";
                                dr1["TransferType"] = "Male";
                                table.Rows.Add(dr1.ItemArray);
                            }

                        }
                        result.Data = new GermplasmsData
                        {
                            Data = table,
                            Columns = tblColumns
                        };
                        result.Status = "1";
                        result.FileName = requestargs.FileName;
                    }
                }
            }
            return result;
        }

        public async Task<GermplasmsImportResult> ImportGermplasmDataAsync(GetGermplasmRequestArgs requestargs, DataTable dtCellTVP, DataTable dtColumnsTVP, DataTable dtRowTVP,DataTable dtLotTVP)
        {
            var data = new GermplasmsImportResult();
            var result = await  DbContext.ExecuteNonQueryAsync(DataConstants.PR_IMPORTDATA, CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@FileName", requestargs.FileName);
                    args.Add("@ObjectID", requestargs.ObjectID);
                    args.Add("@ObjectType", requestargs.ObjectType);
                    args.Add("@TVPRow", dtRowTVP);
                    args.Add("@TVPColumn", dtColumnsTVP);
                    args.Add("@TVPCell", dtCellTVP);
                    args.Add("@TVPlot", dtLotTVP);
                });
            var filter = new List<Enza.PtoV.Entities.Args.Abstract.Filter>();
            var f = new Entities.Args.Abstract.Filter
            {
                Name = "StatusCode",
                Value = "100",
                Expression = "contains",
                Operator = "or"
            };
            filter.Add(f);
            requestargs.Filter = filter;
            requestargs.IsHybrid = true;
            return await GetGermplasmAsync(requestargs);
            
        }

        public async Task<GermplasmsImportResult> GetMappedGermplasmAsync(GetGermplasmRequestArgs requestargs)
        {
            var result = new GermplasmsImportResult();
            var germPlastTVP = new DataTable();
            germPlastTVP.Columns.Add("GermplasmID", typeof(int));
            var filterString = "";
            if (requestargs.ForSendToVarmas)
            {
                filterString = requestargs.ToFilterStringSendToVarmas();
                requestargs.IsHybrid = true;

            }                
            else
                filterString = requestargs.ToFilterString();

            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_CONVERTED_GERMPLASM, CommandType.StoredProcedure, args =>
            {
                args.Add("@FileName", requestargs.FileName);
                args.Add("@PageNumber", requestargs.PageNumber);
                args.Add("@PageSize", requestargs.PageSize);
                args.Add("@TVP_GermPlasm", germPlastTVP); //this paremeter is used for not getting parent on same request. we have to exclude filter, sorting and pagination on parent and should only apply for hybrid,op and cms type
                args.Add("@SendToVarmas", requestargs.ForSendToVarmas);
                args.Add("@FilterQuery", filterString);
                args.Add("@Sort", requestargs.ToSortString());
                args.Add("@IsHybrid", requestargs.IsHybrid);
            });
            if (data.Tables.Count == 2)
            {
                var table0 = data.Tables[0];
                var tblColumns = data.Tables[1];

                //this method is used to give a camelcase key value to columns equivalent to serialized value from json serializer.
                tblColumns.Columns.Add("ColumnLabel2", typeof(object));
                foreach (DataRow dr in tblColumns.Rows)
                {
                    var value = (dr["TraitID"].ToValueOrNull() ?? dr["ColumnLabel"]).ToText();
                    dr["ColumnLabel2"] = value.ToCamelCaseColumnName();
                }

                if (table0.Columns.Contains("TotalRows"))
                {
                    if (table0.Rows.Count > 0)
                    {
                        result.Total = table0.Rows[0]["TotalRows"].ToInt32();
                    }
                    table0.Columns.Remove("TotalRows");
                }
                //add parenttype column to sync schema with parentDatatable which is used to give different icon to frontend.
                table0.Columns.Add("ParentType", typeof(string));
                //get parent                
                foreach (DataRow row in table0.Rows)
                {
                    var dr = germPlastTVP.NewRow();
                    dr["GermplasmID"] = row["GID"];
                    germPlastTVP.Rows.Add(dr);
                }
                if (!requestargs.ForSendToVarmas && requestargs.IsHybrid)
                {

                    var parentGermPlasmDS = await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_CONVERTED_GERMPLASM, CommandType.StoredProcedure, args =>
                    {
                        args.Add("@FileName", requestargs.FileName);
                        args.Add("@PageNumber", requestargs.PageNumber);
                        args.Add("@PageSize", requestargs.PageSize);
                        args.Add("@TVP_GermPlasm", germPlastTVP);
                        args.Add("@SendToVarmas", false); //this paremeter is used for not getting parent on same request. we have to exclude filter, sorting and pagination on parent and should only apply for hybrid,op and cms type
                        args.Add("@FilterQuery", requestargs.ToFilterString());
                        args.Add("@Sort", requestargs.ToSortString());
                    });
                    if (parentGermPlasmDS.Tables.Count == 1)
                    {
                        var parentGermPlasmDT = parentGermPlasmDS.Tables[0];
                        //add parent type column to show different type of icon on frontend grid.
                        parentGermPlasmDT.Columns.Add("ParentType", typeof(string));
                        var table = table0.Clone();
                        //table.Columns.Add("ParentType", typeof(string));
                        DataRow dr1;
                        for (int i = 0; i < table0.Rows.Count; i++)
                        {
                            var dr = table0.Rows[i];
                            table.Rows.Add(dr.ItemArray);

                            //var maintainer = dr["Maintainer"].ToInt32();
                            var male = dr["MalePar"].ToInt32();
                            var female = dr["FemalePar"].ToInt32();
                            if (female > 0)
                            {
                                var femaleDR = parentGermPlasmDT.Select($"GID = {female}").FirstOrDefault();
                                if (femaleDR != null)
                                {
                                    //first add female and then maintainer
                                    var maintainer = femaleDR["Maintainer"].ToInt32();
                                    femaleDR["ParentType"] = "female";
                                    femaleDR["transferType"] = "female";
                                    table.Rows.Add(femaleDR.ItemArray);

                                    if (maintainer > 0)
                                    {
                                        var maintainerDR = parentGermPlasmDT.Select($"GID = {maintainer}").FirstOrDefault();
                                        if (maintainerDR != null)
                                        {
                                            maintainerDR["ParentType"] = "maintainer";
                                            maintainerDR["transferType"] = "maintainer";
                                            table.Rows.Add(maintainerDR.ItemArray);
                                        }

                                    }
                                }
                            }

                            if (male > 0)
                            {
                                dr1 = parentGermPlasmDT.Select($"GID = {male}").FirstOrDefault();
                                if (dr1 == null)
                                    continue;
                                dr1["ParentType"] = "male";
                                table.Rows.Add(dr1.ItemArray);
                            }

                        }

                        result.Data = new GermplasmsData
                        {
                            Data = table,
                            Columns = tblColumns
                        };
                        result.Status = "1";
                        result.FileName = requestargs.FileName;
                    }
                    else
                    {
                        result.Data = new GermplasmsData
                        {
                            Data = table0,
                            Columns = tblColumns
                        };
                        result.Status = "1";
                        result.FileName = requestargs.FileName;

                    }
                }

                else
                {
                    result.Data = new GermplasmsData
                    {
                        Data = table0,
                        Columns = tblColumns
                    };
                    result.Status = "1";
                    result.FileName = requestargs.FileName;
                }
                    
            }
            else
            {
                result.Status = "1";
                result.Data = new GermplasmsData
                {
                    Data = null,
                    Columns = null
                };
                result.FileName = requestargs.FileName;
            }
            return result;
        }

        public async Task<bool> DeleteGermplasmAsync(DeleteGermplasmRequestArgs requestargs)
        {
            var result = await DbContext.ExecuteNonQueryAsync(DataConstants.PR_DELETE_IMPORTED_GERMPLASMS, CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@VarietyIDs", string.Join(",",requestargs.Germplasm));
                    args.Add("@DeleteParentAlso", requestargs.DeleteParent);
                });
            return true;
        }

        public async Task<IEnumerable<CropResult>> GetCropsAsync()
        {
            const string query = @"SELECT 
	                                CropCode, 
	                                ObjectID, 
	                                ObjectType = ISNULL(ObjectType, 5),
                                    ISNULL(VarietySyncTime, DATEADD(WEEK,-2, GETUTCDATE())),
                                    DATEADD(SECOND,-100, GETUTCDATE()),
                                    FileID
                                FROM [File]
                                WHERE ISNULL(ObjectID, '') <> ''";
            return await DbContext.ExecuteReaderAsync(query, args => { }, reader => new CropResult
            {
                CropCode = reader.Get<string>(0),
                ObjectID = reader.Get<string>(1),
                ObjectType = reader.Get<string>(2),
                VarietySyncTIme = reader.Get<DateTime>(3),
                CurrentUTCTime = reader.Get<DateTime>(4),
                FileID = reader.Get<int>(5)
            });
        }

        public async Task<IEnumerable<ColumnInfo>> GetPhenomeObjectDetailAsync(string cropCode)
        {
            //Get Germplasm without parent
            return await DbContext.ExecuteReaderAsync(DataConstants.PR_GET_PHENOME_OBJECT_DETAIL,
                CommandType.StoredProcedure, args => args.Add("@CropCode", cropCode), reader => new ColumnInfo
                {
                    ColumnLabel = reader.Get<string>(0),
                    PhenomeColID = reader.Get<string>(1),
                    VariableID = reader.Get<string>(2),
                    ColumnID = reader.Get<int>(3)
                });
        }

        public async Task<IEnumerable<int>> GetImportedGIDsAsync(string cropCode)
        {
            const string StoredProcedure = "PR_GetImportedGIDsToSync";
            return await DbContext.ExecuteReaderAsync(StoredProcedure, CommandType.StoredProcedure, args => args.Add("@CropCode", cropCode), reader => reader.Get<int>(0));
        }

        public async Task SynchonizePhoneAsync(DataTable tvp)
        {
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_SYNCHRONIZE_PHENOME,
                CommandType.StoredProcedure,
                args => args.Add("@TVP", tvp));
        }

        public Task<IEnumerable<VarmasDataResult>> GetVarmasDataToSyncAsync(string cropCode)
        {
            return DbContext.ExecuteReaderAsync(DataConstants.PR_GET_VARMAS_DATA_TO_SYNC,
                CommandType.StoredProcedure, args => args.Add("@CropCode", cropCode), reader => new VarmasDataResult
                {
                    SyncCode = reader.Get<string>(0),
                    GID = reader.Get<int>(1),
                    VarietyNr = reader.Get<int>(2),
                    LotNumber = reader.Get<int>(3),
                    ScreeningFieldNr = reader.Get<int?>(4),
                    ScreeningFieldValue = reader.Get<string>(5),
                    IsValid = reader.Get<bool>(6),
                    CellID = reader.Get<int>(7),
                    TraitID = reader.Get<int>(8),
                    TraitName = reader.Get<string>(9),
                    ColumnLabel = reader.Get<string>(10)
                });
        }

        public async Task UpdateModifiedData(string cellIDs)
        {
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_UPDATE_MODIFIED_VALUE,
                CommandType.StoredProcedure,
                args => args.Add("@CellIDs", cellIDs));
        }

        public async Task Raciprocate(List<int> varietyIDs)
        {
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_RACIPROCATE, CommandType.StoredProcedure,
                args => args.Add("@VarietyIDs", string.Join(",", varietyIDs)));
        }

        public async Task<IEnumerable<string>> GetPhenomeColumnsAsync(int gid)
        {
            return await DbContext.ExecuteReaderAsync(DataConstants.PR_GET_PHENOME_COLUMNS,
               CommandType.StoredProcedure, args => args.Add("@GID", gid), reader => reader.Get<string>(0));
        }

        public async Task<bool> CheckUsePoNr(string cropCode)
        {
            string query = $"SELECT UsePONr FROM CropRD WHERE UsePONr = 1 AND CropCode = @CropCode";
            var res = await DbContext.ExecuteScalarAsync(query, args => args.Add("@CropCode", cropCode));
            if (res.ToInt32() > 0)
                return true;
            else
                return false;
        }

        public async Task<GermplasmsObjectResult> GetPhenomeColumnDetailsAsync(string cropCode)
        {
            var p1 = DbContext.CreateOutputParameter("@ObjectID", DbType.String, 50);
            var p2 = DbContext.CreateOutputParameter("@ObjectType", DbType.String, 50);
            var columns = await DbContext.ExecuteReaderAsync(DataConstants.PR_GET_PHENOME_COLUMN_DETAILS,
               CommandType.StoredProcedure, args =>
               {
                   args.Add("@CropCode", cropCode);
                   args.Add("@ObjectID", p1);
                   args.Add("@ObjectType", p2);
               }, reader => new ColumnInfo
               {
                   ColumnID = reader.Get<int>(0),
                   ColumnLabel = reader.Get<string>(1),
                   PhenomeColID = reader.Get<string>(2),
                   VariableID = reader.Get<string>(3)
               });

            return new GermplasmsObjectResult
            {
                CropCode = cropCode,
                ObjectID = p1.Value.ToText(),
                ObjectType = p2.Value.ToText(),
                Columns = columns.ToList()
            };
        }

        public async Task UpdateSyncedDateTimeAsync(string cropCode, DateTime currentUTCTime)
        {
            string query = $"Update [File] SET VarietySyncTime = @CurrentUTCTime WHERE CropCode = @CropCode";
            var res = await DbContext.ExecuteNonQueryAsync(query, args =>
            {
                args.Add("@CropCode", cropCode);
                args.Add("@CurrentUTCTime", currentUTCTime);
            });
        }

        //public async Task<IEnumerable<ColumnResult>> GetColumnsAsync(int fileID)
        //{
        //    var query = "SELECT ColumnID, VariableID FROM [Column] WHERE FileID = @FileID";
        //    return await DbContext.ExecuteReaderAsync(query, CommandType.Text, args => args.Add("@FileID", fileID),
        //        reader=>new ColumnResult
        //        {
        //            ColumnID= reader.Get<int>(0),
        //            VariableID= reader.Get<string>(1)
        //        });
        //}
    }
}
