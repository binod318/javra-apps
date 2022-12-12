using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;
using Enza.PtoV.BusinessAccess.Interfaces;
using Enza.PtoV.Common.Extensions;
using Enza.PtoV.Entities.Args;
using Enza.PtoV.Entities.Results;
using Enza.PtoV.Services.Abstract;
using System.Data;
using Enza.PtoV.Common.Exceptions;
using System.Linq;
using System.Xml.Linq;
using System.Configuration;
using Enza.PtoV.Common;
using Enza.PtoV.DataAccess.Data.Interfaces;
using Enza.PtoV.DataAccess.Interfaces;
using Enza.PtoV.Entities;
using Enza.PtoV.Services.Interfaces;
using Enza.PtoV.Services.Proxies;
using System.Security;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Enza.PtoV.BusinessAccess.Services
{
    public class PhenomeServices : IPhenomeServices
    {
        private readonly IGermplasmRepository _repo;
        private readonly IVarietyRepository _varietyRepository;
        private readonly IMasterRepository _masterRepository;
        private readonly IUserContext _userContext;
        private readonly IUELService _uelService;
        private readonly string _baseServiceUrl = ConfigurationManager.AppSettings["BasePhenomeServiceUrl"];

        public PhenomeServices(IGermplasmRepository repo, IVarietyRepository varietyRepository,
            IUserContext userContext, IUELService uelService, IMasterRepository masterRepository)
        {
            _repo = repo;
            _varietyRepository = varietyRepository;
            _userContext = userContext;
            _uelService = uelService;
            _masterRepository = masterRepository;
        }
        public async Task<GermplasmsImportResult> GetPhenomeDataAsync(HttpRequestMessage request,
            GermplasmsImportRequestArgs args)
        {
            var tcs = new TaskCompletionSource<GermplasmsImportResult>();
            try
            {
                var result = new GermplasmsImportResult();
                string cropCode = string.Empty;
                string syncCode = string.Empty;
                string breedingStation = string.Empty;

                bool requiresPoNr = false;

                #region prepare datatables for stored procedure call
                ////don't add value of fixed columns into cell table
                ////the order of the columns must be matched exactly with TVP_ImportVarieties
                var fixedCols = PhenomeToPToVColumns();
                //define tvp
                var dtCellTVP = new DataTable();
                var dtRowTVP = new DataTable("TVP_ImportVarieties");
                var dtColumnsTVP = new DataTable("TVP_Column");
                var lotTVP = new DataTable("TVP_Lot");

                //prepare tvp's (add necessary columns)
                PrepareTVPs(dtRowTVP, dtColumnsTVP, dtCellTVP, lotTVP);
                #endregion

                using (var client = new RestClient(_baseServiceUrl))
                {
                    client.SetRequestCookies(request);

                    //validate required variables on phenome folder structure
                    var variables = await ValidateRequiredVariables(client, args, result);
                    cropCode = variables.cropCode;
                    breedingStation = variables.breedingStationCode;
                    syncCode = variables.syncCode;
                    if (result.Errors.Any())
                    {
                        return result;
                    }
                    //get available transfertype which is used to fetch parents and maintainer depending on transfer type
                    var transferTypePerCrop = await _masterRepository.GetTransferTypePerCropAsync(cropCode);
                    if (transferTypePerCrop == null)
                    {
                        result.Errors.Add("Crop not found on PtoV Master crop table.");
                        result.Status = "0";
                        return result;
                    }
                    //check if crop require PO nr or not
                    requiresPoNr = await _repo.CheckUsePoNr(cropCode);

                    //get_ordered_columns
                    var url = "/api/v1/simplegrid/grid/get_ordered_columns/Germplasms";
                    var response = await client.PostAsync(url, values =>
                    {
                        values.Add("object_type", args.ObjectType);
                        values.Add("object_id", args.ObjectID);
                        values.Add("grid_id", args.GridID);
                        values.Add("base_entity_id", "0");
                        values.Add("use_name", "name");
                        values.Add("admin_mode", "0");
                    });
                    await response.EnsureSuccessStatusCodeAsync();

                    var columnsInfo = await response.Content.DeserializeAsync<GermplasmsColumnsResponse>();
                    if (!columnsInfo.Success)
                    {
                        throw new UnAuthorizedException(columnsInfo.Message);
                    }

                    var allColumns = columnsInfo.Columns.ToSafeList();
                    //validate required columns on phenome Germplasm set 
                    ValidateRequiredColumns(allColumns, result, requiresPoNr);
                    if (result.Errors.Any())
                    {
                        return result;
                    }

                    var dispCols = allColumns.Select(o => new Column
                    {
                        id = o.id,
                        variable_id = o.variable_id,
                        desc = o.desc,
                        data_type = o.data_type,
                        properties = o.properties
                    }).ToList();

                    var dispFCols = new List<Column>();
                    var dispMCols = new List<Column>();

                    //just fetch GID and Generation and its parent with Generation               
                    var cols = dispCols.Where(x => x.desc.EqualsIgnoreCase("GID") || x.desc.EqualsIgnoreCase("Gen"));

                    if (transferTypePerCrop.HasCms || transferTypePerCrop.HasHybrid)
                    {
                        //prepare male and female columns to fetch parent information
                        PrepareColumns(dispFCols, dispMCols, dispCols);
                        cols = cols.Concat(dispFCols).Concat(dispMCols).ToList();
                    }

                    int fGID = 0;
                    int mGID = 0;
                    string fGen = string.Empty;
                    string mGen = string.Empty;

                    //get columns json
                    var cols2 = cols.Serialize();

                    //update GridID value which is used should be unique for set of api's .
                    args.GridID = new Random().Next(10000000, 99999999).ToText(); //this grid id is 8 character id used to set grid and same id is used to fetch data after setting grid
                    //prepare phenome call which will require set display and set filter call before we call service to get data
                    await PreparePhemomeGrid(args, client, cols2, "");

                    var getTraitID = new Func<string, int?>(o =>
                    {
                        if (int.TryParse(o, out var traitid))
                        {
                            if (traitid > 0)
                                return traitid;
                        }
                        return null;
                    });
                    var columns = new List<PhenomeColumnInfo>();
                    var columns2 = new List<PhenomeColumnInfo>();
                    var gids = new HashSet<string>();
                    //var FemaleWithMaintainer = new HashSet<string>();
                    var germplasmList = new List<GermPlasmParentInfo>();
                    //var maintainerParent = new List<GermPlasmParentInfo>();
                    //var maleParent = new List<GermPlasmParentInfo>();
                    //var femaleParent = new List<GermPlasmParentInfo>();
                    XDocument doc;
                    var importedRows = 0;
                    var pagesize = 1000;
                    var totalRows = 0;
                    var addHeader = 1;

                    #region get data per page

                    while (totalRows >= importedRows)
                    {
                        //Get data here
                        url = "/api/v1/simplegrid/grid/show_grid/Germplasms?" +
                              $"object_type={args.ObjectType}&" +
                              $"object_id={args.ObjectID}&" +
                              $"grid_id={args.GridID}&" +
                              "gems_map_id=0&" +
                              $"add_header={addHeader.ToText()}&" +
                              "rows_per_page=99999&" +
                              "use_name=name&" +
                              "display_column=0&" +
                              $"posStart={importedRows}&" +
                              $"count={pagesize}";
                        var response4 = await client.GetAsync(url);
                        await response4.EnsureSuccessStatusCodeAsync();

                        var res4 = await response4.Content.ReadAsStreamAsync();

                        //load data to xdocument for parsing it and storing it to datatable.
                        doc = XDocument.Load(res4);

                        //this must be done only once because on next call we will only fetch data not columns information
                        if (addHeader == 1)
                        {
                            totalRows = Convert.ToInt32(doc.Element("rows").Attribute("total_count").Value);
                            columns2 = doc.Descendants("column").Select((x, idx) => new PhenomeColumnInfo
                            {
                                ID = x.Attribute("id")?.Value,
                                Index = idx
                            }).ToList();
                        }
                        #region Data Processing with Validation
                        var gidGenColumn = columns2.FirstOrDefault(o => o.ID.ToText().ToLower().StartsWith("ger~col"));
                        var fGIDColumn = columns2.FirstOrDefault(o => o.ID.EqualsIgnoreCase("GP1~ID"));
                        var mGIDColumn = columns2.FirstOrDefault(o => o.ID.EqualsIgnoreCase("GP2~ID"));
                        var fGenColumn = columns2.FirstOrDefault(o => (o.ID.StartsWith("GP1~")) && (!o.ID.EqualsIgnoreCase("GP1~ID")));
                        var mGenColumn = columns2.FirstOrDefault(o => (o.ID.StartsWith("GP2~")) && (!o.ID.EqualsIgnoreCase("GP2~ID")));

                        var rows = doc.Descendants("row");

                        var value = "";
                        var genCode = "";
                        var isHybrid = false;
                        var getMaintainer = false;
                        foreach (var dr in rows)
                        {
                            isHybrid = false;
                            getMaintainer = false;
                            genCode = "";
                            fGID = 0;
                            mGID = 0;
                            fGen = "";
                            mGen = "";
                            var gid = dr.Attribute("id")?.Value;
                            if (string.IsNullOrWhiteSpace(gid))
                            {
                                result.Errors.Add("GID can not be blank or empty.");
                                result.Status = "0";
                                return result;
                            }
                            var cells = dr.Descendants("cell").ToList();

                            if (germplasmList.FirstOrDefault(x => x.GID == gid.ToInt32()) != null)
                                continue;

                            genCode = cells[gidGenColumn.Index].Value;

                            //maintain the list to fetch actual parents
                            if ((transferTypePerCrop.HasHybrid || transferTypePerCrop.HasCms))
                            {
                                isHybrid = genCode.EqualsIgnoreCase("F1") ? true : false;
                                getMaintainer = genCode.ToLower().StartsWith("a") && transferTypePerCrop.HasCms ? true : false;
                                if (fGIDColumn != null)
                                {
                                    value = cells[fGIDColumn.Index].Value;
                                    if (!string.IsNullOrWhiteSpace(value))
                                        fGID = value.ToInt32();
                                }
                                if (mGIDColumn != null)
                                {
                                    value = cells[mGIDColumn.Index].Value;
                                    if (!string.IsNullOrWhiteSpace(value))
                                        mGID = value.ToInt32();
                                }
                                if (fGenColumn != null)
                                {
                                    fGen = cells[fGenColumn.Index].Value;
                                }
                                if (mGenColumn != null)
                                {
                                    mGen = cells[mGenColumn.Index].Value;
                                }
                                germplasmList.Add(new GermPlasmParentInfo
                                {
                                    BaseGID = gid.ToInt32(),
                                    GID = gid.ToInt32(),
                                    Gen = genCode,
                                    FemalePar = isHybrid ? new ParentGID
                                    {
                                        GID = fGID,
                                        Gen = fGen,
                                        Level = 1,
                                        FetchNextParent = true,
                                        TransferType = "Female"
                                    } : new ParentGID { },
                                    MalePar = isHybrid ? new ParentGID
                                    {
                                        GID = mGID,
                                        Gen = mGen,
                                        Level = 1,
                                        FetchNextParent = true,
                                        TransferType = "Male"
                                    } : new ParentGID { },
                                    MaintainerPar = getMaintainer ? new ParentGID
                                    {
                                        GID = mGID,
                                        Gen = mGen,
                                        Level = 1,
                                        FetchNextParent = true,
                                        TransferType = "Maintainer"
                                    } : new ParentGID { }
                                });
                            }
                            else
                            {
                                germplasmList.Add(new GermPlasmParentInfo
                                {
                                    BaseGID = gid.ToInt32(),
                                    GID = gid.ToInt32(),
                                    Gen = genCode,
                                    TransferType = "OP"
                                });
                            }
                        }
                        #endregion
                        addHeader = 0;
                        importedRows = importedRows + pagesize;

                    }
                    #endregion

                    if (germplasmList.Any())
                    {
                        if (transferTypePerCrop.HasBulb)
                        {
                            await GetParentGIDs(client, args, germplasmList, transferTypePerCrop, cols.ToList());
                        }
                        else
                        {
                            //get maintainer only if transfer type is CMS. because female and male parents are already fetched with above process
                            if (transferTypePerCrop.HasCms || transferTypePerCrop.HasHybrid)
                            {
                                var parentGermplasmList = new List<GermPlasmParentInfo>();
                                foreach (var germplasm in germplasmList)
                                {
                                    if (germplasm.FemalePar.GID > 0)
                                    {
                                        parentGermplasmList.Add(new GermPlasmParentInfo
                                        {
                                            BaseGID = germplasm.GID,
                                            GID = germplasm.FemalePar.GID,
                                            Gen = germplasm.FemalePar.Gen,
                                            TransferType = "Female"
                                        });
                                    }
                                    if (germplasm.MalePar.GID > 0)
                                    {
                                        parentGermplasmList.Add(new GermPlasmParentInfo
                                        {
                                            BaseGID = germplasm.GID,
                                            GID = germplasm.MalePar.GID,
                                            Gen = germplasm.MalePar.Gen,
                                            TransferType = "Male"
                                        });
                                    }
                                }

                                if (parentGermplasmList.Any())
                                {
                                    germplasmList.AddRange(parentGermplasmList);
                                }

                                if (transferTypePerCrop.HasCms)
                                {
                                    var femaleGIDs = germplasmList.Where(x => x.FemalePar.GID > 0 && x.FemalePar.Gen.ToLower().StartsWith("a")).Select(x => x.FemalePar.GID)
                                        .Concat(germplasmList.Where(x => x.FemalePar.GID <= 0 && x.Gen.ToLower().StartsWith("a")).Select(x => x.GID))
                                        .Distinct();

                                    if (femaleGIDs.Any())
                                    {
                                        //GetMaleParent data of femaleGIDs which are maintainer
                                        var maintainers = await GetMaintainersOfGIDsAsync(client, args, femaleGIDs, cols);
                                        if (maintainers.Any())
                                        {
                                            foreach (var maintainer in maintainers)
                                            {
                                                var parent = germplasmList.FirstOrDefault(x => x.GID == maintainer.BaseGID);
                                                if (parent != null)
                                                {
                                                    parent.MaintainerPar.GID = maintainer.GID;
                                                }
                                            }
                                            germplasmList.AddRange(maintainers);
                                        }
                                    }
                                }
                            }
                        }

                        //get all data of germplasm which are fetched as parent GIDS
                        result = await GetGermplasmData(client, args, germplasmList, dispCols, gids, dtRowTVP, dtCellTVP, fixedCols, requiresPoNr, syncCode, breedingStation, dtColumnsTVP,transferTypePerCrop);
                        if (result.Errors.Any())
                            return result;

                        //Get Lot information for imported Germplasm
                        #region Fetch lot information from Phenome
                        await GetLotFromPhenome(lotTVP, gids, client, args, result);
                        if (result.Errors.Any())
                            return result;
                        #endregion
                    }
                }
                var requestArgs = new GetGermplasmRequestArgs
                {
                    FileName = cropCode,
                    PageNumber = args.PageNumber,
                    PageSize = args.PageSize,
                    TotalRows = args.TotalRows,
                    ObjectID = args.CropID.ToString(),
                    ObjectType = args.ResearchGroupObjectType
                };
                result = await _repo.ImportGermplasmDataAsync(requestArgs, dtCellTVP, dtColumnsTVP, dtRowTVP, lotTVP);

                tcs.SetResult(result);
                //tcs.SetResult(await excelDataRepo.GetDataAsync(requestArgs));
            }
            catch (Exception ex)
            {
                tcs.SetException(ex);
            }
            return await tcs.Task;
        }

        private async Task<GermplasmsImportResult> GetGermplasmData(RestClient client, GermplasmsImportRequestArgs args, List<GermPlasmParentInfo> germplasms, List<Column> germSetPlasmColumns, HashSet<string> gids, DataTable dtRowTVP, DataTable dtCellTVP, Dictionary<string, (string Name, Type DataType)> fixedCols, bool requiresPoNr, string syncCode, string breedingStation, DataTable dtColumnsTVP,TransferTypeForCropResult transferTypePerCrop)
        {
            var result = new GermplasmsImportResult();
            var gridID = new Random().Next(10000000, 99999999).ToText();
            var filterGIDs = string.Join(",", germplasms.Select(x => x.GID));

            var columns = new List<PhenomeColumnInfo>();
            var args1 = new GermplasmsImportRequestArgs
            {
                ObjectID = args.CropID.ToText(),
                ObjectType = "5",
                GridID = gridID
            };
            //filter value 
            var filerValue = "\"GER~id\":\"=" + filterGIDs + "\"";
            //this will prepare grid with filter parameter
            await PreparePhemomeGrid(args1, client, germSetPlasmColumns.Serialize(), filerValue);
            //get data
            var url = "/api/v1/simplegrid/grid/show_grid/Germplasms?" +
                      $"object_type={args1.ObjectType}&" +
                      $"object_id={args1.ObjectID}&" +
                      $"grid_id={args1.GridID}&" +
                      "gems_map_id=0&" +
                      $"add_header=1&" +
                      $"rows_per_page={germplasms.Count}&" +
                      "use_name=name&" +
                      "display_column=0&" +
                      $"posStart=0&" +
                        $"count={germplasms.Count}";
            var dataResp = await client.GetAsync(url);
            await dataResp.EnsureSuccessStatusCodeAsync();
            var dataStream = await dataResp.Content.ReadAsStreamAsync();

            //load data to xml document
            var doc = XDocument.Load(dataStream);

            //load columns to find index

            var columns2 = doc.Descendants("column").Select((x, idx) => new PhenomeColumnInfo
            {
                ID = x.Attribute("id")?.Value,
                Index = idx
            }).ToList();

            columns = (from t1 in germSetPlasmColumns
                       join t2 in columns2 on t1.id equals t2.ID
                       select new PhenomeColumnInfo
                       {
                           ID = t2.ID,
                           Index = t2.Index,
                           //ColName = traitid == null ? t1.desc : traitid.ToString(), //this is now changed because variable id cannot be treated as trait from phenome so all is done based on description.
                           ColName = t1.desc,
                           ColLabel = t1.desc
                       }).ToList();


            //this must be done only once because on next call we will only fetch data not columns information

            //totalRows = Convert.ToInt32(doc.Element("rows").Attribute("total_count").Value);
            columns2 = doc.Descendants("column").Select((x, idx) => new PhenomeColumnInfo
            {
                ID = x.Attribute("id")?.Value,
                Index = idx
            }).ToList();
            //grid may contain parent columns as well. so process only germplasms level not parent
            //because parent level will be processed separately below
            var germplasmColumns = germSetPlasmColumns
                .Where(o => o.id.StartsWith("GER~", StringComparison.OrdinalIgnoreCase))
                .ToList();


            var getTraitID = new Func<string, int?>(o =>
            {
                if (int.TryParse(o, out var traitid))
                {
                    if (traitid > 0)
                        return traitid;
                }
                return null;
            });

            columns = (from t1 in germplasmColumns
                       join t2 in columns2 on t1.id equals t2.ID
                       let traitid = getTraitID(t1.variable_id)
                       select new PhenomeColumnInfo
                       {
                           ID = t2.ID,
                           Index = t2.Index,
                           ColName = t1.desc,
                           DataType = t1.data_type,
                           ColLabel = t1.desc,
                           TraitID = traitid,
                           VariableID = t1.variable_id
                       }).ToList();

            var duplicateColumns = columns.GroupBy(g => g.ColName).Where(x => x.Count() > 1).ToList();
            if (duplicateColumns.Any())
            {
                var duplicateCols = string.Join(", ", duplicateColumns.Select(x => x.Key));
                result.Errors.Add($"Found duplicate column(s) => {duplicateCols}.");
                result.Status = "0";
                return result;
            }
            //add column info into tvp
            for (int j = 0; j < columns.Count; j++)
            {
                var col = columns[j];
                if (col.ColLabel.EqualsIgnoreCase("Crop") || col.ColLabel.EqualsIgnoreCase("SyncCode") || col.ColLabel.EqualsIgnoreCase("Breeding Station"))
                    continue;
                var dr = dtColumnsTVP.NewRow();
                dr["ColumnNr"] = j;
                dr["TraitID"] = col.TraitID ?? (object)DBNull.Value;
                dr["ColumnLabel"] = col.ColLabel;
                dr["DataType"] = col.DataType.ToText().ToUpper() == "C" ? "NVARCHAR(255)" : col.DataType;
                dr["VariableID"] = col.VariableID;
                dr["PhenomeColID"] = col.ID;

                dtColumnsTVP.Rows.Add(dr);
            }

            var rows = doc.Descendants("row");
            var gid = string.Empty;
            int i = dtRowTVP.Rows.Count;
            GermPlasmParentInfo germplasm;
            foreach (var dr in rows)
            {

                i++;
                gid = dr.Attribute("id")?.Value;
                if (string.IsNullOrWhiteSpace(gid))
                {
                    continue;
                }
                else
                {
                    germplasm = germplasms.FirstOrDefault(x => x.GID == gid.ToInt32());
                    if (germplasm == null)
                        continue;
                    var cells = dr.Descendants("cell").ToList();
                    if (gids.Contains(gid))
                        continue;
                    var drRow = dtRowTVP.NewRow();
                    drRow["RowNr"] = i;
                    drRow["GID"] = gid;
                    drRow["SyncCode"] = syncCode; //sync code is not added on fixed column but assigned directly because we will not get values of this in cell
                    drRow["BrStationCode"] = breedingStation; //we will not get value of brstation code from grid.

                    if ((germplasm.MalePar?.GID > 0 && germplasm.FemalePar?.GID > 0) && germplasm.Gen.ToText().EqualsIgnoreCase("F1"))// && transferTypePerCrop.HasCms && germplasm.FemalePar.Gen.ToText().ToLower().StartsWith("a")) )
                    {
                        drRow["TransferType"] = "Hyb";
                        drRow["FemalePar"] = germplasm.FemalePar?.GID;
                        drRow["MalePar"] = germplasm.MalePar?.GID;
                        var femParGID = germplasm.FemalePar?.GID;

                        var femPar = germplasms.FirstOrDefault(x => x.GID == femParGID);
                        if (femPar != null)
                        {
                            var maintainerGID = femPar.MaintainerPar?.GID;
                            var maintainer = germplasms.FirstOrDefault(x => x.GID == maintainerGID);
                            if (maintainer != null)
                                drRow["TransferType"] = "CMS";
                        }
                    }
                    else if (germplasm.MaintainerPar?.GID > 0 && germplasm.Gen.ToText().ToLower().StartsWith("a"))
                    {
                        drRow["Maintainer"] = germplasm.MaintainerPar?.GID;
                        drRow["TransferType"] = string.IsNullOrWhiteSpace(germplasm.TransferType) ? "Female" : germplasm.TransferType;
                    }
                    else if(transferTypePerCrop.HasOp)
                        drRow["TransferType"] = "OP";
                    else
                        drRow["TransferType"] = string.IsNullOrWhiteSpace(germplasm.TransferType) ? "Female" : germplasm.TransferType;

                    if (!LoadPhenomeDataToTVP(columns, columns, cells, drRow, dtCellTVP, gid, string.Empty, fixedCols, result, requiresPoNr, i))
                        return result;
                    dtRowTVP.Rows.Add(drRow);

                    gids.Add(gid);
                }
            }
            return result;

        }

        private async Task GetParentGIDs(RestClient client, GermplasmsImportRequestArgs args, List<GermPlasmParentInfo> parentGermplasms,
            TransferTypeForCropResult transferTypePerCrop, List<Column> cols)
        {
            var gen = string.Empty;
            int parent;
            //male gids,female gids, maintainer gids
            //var parentGermplasms = maleParent.Concat(femaleParent).Concat(maintainerParent).ToList();
            var maleParents = parentGermplasms.Where(x => x.MalePar.FetchNextParent).Select(x => x.MalePar).ToList();
            var femaleParents = parentGermplasms.Where(x => x.FemalePar.FetchNextParent).Select(x => x.FemalePar).ToList();
            var maintainerParents = parentGermplasms.Where(x => x.MaintainerPar.FetchNextParent).Select(x => x.MaintainerPar).ToList();
            var all = maleParents.Concat(femaleParents).Concat(maintainerParents).ToList();
            var gids = string.Join(",", all.Select(x => x.GID));

            //set display for grid on phenome on research group level
            var gridID = new Random().Next(10000000, 99999999).ToText(); //this grid id is 8 character id used to set grid and same id is used to fetch data after setting grid

            int addHeader = 1;
            var columns = new List<PhenomeColumnInfo>();

            while (!string.IsNullOrWhiteSpace(gids))
            {
                var args1 = new GermplasmsImportRequestArgs
                {
                    ObjectID = args.CropID.ToText(),
                    ObjectType = "5",
                    GridID = gridID
                };
                //filter value 
                var filerValue = "\"GER~id\":\"=" + gids + "\"";
                //this will prepare grid with filter parameter
                await PreparePhemomeGrid(args1, client, cols.Serialize(), filerValue);

                //get data
                var url = "/api/v1/simplegrid/grid/show_grid/Germplasms?" +
                          $"object_type={args1.ObjectType}&" +
                          $"object_id={args1.ObjectID}&" +
                          $"grid_id={args1.GridID}&" +
                          "gems_map_id=0&" +
                          $"add_header={addHeader.ToText()}&" +
                          $"rows_per_page={all.Count}&" +
                          "use_name=name&" +
                          "display_column=0&" +
                          $"posStart=0&" +
                          $"count={all.Count}";
                var dataResp = await client.GetAsync(url);
                await dataResp.EnsureSuccessStatusCodeAsync();
                var dataStream = await dataResp.Content.ReadAsStreamAsync();

                var doc = XDocument.Load(dataStream);
                if (addHeader == 1)
                {
                    var columns2 = doc.Descendants("column").Select((x, idx) => new PhenomeColumnInfo
                    {
                        ID = x.Attribute("id")?.Value,
                        Index = idx
                    }).ToList();
                    columns = (from t1 in cols
                               join t2 in columns2 on t1.id equals t2.ID
                               select new PhenomeColumnInfo
                               {
                                   ID = t2.ID,
                                   Index = t2.Index,
                                   //ColName = traitid == null ? t1.desc : traitid.ToString(), //this is now changed because variable id cannot be treated as trait from phenome so all is done based on description.
                                   ColName = t1.desc,
                                   ColLabel = t1.desc
                               }).ToList();
                }
                var maleParentIndex = columns.FirstOrDefault(x => x.ID.EqualsIgnoreCase("GP2~id"));
                var femaleParentIndex = columns.FirstOrDefault(x => x.ID.EqualsIgnoreCase("GP1~id"));
                var maleParentGenIndex = columns.FirstOrDefault(x => x.ID.ToText().ToLower().StartsWith("gp2") && x.ColLabel.ToText().ToLower().Contains("gen"));
                var femaleParentGenIndex = columns.FirstOrDefault(x => x.ID.ToText().ToLower().StartsWith("gp1") && x.ColLabel.ToText().ToLower().Contains("gen"));

                //load data to xml
                var rows = doc.Descendants("row");
                foreach (var dr in rows)
                {
                    parent = 0;
                    var gid = dr.Attribute("id")?.Value;

                    var cells = dr.Descendants("cell").ToList();
                    //there could be a multiple germplasmList added due to fetching parent and same parent is also present on germplasm set on phenome
                    //we need to update that value

                    var maintPar = maintainerParents.Where(x => x.GID == gid.ToInt32());
                    foreach (var _maintPar in maintPar)
                    {
                        if (int.TryParse(cells[maleParentIndex.Index].Value, out parent))
                            gen = cells[maleParentGenIndex.Index].Value;
                        else if (int.TryParse(cells[femaleParentIndex.Index].Value, out parent))
                            gen = cells[femaleParentGenIndex.Index].Value;

                        if (parent > 0 && _maintPar.Gen.EqualsIgnoreCase(gen))
                        {
                            _maintPar.GID = parent;
                        }
                        else
                        {
                            _maintPar.FetchNextParent = false;
                            var p1 = parentGermplasms.FirstOrDefault(x => x.GID == _maintPar.GID);
                            if (p1 == null)
                            {
                                parentGermplasms.Add(new GermPlasmParentInfo
                                {
                                    BaseGID = _maintPar.GID,
                                    GID = _maintPar.GID,
                                    Gen = parent > 0 ? gen : _maintPar.Gen,
                                    TransferType = "Maintainer"
                                });
                            }
                        }
                    }

                    var mPar = maleParents.Where(x => x.GID == gid.ToInt32());
                    foreach (var malePar in mPar)
                    {
                        if (int.TryParse(cells[maleParentIndex.Index].Value, out parent))
                            gen = cells[maleParentGenIndex.Index].Value;
                        else if (int.TryParse(cells[femaleParentIndex.Index].Value, out parent))
                            gen = cells[femaleParentGenIndex.Index].Value;

                        if (parent > 0 && malePar.Gen.EqualsIgnoreCase(gen))
                        {
                            malePar.GID = parent;
                        }
                        else
                        {
                            malePar.FetchNextParent = false;
                            var p1 = parentGermplasms.FirstOrDefault(x => x.GID == malePar.GID);
                            if (p1 == null)
                            {
                                parentGermplasms.Add(new GermPlasmParentInfo
                                {
                                    BaseGID = malePar.GID,
                                    GID = malePar.GID,
                                    Gen = parent > 0 ? gen : malePar.Gen,
                                    TransferType = "Male"
                                });
                            }
                        }
                    }

                    var fPar = femaleParents.Where(x => x.GID == gid.ToInt32());
                    foreach (var femalePar in fPar)
                    {
                        gen = cells[femaleParentGenIndex.Index].Value;
                        if (int.TryParse(cells[femaleParentIndex.Index].Value, out parent) && femalePar.Gen.EqualsIgnoreCase(gen))
                        {
                            femalePar.GID = parent;
                            femalePar.Gen = gen;
                        }
                        else
                        {
                            femalePar.FetchNextParent = false;
                            var par = parentGermplasms.FirstOrDefault(x => x.GID == femalePar.GID);
                            if (par == null)
                            {
                                int malePar;
                                string maleGen;
                                var parentGermplasm = new ParentGID
                                {
                                    TransferType = "Maintainer",
                                    Level = 1,
                                    FetchNextParent = true
                                };
                                if (int.TryParse(cells[maleParentIndex.Index].Value, out malePar) && transferTypePerCrop.HasCms && femalePar.Gen.ToLower().StartsWith("a"))
                                {
                                    maleGen = cells[maleParentGenIndex.Index].Value;
                                    parentGermplasm.GID = malePar;
                                    parentGermplasm.Gen = maleGen;
                                    maintainerParents.Add(parentGermplasm);
                                    parentGermplasms.Add(new GermPlasmParentInfo
                                    {
                                        BaseGID = femalePar.GID,
                                        GID = femalePar.GID,
                                        Gen = parent > 0 ? femalePar.Gen : gen,
                                        TransferType = "Female",
                                        MaintainerPar = parentGermplasm
                                    });
                                    all.Add(parentGermplasm);
                                }
                                else
                                {
                                    parentGermplasms.Add(new GermPlasmParentInfo
                                    {
                                        BaseGID = femalePar.GID,
                                        GID = femalePar.GID,
                                        Gen = parent > 0 ? femalePar.Gen : gen,
                                        TransferType = "Female"
                                    });

                                }
                            }
                            else
                            {
                                int malePar;
                                string maleGen;
                                var parentGermplasm = new ParentGID
                                {
                                    TransferType = "Maintainer",
                                    Level = 1

                                };
                                if (int.TryParse(cells[maleParentIndex.Index].Value, out malePar) && transferTypePerCrop.HasCms && gen.ToLower().StartsWith("a"))
                                {
                                    maleGen = cells[maleParentGenIndex.Index].Value;
                                    parentGermplasm.GID = malePar;
                                    parentGermplasm.Gen = maleGen;
                                    maintainerParents.Add(parentGermplasm);
                                    par.MaintainerPar = parentGermplasm;
                                }
                            }
                        }
                    }
                }

                gids = string.Join(",", all.Where(x => x.FetchNextParent && x.GID > 0).Select(x => x.GID));
                 
                //set add header to false here
                addHeader = 0;
            }

        }

        private async Task PreparePhemomeGrid(GermplasmsImportRequestArgs args, RestClient client, string cols2, string filterValue)
        {
            var url = "";            
            //set display
            url = "/api/v1/simplegrid/grid/set_display/Germplasms";
            var response2 = await client.PostAsync(url, values =>
            {
                values.Add("grid_id", args.GridID);
                values.Add("columns", cols2);
            });
            await response2.EnsureSuccessStatusCodeAsync();

            //filter_grid
            url = "/api/v1/simplegrid/grid/filter_grid/Germplasms";
            var response3 = await client.PostAsync(url, values =>
            {
                values.Add("object_type", args.ObjectType);
                values.Add("object_id", args.ObjectID);
                values.Add("grid_id", args.GridID);
                values.Add("gems_map_id", "0");
                values.Add("admin_mode", "0");
                values.Add("simple_filter", "{" + filterValue + "}");
            });
            await response3.EnsureSuccessStatusCodeAsync();
        }

        private void ValidateRequiredColumns(List<Column> columns, GermplasmsImportResult result, bool requiresPoNr)
        {
            if (!columns.Any())
            {
                result.Errors.Add("No columns found.");
                result.Status = "0";
            }

            var requiredColumns = new List<string> {"GID", "E-number", "Name", "Gen", "MasterNr", "Plantnumbr", "Pedigree", "Stem", "Stemtail"};
            if (requiresPoNr)
            {
                requiredColumns.Add("po nr");
            }
            var missingColumns = requiredColumns.Where(x => !columns.Any(y => y.desc.EqualsIgnoreCase(x)));
            if (missingColumns.Any())
            {
                var columnNames = string.Join(", ", missingColumns);
                var errorMsg = $"Following column(s) are mandatory: ({columnNames})";
                result.Errors.Add(errorMsg);
                result.Status = "0";
            }
            
            ////check if ENumber column exists in the grid
            //if (!columns.Any(o => o.desc.EqualsIgnoreCase("E-number")))
            //{
            //    result.Errors.Add("Couldn't find E-number column in the grid.");
            //    result.Status = "0";
            //}
            ////check if Plant name column exists in the grid
            //if (!columns.Any(o => o.desc.EqualsIgnoreCase("Name")))
            //{
            //    result.Errors.Add("Couldn't find Name column in the grid.");
            //    result.Status = "0";
            //}
            ////check if gen column exists or not
            //if (!columns.Any(o => o.desc.EqualsIgnoreCase("Gen")))
            //{
            //    result.Errors.Add("Couldn't find Gen column in the grid.");
            //    result.Status = "0";
            //}

            //check if po nr column exists or not if ponr is needed for imported crop
            //if (requiresPoNr && !columns.Any(o => o.desc.EqualsIgnoreCase("po nr")))
            //{
            //    result.Errors.Add("Couldn't find Po nr in the grid.");
            //    result.Status = "0";
            //}
        }

        private async Task<(string cropCode, string breedingStationCode, string syncCode)> ValidateRequiredVariables(RestClient client, GermplasmsImportRequestArgs args, GermplasmsImportResult result)
        {
            const string CROP = "Crop";
            const string BREEDING_STATION = "Breeding Station";
            const string BREED_STATION = "BreedStat";
            const string SYNC_CODE = "SyncCode";
            string cropCode;
            string syncCode;
            string breedingStation;

            var cropVariables = await GetRGVariablesAsync(client, args.CropID);
            var variables = await GetBOVariablesAsync(client, args.FolderID);

            if (!cropVariables.TryGetValue(CROP, out cropCode))
            {
                result.Errors.Add("Could not find crop. Please configure Crop on phenome.");
                result.Status = "0";
            }
            if (string.IsNullOrWhiteSpace(cropCode))
            {
                result.Errors.Add("Crop can not be empty.");
                result.Status = "0";
            }
            if (!variables.TryGetValue(BREEDING_STATION, out breedingStation) && !variables.TryGetValue(BREED_STATION, out breedingStation))
            {
                result.Errors.Add("Could not find Breeding station. Please configure Breeding station on phenome.");
                result.Status = "0";
            }
            if (string.IsNullOrWhiteSpace(breedingStation))
            {
                result.Errors.Add("Breeding station can not be empty.");
                result.Status = "0";
            }
            if (!variables.TryGetValue(SYNC_CODE, out syncCode))
            {
                result.Errors.Add("Could not find Sync code. Please configure Sync code on phenome.");
                result.Status = "0";
            }

            if (string.IsNullOrWhiteSpace(syncCode))
            {
                result.Errors.Add("Sync code can not be empty.");
                result.Status = "0";
            }
            return (cropCode, breedingStation, syncCode);
        }

        private void PrepareColumns(List<Column> dispFCols, List<Column> dispMCols, List<Column> dispCols)
        {
            //set_display
            var replacePrefix = new Func<string, string, string>((prefix, o) =>
                string.Concat(prefix, o.Substring("GER~".Length)));
            //get female parent information
            dispFCols.AddRange(dispCols.Where(o => (o.id.StartsWith("GER~col", StringComparison.OrdinalIgnoreCase)) && (o.desc.EqualsIgnoreCase("gen")))
                .Select(o => new Column
                {
                    id = replacePrefix("GP1~", o.id),
                    variable_id = o.variable_id,
                    desc = o.desc,
                    col_num = o.col_num,
                    data_type = o.data_type,
                    properties = o.properties.Select(x => new ColumnProperty
                    {
                        id = replacePrefix("GP1~", x.id)
                    }).ToList()
                })
                .Concat(new[]
                {
                            new Column
                            {
                                id = "GP1~id",
                                variable_id = "-1",
                                desc = "GID",
                                data_type= "C",
                                properties = new List<ColumnProperty>
                                {
                                    new ColumnProperty
                                    {
                                        id= "GP1~id"
                                    }
                                }
                            }
                }));

            //get male parent information
            dispMCols.AddRange(dispCols.Where(o => (o.id.StartsWith("GER~col", StringComparison.OrdinalIgnoreCase)) && (o.desc.EqualsIgnoreCase("gen")))
                .Select(o => new Column
                {
                    id = replacePrefix("GP2~", o.id),
                    variable_id = o.variable_id,
                    desc = o.desc,
                    col_num = o.col_num,
                    data_type = o.data_type,
                    properties = o.properties.Select(x => new ColumnProperty
                    {
                        id = replacePrefix("GP2~", x.id)
                    }).ToList()
                }).Concat(new[]
                {
                            new  Column
                            {
                                id = "GP2~id",
                                variable_id = "-1",
                                desc = "GID",
                                data_type= "C",
                                properties = new List<ColumnProperty>
                                {
                                    new ColumnProperty
                                    {
                                        id = "GP2~id"
                                    }
                                }
                            }
                }));
        }

        private async Task GetLotFromPhenome(DataTable dt, HashSet<string> gids, RestClient client, GermplasmsImportRequestArgs args, GermplasmsImportResult result)
        {
            //Get all columns
            var url = "/api/v1/simplegrid/grid/get_columns_list/InventoryLots";
            var gridid = new Random().Next(10000000, 99999999).ToText();
            var response = await client.PostAsync(url, values =>
            {
                values.Add("object_type", "5");
                values.Add("object_id", args.CropID.ToText());
                values.Add("base_entity_id", "0");
            });

            await response.EnsureSuccessStatusCodeAsync();
            var columnsInfo = await response.Content.DeserializeAsync<InventoryLotColumnsResponse>();
            if (!columnsInfo.Status.EqualsIgnoreCase("1"))
            {
                throw new UnAuthorizedException(columnsInfo.Message);
            }
            var columns = columnsInfo.All_Columns.ToSafeList();
            if (!columns.Any())
            {
                result.Errors.Add("No columns found while importing Lot.");
                result.Status = "0";
                return;
            }
            //set_display
            var Cols = columns.Select(o => new Column
            {
                id = o.id,
                variable_id = o.variable_id,
                desc = o.desc,
                data_type = o.data_type,
                properties = o.properties
            }).Where(x => x.id.EqualsIgnoreCase("GER~id") || (x.desc.EqualsIgnoreCase("ID") && x.id.ToText().ToLower().StartsWith("lot")) || (x.desc.EqualsIgnoreCase("is default") && x.id.ToText().ToLower().StartsWith("lot")))
            .ToList();
            //serialize column
            var serializedCol = Cols.Serialize();

            url = "/api/v1/simplegrid/grid/set_display/InventoryLots";
            var response2 = await client.PostAsync(url, values =>
            {
                values.Add("grid_id", gridid);
                values.Add("columns", serializedCol);
            });
            await response2.EnsureSuccessStatusCodeAsync();

            //filter_grid
            url = "/api/v1/simplegrid/grid/filter_grid/InventoryLots";
            var germplasms = string.Join(",", gids);
            var germPlasmColID = Cols.FirstOrDefault(x => x.desc.EqualsIgnoreCase("GID"))?.id;
            var lotColID = Cols.FirstOrDefault(x => x.desc.EqualsIgnoreCase("ID"))?.id;
            var isdefaultColID = Cols.FirstOrDefault(x => x.desc.EqualsIgnoreCase("is default"))?.id;
            if (string.IsNullOrWhiteSpace(germPlasmColID))
            {
                result.Errors.Add("GID column not configured for inventory.");
                result.Status = "0";
                return;
            }
            if (string.IsNullOrWhiteSpace(lotColID))
            {
                result.Errors.Add("ID column not configured for inventory.");
                result.Status = "0";
                return;
            }
            if (string.IsNullOrWhiteSpace(isdefaultColID))
            {
                result.Errors.Add("Is default column not configured for inventory.");
                result.Status = "0";
                return;
            }
            //filter value 
            var filerValue = "\"" + germPlasmColID + "\":\"" + germplasms + "\"";


            var response3 = await client.PostAsync(url, values =>
            {
                //values.Add("object_type", args.FolderObjectType); //folder object type is 4 but research group object type is 5
                values.Add("object_type", "5");
                values.Add("object_id", args.CropID.ToText());
                values.Add("grid_id", gridid);
                values.Add("gems_map_id", "0");
                values.Add("admin_mode", "0");
                values.Add("simple_filter", "{" + filerValue + "}");
            });
            await response3.EnsureSuccessStatusCodeAsync();


            var finalCol = new List<PhenomeColumnInfo>();
            XDocument doc;
            var importedRows = 0;
            var pagesize = 1000;
            var totalRows = 0;
            var addHeader = 1;
            while (totalRows >= importedRows)
            {
                //get data
                url = "/api/v1/simplegrid/grid/show_grid/InventoryLots?" +
                              $"object_type=5&" +
                              $"object_id={args.CropID.ToText()}&" +
                              $"grid_id={gridid}&" +
                              "gems_map_id=0&" +
                              $"add_header={addHeader.ToText()}&" +
                              $"rows_per_page={pagesize}&" +
                              "use_name=name&" +
                              "display_column=0&" +
                              $"posStart={importedRows}&" +
                              $"count={pagesize}";

                var response4 = await client.GetAsync(url);
                await response4.EnsureSuccessStatusCodeAsync();
                var lotdata = await response4.Content.ReadAsStreamAsync();

                doc = XDocument.Load(lotdata);

                var rows = doc.Descendants("row");

                if (addHeader == 1)
                {
                    totalRows = Convert.ToInt32(doc.Element("rows").Attribute("total_count").Value);
                    var colsInData = doc.Descendants("column").Select((x, idx) => new
                    {
                        ID = x.Attribute("id")?.Value,
                        Index = idx
                    }).ToList();

                    var getTraitID = new Func<string, int?>(o =>
                    {
                        if (int.TryParse(o, out var traitid))
                        {
                            if (traitid > 0)
                                return traitid;
                        }
                        return null;
                    });
                    finalCol = (from t1 in Cols
                                join t2 in colsInData on t1.id equals t2.ID
                                let traitid = getTraitID(t1.variable_id)
                                select new PhenomeColumnInfo
                                {
                                    ID = t2.ID,
                                    Index = t2.Index,
                                    //ColName = traitid == null ? t1.desc : traitid.ToString(), //this is now changed because variable id cannot be treated as trait from phenome so all is done based on description.
                                    ColName = t1.desc,
                                    DataType = t1.data_type,
                                    ColLabel = t1.desc,
                                    TraitID = traitid
                                }).ToList();

                    var duplicateColumns = finalCol.GroupBy(g => g.ColName).Where(x => x.Count() > 1).ToList();
                    if (duplicateColumns.Any())
                    {
                        var duplicateCols = string.Join(", ", duplicateColumns.Select(x => x.Key));
                        result.Errors.Add($"Found duplicate column(s) => {duplicateCols} while importing Inventory records from Inventory Grid.");
                        result.Status = "0";
                        return;
                    }

                }
                //process data here
                foreach (var dr in rows)
                {
                    var lotID = dr.Attribute("id")?.Value;
                    if (string.IsNullOrWhiteSpace(lotID))
                    {
                        result.Errors.Add("LotID can not be blank or empty.");
                        result.Status = "0";
                        return;
                    }

                    var cells = dr.Descendants("cell").ToList();

                    var drRow = dt.NewRow();
                    for (int i = 0; i < finalCol.Count; i++)
                    {
                        var col = finalCol[i];
                        var cellval = cells[col.Index].Value;
                        if (col.ColName.EqualsIgnoreCase("ID"))
                        {
                            drRow["ID"] = cellval;
                        }
                        else if (col.ColName.EqualsIgnoreCase("GID"))
                        {
                            drRow["GID"] = cellval;
                        }
                        else if (col.ColName.EqualsIgnoreCase("Is Default"))
                        {
                            drRow["Is Default"] = cellval == "1" ? true : false;
                        }
                    }
                    dt.Rows.Add(drRow);
                }
                addHeader = 0;
                importedRows = importedRows + pagesize;
            }
        }

        public async Task<SendToVarmasResult> SendToVarmasAsync(IEnumerable<SendToVarmasRequestArgs> requestargs)
        {
            var rs = new SendToVarmasResult();
            var sentVariList = new HashSet<int>();
            return await SendToVarmasAsync(requestargs, sentVariList, rs);
        }
        public async Task<SendToVarmasResult> SyncToVarmasAsync(IEnumerable<int> requestargs)
        {
            var rs = new SendToVarmasResult();
            var sentVariList = new HashSet<int>();
            return await SyncToVarmas(requestargs, sentVariList, rs);
        }

        public void PrepareTVPs(DataTable dtRowTVP, DataTable dtColumnsTVP, DataTable dtCellTVP, DataTable lotTVP)
        {
            //don't add value of fixed columns into cell table
            //the order of the columns must be matched exactly with TVP_ImportVarieties
            var fixedCols = PhenomeToPToVColumns();

            //var dtCellTVP = new DataTable();
            dtCellTVP.Columns.Add("RowNr", typeof(int));
            dtCellTVP.Columns.Add("ColumnNr", typeof(int));
            dtCellTVP.Columns.Add("Value");

            //var dtRowTVP = new DataTable("TVP_ImportVarieties");
            dtRowTVP.Columns.Add("RowNr", typeof(int));

            //create columns for fixed cols
            foreach (var key in fixedCols.Keys)
            {
                var fixedCol = fixedCols[key];
                dtRowTVP.Columns.Add(fixedCol.Name, fixedCol.DataType);
            }

            //add breeding station and synccode seperately because value is not from grid but from variable declared on phenome
            //cropcode is sent as seperate parameter on stored procedure.
            dtRowTVP.Columns.Add("BrStationCode", typeof(string));
            dtRowTVP.Columns.Add("SyncCode", typeof(string));

            //var dtColumnsTVP = new DataTable("TVP_Column");
            dtColumnsTVP.Columns.Add("ColumnNr", typeof(int));
            dtColumnsTVP.Columns.Add("TraitID", typeof(int));
            dtColumnsTVP.Columns.Add("ColumnLabel", typeof(string));
            dtColumnsTVP.Columns.Add("DataType", typeof(string));
            dtColumnsTVP.Columns.Add("VariableID", typeof(string));
            dtColumnsTVP.Columns.Add("PhenomeColID", typeof(string));


            //var lotTVP = new DataTable("TVP_Lot");
            lotTVP.Columns.Add("ID", typeof(int)); //lot ID
            lotTVP.Columns.Add("GID", typeof(int)); //Germplasm ID
            lotTVP.Columns.Add("Is Default", typeof(bool)); //Is Default
        }
        public Dictionary<string, (string Name, Type DataType)> PhenomeToPToVColumns()
        {
            //this list doesnot include cropcode, synccode and breedingstationcode
            //NOTE: It is very important that the sequence of this field should match the sequestion of defined TVP_ImportVarieties
            return new Dictionary<string, (string Name, Type DataType)>(StringComparer.OrdinalIgnoreCase)
            {
                {"GID", ("GID", typeof(int))},
                {"Gen", ("GenerationCode", typeof(string))},
                {"MalePar", ("MalePar", typeof(int))},
                {"FemalePar", ("FemalePar", typeof(int))},
                {"Maintainer", ("Maintainer", typeof(int))},
                {"Pedigree", ("StembookShort", typeof(string))},
                {"MasterNr", ("MasterNr", typeof(string))},
                {"Po nr", ("PONumber", typeof(string))},
                {"Stem", ("Stem", typeof(string))},
                {"Plasma typ", ("PlasmaType", typeof(string))},
                {"CMS source", ("CMSSource", typeof(string))},
                {"GMS", ("GMS", typeof(string))},
                {"Rest.genes", ("RestorerGenes", typeof(string))},
                {"TransferType", ("TransferType", typeof(string))},
                {"E-number", ("ENumber", typeof(string))},
                {"Name", ("Name", typeof(string))},
                {"Variety", ("VarietyName", typeof(string))}
            };
        }
        private async Task<SendToVarmasResult> SendToVarmasAsync(IEnumerable<SendToVarmasRequestArgs> requestargs, HashSet<int> sentVariList, SendToVarmasResult rs)
        {
            var invalidParentList = new HashSet<int>();
            var invalidVarietyList = new HashSet<int>();
            var varietyToIgnore = new HashSet<int>();

            var varietyIDs = requestargs.Select(o => o.VarietyID).ToList();
            var varietyDetails = await _varietyRepository.GetVarietyDetailsAsync(varietyIDs);
            var missingLotGIDs = varietyDetails.Where(x => x.LotNr <= 0).ToList();
            if (missingLotGIDs.Any())
            {
                var gids = string.Join(",", missingLotGIDs.Select(x => x.GID));
                rs.Errors.Add($"Following GID(s) do not have default Inventory record: { string.Join(", ", missingLotGIDs.Select(x => x.GID))} . Import Inventory record before sending to Varmas.");
                //There is no inventory lot for {GID}. Please provide one before importing"
                return rs;
            }
            if (varietyDetails.Any(o => o.ReplacingLot))
            {
                rs.Errors.Add("Selected record(s) are used for replacing lot. Send replaced lot data first if present.");
                return rs;
            }

            //Fetch already sent varieties with same stem
            var varietyListwithMatchingStem = await _varietyRepository.GetVarietiesWithStemAsync(varietyIDs);

            //validate if varieties are already sent to varmas
            var sentVarieties = varietyDetails.Where(o => o.StatusCode > 100).ToList();
            if (sentVarieties.Any())
            {
                //fetch data for replace lot
                var replacedLOT = await _varietyRepository.GetVarietyDetailForReplacedLotAsync(string.Join(",", sentVarieties.Select(x => x.VarietyID.ToString())));
                varietyDetails = varietyDetails.Concat(replacedLOT);

            }
            //validate if required fields are present in the mapped data
            var missedGIDs = varietyDetails.Where(o =>
                    string.IsNullOrWhiteSpace(o.NewCropCode) || string.IsNullOrWhiteSpace(o.ProdSegCode))
                .Select(o => o.GID).ToList();
            if (missedGIDs.Any())
            {
                var msg = $"New CropCode or Product Segment is missing for the following GIDs: ({string.Join(", ", missedGIDs)}).";
                throw new BusinessException(msg);
            }

            //varmas columns that is needed to send program field data
            var varmasCols = PtoVToVarmasColumns();

            var getVarmasLabel = new Func<string, string>(o =>
            {
                if (string.IsNullOrWhiteSpace(o))
                    return string.Empty;
                return varmasCols.ContainsKey(o) ? varmasCols[o] : string.Empty;
            });

            var crop = varietyDetails.FirstOrDefault()?.CropCode;
            //send only not already sent variety
            var varieties = varietyDetails
                .Where(x => !sentVarieties.Any(y => y.VarietyID == x.VarietyID))
                .ToList();
            //get converted data based on crop code
            var requestArgs = new GetGermplasmRequestArgs
            {
                FileName = crop,
                PageNumber = 1,
                PageSize = int.MaxValue,
                ForSendToVarmas = true,
                Filter = varieties.Select(o => new Entities.Args.Abstract.Filter
                {
                    Expression = "contains",
                    Name = "gid",
                    Value = o.GID.ToString(),
                    Operator = "OR"
                }).ToList()
            };
            var data = await _repo.GetMappedGermplasmAsync(requestArgs);

            //now segregate data into two dataset 
            var columns = data.Data.Columns.AsEnumerable()
                .Select(o => new
                {
                    TraitID = o.Field<int?>("TraitID"),
                    ColumnLabel = o.Field<string>("ColumnLabel"),
                    RefColumn = o.Field<string>("RefColumn"),
                    ScrFldNr = o.Field<int?>("ScreeningFieldNr"),
                    ColorCode = o.Field<int?>("ColorCode")
                }).ToList();

            var programFields = columns.Where(o => o.TraitID == null).ToList();
            var scrFields = columns.Where(o => o.TraitID != null).ToList();

            #region Trait and Program Values Processing

            var dt = data.Data.Data;
            var soapErrors = new List<string>();
            var mainGID = requestargs.FirstOrDefault().MainGID;
            var newGID = requestargs.FirstOrDefault().NewGID;
            var forcedBit = requestargs.FirstOrDefault().ForcedBit;
            var skipgids = requestargs.FirstOrDefault().SkipGID;
            if (skipgids == null)
                skipgids = new List<int>();

            //process for each variety separately
            using (var svc = new VarmasSoapClient
            {
                Url = ConfigurationManager.AppSettings["VarmasServiceUrl"],
                //Credentials = new NetworkCredential(credentials.UserName, credentials.Password)
            })
            {
                for (int i = 0; i < varieties.Count; i++)
                {
                    var variety = varieties[i];
                    if (sentVariList.Contains(variety.VarietyID))
                    {
                        continue;
                    }
                    if (invalidParentList.Contains(variety.GID))
                    {
                        rs.Errors.Add($"{variety.GID}, Error on sending parent information.");
                        skipgids.Add(variety.GID);
                        continue;
                    }
                    if (varietyToIgnore.Contains(variety.GID))
                    {
                        continue;
                    }
                    // Skip GID already processed
                    if (skipgids.Contains(variety.GID))
                    {
                        continue;
                    }
                    // Check in stem os only done for parents
                    if (variety.TransferType.EqualsIgnoreCase("Maintainer") || variety.TransferType.EqualsIgnoreCase("Male") || variety.TransferType.EqualsIgnoreCase("Female"))
                    {
                        // For normal flow
                        if (!forcedBit)
                        {
                            //Check if there is already Varmas variety with same data: if Yes show popup in UI to choose option
                            var varList = varietyListwithMatchingStem.Where(o => o.Stem == variety.Stem && o.VarietyID != variety.VarietyID).ToList();
                            if (varList.Any())
                            {
                                var returndata = new SendToVarmasResult();
                                var msg = variety.GID.ToString() + ", " + (varList.Count() > 1 ? "Varieties already exist with stem " : "Variety already exists with stem ") + variety.Stem + ".";
                                returndata.Results.AddRange(varList.Select(o => new VarmasResponse() { GID = o.GID, ENumber = o.ENumber, VarietyNr = o.VarmasVarietyNr, VarietyID = o.VarietyID, StatusCode = o.StatusCode }));
                                returndata.Warning = new Warning() { GID = variety.GID, Message = msg, SkipGID = skipgids };
                                return returndata;
                            }
                            else
                                skipgids.Add(variety.GID);
                        }
                        // After confirmation from UI
                        else if (mainGID != newGID)
                        {
                            if (mainGID > 0 && variety.GID != mainGID)
                                continue;

                            var germplasm = new VarietyResult();

                            if (variety.TransferType.EqualsIgnoreCase("Maintainer"))
                            {
                                germplasm = varieties.Where(o => o.Maintainer == mainGID).FirstOrDefault();
                                if (germplasm != null)
                                {
                                    germplasm.Maintainer = newGID;

                                    var rows = dt.Select($"GID = {germplasm.GID}");
                                    if (rows.Any())
                                        rows[0]["Maintainer"] = newGID;
                                }
                            }

                            if (variety.TransferType.EqualsIgnoreCase("Female"))
                            {
                                germplasm = varieties.Where(o => o.FemaleParent == mainGID).FirstOrDefault();
                                if (germplasm != null)
                                {
                                    germplasm.FemaleParent = newGID;

                                    var rows = dt.Select($"GID = {germplasm.GID}");
                                    if (rows.Any())
                                        rows[0]["FemalePar"] = newGID;
                                }                                    
                            }

                            if (variety.TransferType.EqualsIgnoreCase("Male"))
                            {
                                germplasm = varieties.Where(o => o.MaleParent == mainGID).FirstOrDefault();
                                if (germplasm != null)
                                {
                                    germplasm.MaleParent = newGID;

                                    var rows = dt.Select($"GID = {germplasm.GID}");
                                    if(rows.Any())
                                        rows[0]["MalePar"] = newGID;
                                }
                            }

                            //Update in database
                            if (germplasm != null)
                                await _varietyRepository.UpdateVarietyLinkAsync(germplasm.VarietyID, variety.TransferType, newGID);

                            skipgids.Add(variety.GID); // Skip check on already checked GIDs. For example: when female parent is already transferred and popup comes for Male then skip stem check for female
                            forcedBit = false;

                            continue;
                        }
                        else
                        {
                            skipgids.Add(variety.GID); // Skip check on already checked GIDs. For example: when female parent is already transferred and popup comes for Male then skip stem check for female
                            forcedBit = false;
                        }
                    }
                    try
                    {
                        var programValues = new Dictionary<string, string>();
                        var scrValues = new Dictionary<string, string>();

                        var isValid = true;

                        #region Process Variety wise data sets

                        var dr = dt.Select($"VarietyID={variety.VarietyID}").FirstOrDefault();
                        if (dr == null)
                            continue;
                        //process program fields
                        var value = string.Empty;
                        var label = string.Empty;
                        foreach (var programField in programFields)
                        {
                            if (dt.Columns.Contains(programField.ColumnLabel))
                            {
                                value = dr[programField.ColumnLabel].ToText();
                                label = getVarmasLabel(programField.ColumnLabel);
                                if (!string.IsNullOrWhiteSpace(label) && !string.IsNullOrWhiteSpace(value))
                                    programValues.Add(label, SecurityElement.Escape(value));
                            }
                        }

                        //send linked variety program field, this cannot be fetched as program field data so need to add here.
                        //varmasVarietyNr is only fetched for replace lot, linkedVariety is only fetched for normal variety.
                        if (variety.Linkedvariety > 0 && variety.StatusCode <= 100)
                        {
                            programValues.Add("linkedvariety", variety.Linkedvariety.ToText());
                        }
                        //send linked lot id for replace lot. this is required when replace lot is done with already sent variety's lot 
                        //for normal replace lot with new vareity this field is not needed
                        if(variety.linkedlot > 0)
                        {
                            programValues.Add("linkedlot", variety.linkedlot.ToText());
                        }


                        //process trait fields
                        //if there is value in RefColumn, need to check if value for that field is 0 or 1. Also check 0 or 1 for color code in column list
                        //if value is 0, we will send data to varmas
                        foreach (var scrField in scrFields)
                        {
                            if ((scrField.ColorCode ?? 0) != 0)
                            {
                                isValid = false;
                                break;
                            }

                            if (string.IsNullOrWhiteSpace(scrField.RefColumn))
                            {
                                isValid = false;
                                break;
                            }

                            var refFlag = 1;
                            if (dt.Columns.Contains(scrField.RefColumn))
                            {
                                refFlag = dr[scrField.RefColumn].ToInt32();
                            }

                            //refcolumn value and column's color code both should be 0 to proceed
                            if (refFlag != 0)
                            {
                                isValid = false;
                                break;
                            }

                            var columnLabel = scrField.TraitID.ToText();
                            if (dt.Columns.Contains(columnLabel))
                            {
                                value = dr[columnLabel].ToText();
                                if (!string.IsNullOrWhiteSpace(value))
                                    scrValues.Add(scrField.ScrFldNr.ToText(), SecurityElement.Escape(value));
                                //scrValues.Add(scrField.ScrFldNr.ToText(), value);

                            }
                        }

                        #endregion

                        if (!isValid)
                        {
                            rs.Errors.Add($"{variety.GID}, Conversion is missing.");
                            invalidVarietyList.Add(variety.GID);
                            AddToInvalidList(varieties, variety.Parent, sentVariList, varietyToIgnore, invalidParentList);
                            continue;
                        }

                        //handle OPAsParent logic. We need to send IsParent=True in this case. So, we just change the transfer type of Female for this.
                        var selectedOpAsParent = requestargs.FirstOrDefault(o => o.VarietyID == variety.VarietyID);
                        var transferType = selectedOpAsParent?.OPAsParent == true ? "Female" : variety.TransferType;

                        //get varietyNr of parent
                        
                        var varietyNr = await _varietyRepository.GetVarietyNrOfParentAsync(variety.GID);
                        var programFieldCode = getVarmasLabel("MalePar");
                        if (programValues.TryGetValue(programFieldCode,out _) && varietyNr?.MaleParent <= 0)
                        {
                            rs.Errors.Add($"{variety.GID}, VarietyNr of male parent is not found on Relation table.");
                            invalidVarietyList.Add(variety.GID);
                            AddToInvalidList(varieties, variety.Parent, sentVariList, varietyToIgnore, invalidParentList);
                            continue;
                        }
                        if (varietyNr?.MaleParent >= 0)
                        {

                            programValues[programFieldCode] = varietyNr.MaleParent.ToText();

                        }
                        programFieldCode = getVarmasLabel("FemalePar");
                        if (programValues.TryGetValue(programFieldCode, out _) && varietyNr?.FemaleParent <= 0)
                        {
                            rs.Errors.Add($"{variety.GID}, VarietyNr of female parent is not found on Relation table.");
                            invalidVarietyList.Add(variety.GID);
                            AddToInvalidList(varieties, variety.Parent, sentVariList, varietyToIgnore, invalidParentList);
                            continue;
                        }
                        if (varietyNr?.FemaleParent >= 0)
                        {

                            programValues[programFieldCode] = varietyNr.FemaleParent.ToText();

                        }
                        programFieldCode = getVarmasLabel("Maintainer");
                        if (programValues.TryGetValue(programFieldCode, out _) && varietyNr?.Maintainer <= 0)
                        {
                            rs.Errors.Add($"{variety.GID}, VarietyNr of Maintainer is not found on Relation table.");
                            invalidVarietyList.Add(variety.GID);
                            AddToInvalidList(varieties, variety.Parent, sentVariList, varietyToIgnore, invalidParentList);
                            continue;
                        }
                        if (varietyNr?.Maintainer >= 0)
                        {

                            programValues[programFieldCode] = varietyNr.Maintainer.ToText();
                        }

                        //prepare SOAP Model and request
                        var model = new
                        {
                            UserName = _userContext.GetContext().Name,
                            variety.SyncCode,
                            variety.VarmasVarietyNr,
                            variety.CropCode,
                            variety.BrStationCode,
                            variety.GID,
                            TransferType = transferType,
                            IsParent = (transferType.ToText().EqualsIgnoreCase("female") || transferType.ToText().EqualsIgnoreCase("male") || transferType.ToText().EqualsIgnoreCase("maintainer")) ? true : false,//variety.Child > 0 ? true : false,,
                            variety.LotNr,
                            ProgramValues = programValues,
                            ScrValues = scrValues,
                            UsePONumber = variety.UsePoNr
                        };

                        #region validation on sending data to varmas
                        if (string.IsNullOrWhiteSpace(model.SyncCode))
                        {
                            rs.Errors.Add($"{variety.GID}, Sync Code can not be blank or empty.");
                            invalidVarietyList.Add(variety.GID);
                            AddToInvalidList(varieties, variety.Parent, sentVariList, varietyToIgnore, invalidParentList);
                            continue;
                        }
                        if (string.IsNullOrWhiteSpace(model.CropCode))
                        {
                            rs.Errors.Add($"{variety.GID}, Crop code can not be blank or empty.");
                            invalidVarietyList.Add(variety.GID);
                            AddToInvalidList(varieties, variety.Parent, sentVariList, varietyToIgnore, invalidParentList);
                            continue;
                           
                        }
                        if (string.IsNullOrWhiteSpace(model.BrStationCode))
                        {
                            rs.Errors.Add($"{variety.GID}, Breedingstation code can not be blank or empty.");
                            invalidVarietyList.Add(variety.GID);
                            AddToInvalidList(varieties, variety.Parent, sentVariList, varietyToIgnore, invalidParentList);
                            continue;
                        }
                        if (model.GID <= 0)
                        {
                            rs.Errors.Add($"{variety.GID}, Germplasm id can not be blank or empty.");
                            invalidVarietyList.Add(variety.GID);
                            AddToInvalidList(varieties, variety.Parent, sentVariList, varietyToIgnore, invalidParentList);
                            continue;
                            
                        }
                        if (string.IsNullOrWhiteSpace(model.TransferType))
                        {
                            rs.Errors.Add($"{variety.GID}, Transfer type can not be blank or empty.");
                            invalidVarietyList.Add(variety.GID);
                            AddToInvalidList(varieties, variety.Parent, sentVariList, varietyToIgnore, invalidParentList);
                            continue;
                           
                        }
                        #endregion

                        svc.Model = model;
                        var resp = await svc.SendToVarmasAsync();
                        if (!resp.Success)
                        {
                            rs.Errors.Add($"{variety.GID}: {resp.Message}");
                            if (variety.Parent > 0)
                            {
                                invalidParentList.Add(variety.Parent);
                            }
                            continue;
                        }

                        var args = new UpdateVarmasResponse
                        {
                            VarietyID = variety.VarietyID,
                            GID = variety.GID,
                            VarietyNr = resp.VarietyNr,
                            ENumber = resp.Enumber,
                            LotNr = resp.LotNr,
                            PhenomeLotID = variety.LotNr,
                            VarietyStatus = resp.VarietyStatus,
                            VarietyName = resp.VarietyName
                        };

                        //save to database
                        var updateResult = await _varietyRepository.UpdateVarmasResponseAsync(args);
                        rs.Results.Add(new VarmasResponse
                        {
                            VarietyID = variety.VarietyID,
                            VarietyNr = args.VarietyNr,
                            ENumber = args.ENumber,
                            StatusCode = updateResult?.StatusCode ?? 0,
                            StatusName = updateResult?.StatusName
                        });
                        sentVariList.Add(variety.VarietyID);

                    }
                    catch (Exception innerEx)
                    {
                        if (innerEx is SoapException)
                        {
                            var detail = (innerEx as SoapException).Detail;
                            soapErrors.Add($"{variety.GID}: {innerEx.Message}: {detail}");
                        }
                        rs.Errors.Add($"{variety.GID}: {innerEx.Message}");
                    }
                }
            }
            #endregion

            //if there are any errors or warnings, log it to UEL
            if (rs.Errors.Any())
            {
                try
                {
                    var msg = string.Join(Environment.NewLine, rs.Errors);
                    var innerMsg = string.Join(Environment.NewLine, soapErrors);
                    await _uelService.LogAsync(new Exception(msg, new Exception(innerMsg)));
                }
                catch (Exception)
                {
                    //rs.Errors.Add($"UEL: {ex.Message}");
                }
            }
            return rs;
        }

        private async Task<SendToVarmasResult> SyncToVarmas(IEnumerable<int> requestargs, HashSet<int> sentVariList, SendToVarmasResult rs)
        {
            //var varietyDetails = await _varietyRepository.GetVarietyDetailsAsync(requestargs);

            //varmas columns that is needed to send program field data
            //var varmasCols = PtoVToVarmasColumns();

            //var getVarmasLabel = new Func<string, string>(o =>
            //{
            //    if (string.IsNullOrWhiteSpace(o))
            //        return string.Empty;
            //    return varmasCols.ContainsKey(o) ? varmasCols[o] : string.Empty;
            //});

            // var crop = varietyDetails.FirstOrDefault()?.CropCode;

            //if there are any errors or warnings, log it to UEL
            if (rs.Errors.Any())
            {
                try
                {
                    var msg = GetSendToVarmasUELTemplate(rs);
                    await _uelService.LogAsync(new Exception(msg));
                }
                catch (Exception)
                {
                    //rs.Errors.Add($"UEL: {ex.Message}");
                }
            }
            return rs;
        }
        private bool AddToInvalidList(List<VarietyResult> varieties, int child, HashSet<int> sentVariList, HashSet<int> varietyToIgnore, HashSet<int> invalidCHildrenList)
        {
            //if maintainer fails, block female, male and parent
            //if female fails block male and parent
            //if male fails block parent
            var parent = varieties.Where(x => x.GID == child).FirstOrDefault();
            //if (variety.Parent > 0)
            if (parent != null)
            {
                var female = parent.FemaleParent;
                var male = parent.MaleParent;
                if (!sentVariList.Contains(female))
                {
                    varietyToIgnore.Add(female);
                }
                if (!sentVariList.Contains(male))
                {
                    varietyToIgnore.Add(male);
                }
                invalidCHildrenList.Add(child);
                return false;
            }
            return true;
        }

        //private bool LoadPhenomeDataToTVP(List<PhenomeColumnInfo> columns, List<PhenomeColumnInfo> mainColumns, List<XElement> cells, DataRow drRow, int rowNr,
        //    DataTable dtCellTVP, string gid, string parentGID, Dictionary<string, (string Name, Type DataType)> fixedCols, GermplasmsImportResult result, Dictionary<int, string> CmsGermplasm, bool hasCMS)
        private bool LoadPhenomeDataToTVP(List<PhenomeColumnInfo> columns, List<PhenomeColumnInfo> mainColumns, List<XElement> cells, DataRow drRow,
           DataTable dtCellTVP, string gid, string offSpringGID, Dictionary<string, (string Name, Type DataType)> fixedCols, GermplasmsImportResult result, bool requiresPoNr, int rowNr)
        {
            var colindex = 0;
            //var genoType = string.Empty;
            //var isCMS = false;
            for (int j = 0; j < columns.Count; j++)
            {
                var col = columns[j];
                colindex = j;
                var cellval = cells[col.Index].Value;
                if (!string.IsNullOrEmpty(offSpringGID))
                {
                    var item = mainColumns.FirstOrDefault(x => x.ColLabel == col.ColLabel);
                    if (item == null)
                        continue;
                    colindex = mainColumns.IndexOf(item);

                }
                if (col.ColLabel.EqualsIgnoreCase("Crop") || col.ColLabel.EqualsIgnoreCase("SyncCode") || col.ColLabel.EqualsIgnoreCase("Breeding Station"))
                    continue;

                //check if columns is fixed columns
                if (fixedCols.ContainsKey(col.ColLabel))
                {
                    var fixedCol = fixedCols[col.ColLabel];
                    //GID is already added in the row so ignore it even if it is in fixed cols
                    if (!fixedCol.Name.EqualsIgnoreCase("GID"))
                    {
                        //check if po nr if empty or not based on condition
                        if (requiresPoNr && col.ColLabel.EqualsIgnoreCase("Po nr") && string.IsNullOrWhiteSpace(cellval))
                        {
                            result.Errors.Add("Po nr can not be blank on Phenome.");
                            return false;

                        }
                        ////convert value based on datatype if necessary for fixed columns
                        //if (fixedCol.DataType == typeof(bool))
                        //{                            
                        //    cellval = (cellval.EqualsIgnoreCase("Y") || cellval.EqualsIgnoreCase("True") || cellval.EqualsIgnoreCase("1")).ToString();
                        //}

                        //add values to row table if it is fixed columns
                        drRow[fixedCol.Name] = cellval;

                        //validtation on master number/Generation code/Transfer type and set transferType if present
                        //validation is now only done for generation code (master number also removed from valiation)
                        if (!ValidateData(fixedCol, cellval, gid, offSpringGID, result))
                            return false;
                    }
                }
                else if (!string.IsNullOrWhiteSpace(cellval))
                {
                    //only added to cell if it is not fixed columns
                    var drCell = dtCellTVP.NewRow();
                    drCell["RowNr"] = rowNr; //i is already incremented
                    drCell["ColumnNr"] = colindex;
                    drCell["Value"] = cellval;
                    dtCellTVP.Rows.Add(drCell);
                }
            }
            return true;
        }


        private bool ValidateData((string Name, Type DataType) fixedCol, string cellval, string gid, string parentGID, GermplasmsImportResult result)
        {
            //if ((fixedCol.Name.EqualsIgnoreCase("MasterNumber") || fixedCol.Name.EqualsIgnoreCase("Gen") || fixedCol.Name.EqualsIgnoreCase("Transfer type")) && string.IsNullOrWhiteSpace(cellval))
            //if ((fixedCol.Name.EqualsIgnoreCase("MasterNr") || fixedCol.Name.EqualsIgnoreCase("GenerationCode")) && string.IsNullOrWhiteSpace(cellval))
            //master number validaton removed 
            if (fixedCol.Name.EqualsIgnoreCase("GenerationCode") && string.IsNullOrWhiteSpace(cellval))
            {
                if (string.IsNullOrWhiteSpace(parentGID))
                    result.Errors.Add($"GID: {gid}, {fixedCol.Name} can not be blank or empty.");
                else
                    result.Errors.Add($"GID: {gid}, {fixedCol.Name} can not be blank or empty for its parent GID({parentGID}).");

                result.Status = "0";
                return false;
            }

            //for now transfer type is ignored which should be implemented later
            #region validate on transfer type
            ////validation on male and female parent if transfer type is CMS or Hybrid but not OP(Open pollinated)
            //if (fixedCol.Name.EqualsIgnoreCase("Transfer type"))
            //{
            //    transferType = cellval;
            //}
            //if (fixedCol.Name.EqualsIgnoreCase("Transfer type"))
            //{
            //    maleParent = cellval;
            //}
            //if (fixedCol.Name.EqualsIgnoreCase("Transfer type"))
            //{
            //    femaleParent = cellval;
            //}
            #endregion
            return true;
        }

        private async Task<Dictionary<string, string>> GetBOVariablesAsync(RestClient client, int folderID)
        {
            return await GetVariablesAsync(client, $"/api/v1/folder/info/{folderID}");
        }

        private async Task<Dictionary<string, string>> GetRGVariablesAsync(RestClient client, int researchGroupID)
        {
            return await GetVariablesAsync(client, $"/api/v1/researchgroup/info/{researchGroupID}");
        }

        private async Task<Dictionary<string, string>> GetVariablesAsync(RestClient client, string url)
        {
            var variables = await client.PostAsync(url, o => { });
            await variables.EnsureSuccessStatusCodeAsync();
            var folderInfo = await variables.Content.DeserializeAsync<PhenomeFolderInfo>();
            if (folderInfo != null)
            {
                if (folderInfo.Status != "1")
                {
                    throw new UnAuthorizedException(folderInfo.Message);
                }

                var values = (from t1 in folderInfo.Info.RG_Variables
                              join t2 in folderInfo.Info.BO_Variables on t1.VID equals t2.VID
                              select new
                              {
                                  t1.Name,
                                  t2.Value
                              }).ToList();
                return values.ToDictionary(k => k.Name, v => v.Value, StringComparer.OrdinalIgnoreCase);
            }
            return new Dictionary<string, string>();
        }

        private string GetSendToVarmasUELTemplate(object model)
        {
            var body = typeof(VarmasSoapClient).Assembly.GetString(
                "Enza.PtoV.Services.Requests.UELCreateVarmasVariety.st");
            return Template.Render(body, model);
        }

        private Dictionary<string, string> PtoVToVarmasColumns()
        {
            //all columns(fixed and non-fixed) from column table. So, we should map columns from columns except few fixed columns
            return new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
            {
                {"Gen", "bgenc_genercod"},
                {"Pedigree", "bvarc_stbdescr"},
                {"PedigrAbbr", "bvarc_stbshort"},
                {"Fieldbooks", "bvarc_fieldbook"},
                {"Plantnumbr", "bvarc_plantnrs"},
                {"Line 1", "bvarc_descline1"},
                {"Line 2", "bvarc_descline2"},
                {"Line B", "bvarc_descline3"},
                {"PO nr", "bvarc_ponbr"},
                {"CMS source", "bcmsc_sourcecod"},
                {"Rest.genes", "bvarc_restorergenes"},
                {"Plasma typ", "bpltc_pltypecod"},
                {"GMS", "bvarl_gms"},
                {"SI", "bvarl_selfincomp"},
                {"Fert", "bferc_fertilitycod"},
                {"Seg.ratio", "bvarc_segratio"},
                {"Exp.res", "bvarc_expresist"},
                {"ExpResCalc", "bvard_exprescalc"},
                {"Tested res", "bvarc_resist"},
                {"TestResCal", "bvard_rescalc"},
                {"MasterNr", "bvarc_mastnumber"},
                {"E-number", "vvarc_enumber"},
                {"MalePar", "vvarn_male"},
                {"FemalePar", "vvarn_female"},
                {"Maintainer", "vvarn_maintainer"},
                {"Stem", "bvarc_stem"},
                {"Stemtail", "bvarc_stemtail"},
                {"Newcrop", "vncrc_cropcod"},
                {"Prod.Segment", "vprdc_prodsegcod"},
                {"Origin Country", "gcouc_cntrycod"}
            };
        }


        private async Task<IEnumerable<GermPlasmParentInfo>> GetMaintainersOfGIDsAsync(RestClient client,
            GermplasmsImportRequestArgs args,
            IEnumerable<int> germplasms, IEnumerable<Column> cols)
        {
            var gids = string.Join(",", germplasms);
            var args1 = new GermplasmsImportRequestArgs
            {
                ObjectID = args.CropID.ToText(),
                ObjectType = "5",
                GridID = "G7654321"
            };
            //filter value 
            var filerValue = "\"GER~id\":\"=" + gids + "\"";
            //this will prepare grid with filter parameter
            await PreparePhemomeGrid(args1, client, cols.Serialize(), filerValue);

            //var totalGIDs = germplasms.Count();
            var totalGIDs = int.MaxValue;
            //get data
            var url = "/api/v1/simplegrid/grid/show_grid/Germplasms?" +
                      $"object_type={args1.ObjectType}&" +
                      $"object_id={args1.ObjectID}&" +
                      $"grid_id={args1.GridID}&" +
                      "gems_map_id=0&" +
                      "add_header=1&" +
                      $"rows_per_page={totalGIDs}&" +
                      "use_name=name&" +
                      "display_column=0&" +
                      "posStart=0&" +
                      $"count={totalGIDs}";
            var dataResp = await client.GetAsync(url);
            await dataResp.EnsureSuccessStatusCodeAsync();
            var dataStream = await dataResp.Content.ReadAsStreamAsync();

            var doc = XDocument.Load(dataStream);
            var columns2 = doc.Descendants("column")
            .Select((x, i) => new PhenomeColumnInfo
            {
                ID = x.Attribute("id")?.Value,
                Index = i
            }).ToList();

            var columns = (from t1 in cols
                           join t2 in columns2 on t1.id equals t2.ID
                           select new PhenomeColumnInfo
                           {
                               ID = t2.ID,
                               Index = t2.Index,
                               ColName = t1.desc,
                               ColLabel = t1.desc
                           }).ToList();

            var maleParentIndex = columns.FirstOrDefault(x => x.ID.EqualsIgnoreCase("GP2~id"));
            var femaleParentIndex = columns.FirstOrDefault(x => x.ID.EqualsIgnoreCase("GP1~id"));
            var maleParentGenIndex = columns.FirstOrDefault(x => x.ID.ToText().ToLower().StartsWith("gp2") && x.ColLabel.ToText().ToLower().Contains("gen"));
            var femaleParentGenIndex = columns.FirstOrDefault(x => x.ID.ToText().ToLower().StartsWith("gp1") && x.ColLabel.ToText().ToLower().Contains("gen"));

            var items = new List<GermPlasmParentInfo>();
            //load data to xml
            var rows = doc.Descendants("row");
            foreach (var dr in rows)
            {

                var gid = dr.Attribute("id").Value.ToInt32();
                if (germplasms.FirstOrDefault(x => x == gid) <= 0)
                    continue;
                var cells = dr.Descendants("cell").ToList();
                //add maintainers in the list if it is not already available in germplasm list
                int value;
                if (!int.TryParse(cells[maleParentIndex.Index].Value, out value))
                {
                    int.TryParse(cells[femaleParentIndex.Index].Value, out value);
                }
                var gen = cells[maleParentGenIndex.Index].Value;
                if (string.IsNullOrWhiteSpace(gen))
                {
                    gen = cells[femaleParentGenIndex.Index].Value;
                }
                if (value > 0)
                {
                    if (!germplasms.Any(x => x == value))
                    {
                        //maintainer found, include it into germplasm list
                        items.Add(new GermPlasmParentInfo
                        {
                            BaseGID = gid,
                            GID = value,
                            Gen = gen,
                            TransferType = "Maintainer"
                        });
                    }
                }
            }
            return items;
        }

        private async Task<MaintainerInfo> GetMaintainerOfGIDAsync(RestClient client, GermplasmsImportRequestArgs requestArgs, IEnumerable<Column> cols, int gid, bool isBulbCrop)
        {
            //only fetch maintainer if gen starts with 'a' of it's female GID
            //if isBulbCrop flag is true, get very first GID of same generation of male, female and maintainer

            #region GET DATA

            //filter value 
            var filerValue = $"\"GER~id\":\"={gid}\"";
            //this will prepare grid with filter parameter

            var totalGIDs = int.MaxValue;
            await PreparePhemomeGrid(requestArgs, client, cols.Serialize(), filerValue);

            //get data
            var url = "/api/v1/simplegrid/grid/show_grid/Germplasms?" +
                      $"object_type={requestArgs.ObjectType}&" +
                      $"object_id={requestArgs.ObjectID}&" +
                      $"grid_id={requestArgs.GridID}&" +
                      "gems_map_id=0&" +
                      "add_header=1&" +
                      $"rows_per_page={totalGIDs}&" +
                      "use_name=name&" +
                      "display_column=0&" +
                      "posStart=0&" +
                      $"count={totalGIDs}";

            var dataResp = await client.GetAsync(url);
            await dataResp.EnsureSuccessStatusCodeAsync();
            var dataStream = await dataResp.Content.ReadAsStreamAsync();
            var doc = XDocument.Load(dataStream);

            var columns2 = doc.Descendants("column")
            .Select((x, i) => new PhenomeColumnInfo
            {
                ID = x.Attribute("id")?.Value,
                Index = i
            }).ToList();

            var columns = (from t1 in cols
                           join t2 in columns2 on t1.id equals t2.ID
                           select new PhenomeColumnInfo
                           {
                               ID = t2.ID,
                               Index = t2.Index,
                               ColName = t1.desc,
                               ColLabel = t1.desc
                           }).ToList();

            var maleParentIndex = columns.FirstOrDefault(x => x.ID.EqualsIgnoreCase("GP2~id"));
            var femaleParentIndex = columns.FirstOrDefault(x => x.ID.EqualsIgnoreCase("GP1~id"));
            var maleParentGenIndex = columns.FirstOrDefault(x => x.ID.ToText().ToLower().StartsWith("gp2") && x.ColLabel.ToText().ToLower().Contains("gen"));
            var femaleParentGenIndex = columns.FirstOrDefault(x => x.ID.ToText().ToLower().StartsWith("gp1") && x.ColLabel.ToText().ToLower().Contains("gen"));
            var maleParentPONrIndex = columns.FirstOrDefault(x => x.ID.ToText().ToLower().StartsWith("gp2") && x.ColLabel.ToText().ToLower().Contains("po nr"));
            var femaleParentPONrIndex = columns.FirstOrDefault(x => x.ID.ToText().ToLower().StartsWith("gp1") && x.ColLabel.ToText().ToLower().Contains("po nr"));

            var items = new List<GermPlasmParentInfo>();
            //load data to xml
            int parentGID;
            string parentGen;
            string parentPONr;

            var rows = doc.Descendants("row");
            foreach (var dr in rows)
            {
                var gid2 = dr.Attribute("id").Value.ToInt32();
                var cells = dr.Descendants("cell").ToList();

                //skip if gid filter, retrieves other than filter gids
                if (gid2 != gid)
                    continue;

                if (!int.TryParse(cells[maleParentIndex.Index].Value, out parentGID))
                {
                    if (!int.TryParse(cells[femaleParentIndex.Index].Value, out parentGID))
                        continue;
                }
                parentGen = cells[maleParentGenIndex.Index].Value;
                if (string.IsNullOrWhiteSpace(parentGen))
                {
                    parentGen = cells[femaleParentGenIndex.Index].Value;
                }
                parentPONr = cells[maleParentPONrIndex.Index].Value;
                if (string.IsNullOrWhiteSpace(parentPONr))
                {
                    parentPONr = cells[femaleParentPONrIndex.Index].Value;
                }

                var maintainer = new MaintainerInfo
                {
                    GID = gid,
                    MaintainerGID = parentGID,
                    MaintainerGen = parentGen,
                    MaintainerPONr = parentPONr
                };
                return maintainer;
            }
            #endregion

            return null;
        }


        public async Task<IEnumerable<GermplasmInfo>> GetGermplasmsAsync(HttpRequestMessage request,
            string cropCode,
            IEnumerable<int> gids,
            IEnumerable<string> cols)
        {
            var germplasms = new List<GermplasmInfo>();

            var germplasmObject = await _repo.GetPhenomeColumnDetailsAsync(cropCode);
            //var requiredColumns = new[] { "GID", "Gen", "PO nr" };
            var columns = germplasmObject
                .Columns
                .Where(x => cols.Contains(x.ColumnLabel, StringComparer.OrdinalIgnoreCase))
                .Select((x, i) => new Column
                {
                    id = x.PhenomeColID,
                    desc = x.ColumnLabel,
                    variable_id = x.VariableID,
                    col_num = i.ToString(),
                    properties = new List<ColumnProperty>
                    {
                        new ColumnProperty
                        {
                            id = x.PhenomeColID
                        }
                    }
                }).ToList();

            using (var client = new RestClient(_baseServiceUrl))
            {
                client.SetRequestCookies(request);

                var filerValue = $"\"GER~id\":\"={string.Join(",", gids)}\"";
                //this will prepare grid with filter parameter
                var requestArgs = new GermplasmsImportRequestArgs
                {
                    ObjectID = germplasmObject.ObjectID,
                    ObjectType = germplasmObject.ObjectType,
                    GridID = "GERM_321"
                };
                await PreparePhemomeGrid(requestArgs, client, cols.Serialize(), filerValue);

                //get data
                var url = "/api/v1/simplegrid/grid/show_grid/Germplasms?" +
                          $"object_type={requestArgs.ObjectType}&" +
                          $"object_id={requestArgs.ObjectID}&" +
                          $"grid_id={requestArgs.GridID}&" +
                          "gems_map_id=0&" +
                          "add_header=1&" +
                          $"rows_per_page=1&" +
                          "use_name=name&" +
                          "display_column=0&" +
                          "posStart=0&" +
                          $"count=1";

                var dataResp = await client.GetAsync(url);
                await dataResp.EnsureSuccessStatusCodeAsync();
                var dataStream = await dataResp.Content.ReadAsStreamAsync();
                var doc = XDocument.Load(dataStream);

                var columns2 = doc.Descendants("column")
                .Select((x, i) => new
                {
                    id = x.Attribute("id")?.Value,
                    index = i
                }).ToList();

                var finalColumns = (from t1 in columns
                                    join t2 in columns2 on t1.id equals t2.id
                                    select new PhenomeColumnInfo
                                    {
                                        ID = t2.id,
                                        Index = t2.index,
                                        ColName = t1.desc,
                                        ColLabel = t1.desc
                                    }).ToList();

                var rows = doc.Descendants("row");
                foreach (var dr in rows)
                {
                    var gid = dr.Attribute("id").Value.ToInt32();
                    var cells = dr.Descendants("cell").ToList();

                    //skip if gid filter, retrieves other than filter gids
                    if (!gids.Contains(gid))
                        continue;

                    var germplasm = new GermplasmInfo
                    {
                        GID = gid
                    };
                    foreach (var column in finalColumns)
                    {
                        if (!germplasm.Values.ContainsKey(column.ColLabel))
                        {
                            germplasm.Values.Add(column.ColLabel, cells[column.Index].Value);
                        }
                    }
                    germplasms.Add(germplasm);
                }
            }
            return germplasms;
        }

        public async Task ValidatePONrForCMSCropAsync(HttpRequestMessage request, VarietyInfo variety, int gid, TransferTypeForCropResult transferType)
        {
            var isBulbCrop = transferType.HasBulb;
            var usePONr = transferType.UsePONr;

            //get columns and object details of phenome from already imported information
            var germplasmsObject = await _repo.GetPhenomeColumnDetailsAsync(variety.CropCode);
            var requiredColumns = new[] { "GID", "Gen", "PO nr" };
            var columns = germplasmsObject.Columns
                .Where(x => requiredColumns.Contains(x.ColumnLabel, StringComparer.OrdinalIgnoreCase));

            var replacePrefix = new Func<string, string, string>((prefix, o) => string.Concat(prefix, o.Substring("GER~".Length)));
            var cols = columns.Select((x, i) => new Column
            {
                id = x.PhenomeColID,
                desc = x.ColumnLabel,
                variable_id = x.VariableID,
                col_num = i.ToString(),
                properties = new List<ColumnProperty>
                {
                    new ColumnProperty { id = x.PhenomeColID }
                }
            }).Concat(columns.Select((x, i) => new Column
            {
                id = replacePrefix("GP1~", x.PhenomeColID),
                desc = x.ColumnLabel,
                variable_id = x.VariableID,
                col_num = (i + requiredColumns.Length).ToString(),
                properties = new List<ColumnProperty>
                {
                    new ColumnProperty { id = replacePrefix("GP1~", x.PhenomeColID) }
                }
            })).Concat(columns.Select((x, i) => new Column
            {
                id = replacePrefix("GP2~", x.PhenomeColID),
                desc = x.ColumnLabel,
                variable_id = x.VariableID,
                col_num = (i + (requiredColumns.Length * 2)).ToString(),
                properties = new List<ColumnProperty>
                {
                    new ColumnProperty { id = replacePrefix("GP2~", x.PhenomeColID) }
                }
            }));

            using (var client = new RestClient(_baseServiceUrl))
            {
                client.SetRequestCookies(request);

                var args = new GermplasmsImportRequestArgs
                {
                    ObjectID = germplasmsObject.ObjectID,
                    ObjectType = germplasmsObject.ObjectType,
                    GridID = "GERM_123"
                };

                var maintainer = await GetMaintainerOfGIDAsync(client, args, cols, gid, isBulbCrop);
                if (maintainer?.MaintainerGID > 0)
                {
                    if (!isBulbCrop && usePONr)
                    {
                        if (string.IsNullOrWhiteSpace(maintainer?.MaintainerPONr))
                            throw new BusinessException($"PO nr of maintainer GID {maintainer.GID} is not available.");
                    }
                    if (isBulbCrop)
                    {
                        //loop through male parent of maintainer
                        var maintainer2 = await GetMaintainerOfGIDAsync(client, args, cols, maintainer.MaintainerGID, isBulbCrop);
                        if (maintainer2 != null)
                        {
                            while (maintainer.MaintainerGen.EqualsIgnoreCase(maintainer2?.MaintainerGen))
                            {
                                maintainer = maintainer2;
                                if (maintainer2?.MaintainerGID > 0)
                                {
                                    maintainer2 = await GetMaintainerOfGIDAsync(client, args, cols, maintainer2.MaintainerGID, isBulbCrop);
                                }
                            }
                        }
                    }
                }
                if (maintainer != null)
                {
                    if (usePONr && string.IsNullOrWhiteSpace(maintainer.MaintainerPONr))
                        throw new BusinessException($"PO nr of maintainer GID {maintainer.GID} is not available.");

                    if (!maintainer.MaintainerPONr.EqualsIgnoreCase(variety.MaintainerPONr))
                        throw new BusinessException($"The PO nr of GID: {variety.Maintainer} in PtoV and {maintainer.MaintainerGID} in Phenome don't match with each other.");
                }
            }
        }

        public async Task<string> GetAccessTokenAsync(string jwtToken)
        {
            var config = new
            {
                instance = "https://login.microsoftonline.com",
                tenant = ConfigurationManager.AppSettings["ida:tenant"],
                client_id = ConfigurationManager.AppSettings["ida:audience"],
                client_secret = ConfigurationManager.AppSettings["ida:client_secret"],
                resource_id = ConfigurationManager.AppSettings["ida:resource_id"]
            };
            using (var client = new RestClient(config.instance))
            {
                var response = await client.PostAsync($"/{config.tenant}/oauth2/v2.0/token", values =>
                {
                    values.Add("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer");
                    values.Add("client_id", config.client_id);
                    values.Add("client_secret", config.client_secret);
                    values.Add("requested_token_use", "on_behalf_of");
                    values.Add("scope", config.resource_id);
                    values.Add("assertion", jwtToken);
                });
                var result = await response.Content.ReadAsStringAsync();
                if (!response.IsSuccessStatusCode)
                {
                    throw new BusinessException("Unable to retrieve the access token for Phenome.");
                }
                var tokens = (JObject)JsonConvert.DeserializeObject(result);
                return tokens["access_token"].ToText();
            }
        }
    }
}
