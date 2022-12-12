using System;
using System.Data;
using System.Threading.Tasks;
using Enza.UTM.DataAccess.Abstract;
using Enza.UTM.DataAccess.Data.Interfaces;
using Enza.UTM.DataAccess.Interfaces;
using Enza.UTM.Entities.Args;
using Enza.UTM.Entities.Results;
using System.Configuration;
using System.Net.Http;
using Enza.UTM.Services.Abstract;
using System.Collections.Generic;
using Enza.UTM.Common.Extensions;
using Enza.UTM.Common.Exceptions;
using System.Linq;
using System.IO;
using NPOI.XSSF.Streaming.Values;
using NPOI.SS.Formula.Functions;
using Enza.UTM.Entities.Args.Abstract;
using Enza.UTM.Services.Proxies;
using Enza.UTM.Entities;
using System.Text.RegularExpressions;
using log4net;
using Newtonsoft.Json;

namespace Enza.UTM.DataAccess.Data.Repositories
{
    public class SeedHealthRepository : Repository<object>, ISeedHealthRepository
    {
        private readonly IUserContext _userContext;
        private readonly string BASE_SVC_URL = ConfigurationManager.AppSettings["BasePhenomeServiceUrl"];
        private static readonly ILog _logger =
            LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);

        public SeedHealthRepository(IDatabase dbContext, IUserContext userContext) : base(dbContext)
        {
            _userContext = userContext;
        }

        public async Task<ExcelDataResult> GetDataAsync(SeedHealthGetDataRequestArgs requestArgs)
        {
            var result = new ExcelDataResult();
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_SH_GET_DATA, CommandType.StoredProcedure,
                args1 =>
                {
                    args1.Add("@TestID", requestArgs.TestID);
                    args1.Add("@Page", requestArgs.PageNumber);
                    args1.Add("@PageSize", requestArgs.PageSize);
                    args1.Add("@FilterQuery", requestArgs.ToFilterString());
                });
            if (data.Tables.Count == 2)
            {
                result.Success = true;
                var table0 = data.Tables[0];
                if (table0.Columns.Contains("TotalRows"))
                {
                    if (table0.Rows.Count > 0)
                    {
                        result.Total = table0.Rows[0]["TotalRows"].ToInt32();
                    }
                    table0.Columns.Remove("TotalRows");
                }
                if (table0.Columns.Contains("Total"))
                {
                    if (table0.Rows.Count > 0)
                    {
                        result.TotalCount = table0.Rows[0]["Total"].ToInt32();
                    }
                    table0.Columns.Remove("Total");
                }
                result.DataResult = new ExcelData
                {
                    Columns = data.Tables[1],
                    Data = table0
                };
            }
            else
            {
                result.Success = false;
                result.Errors.Add("Problem while fetching data.");
            }
            return result;
        }

        public async Task<PhenoneImportDataResult> ImportDataFromPhenomeAsync(HttpRequestMessage request, SeedHealthRequestArgs args)
        {
            var result = new PhenoneImportDataResult();

            var cropCode = "";
            var breedingStation = "";
            var syncCode = "";
            var countryCode = "";

            #region Prepare datatables for stored procedure call

            var dtCellTVP = new DataTable();
            var dtRowTVP = new DataTable();
            var dtColumnsTVP = new DataTable();

            PrepareTVPS(dtCellTVP, dtRowTVP, dtColumnsTVP);

            #endregion

            using (var client = new RestClient(BASE_SVC_URL))
            {
                var URI = "";
                client.SetRequestCookies(request);

                #region Get Variables detail from Tree Structure

                //call service to get crop code based on cropid
                URI = $"/api/v1/researchgroup/info/{ args.CropID}";
                var cropDetail = await GetFolderVariablesDetail(client, URI);
                if (!cropDetail.TryGetValue("Crop", out cropCode))
                {
                    result.Errors.Add("Crop code not found. Please add crop code first.");
                    return result;
                }
                if (string.IsNullOrWhiteSpace(cropCode))
                {
                    result.Errors.Add("CropCode can not be null or empty.");
                    return result;
                }

                //if (cropCode != args.CropCode)
                //{
                //    result.Errors.Add("Crop code in Phenome and S2S capacity don't match with each other");
                //    return result;
                //}

                //call service to get Breeding station and SyncCode based on breeding station level call on phenome from folder in tree structure.
                URI = $"/api/v1/folder/info/{ args.FolderID}";
                var importFrom = "";
                var breedingStationDetail = await GetFolderVariablesDetail(client, URI);
                if (!breedingStationDetail.TryGetValue("Breeding Station", out breedingStation) && !breedingStationDetail.TryGetValue("BreedStat", out breedingStation))
                {
                    result.Errors.Add("Breeding station not found. Please add Breeding station code first.");
                    return result;
                }

                if (string.IsNullOrWhiteSpace(breedingStation))
                {
                    result.Errors.Add("Breeding station can not be null or empty.");
                    return result;
                }
                //syncCode
                if (!breedingStationDetail.TryGetValue("SyncCode", out syncCode))
                {
                    result.Errors.Add("SyncCode not found. Please add SyncCode first.");
                    return result;
                }
                if (string.IsNullOrWhiteSpace(syncCode))
                {
                    result.Errors.Add("SyncCode can not be null or empty.");
                    return result;
                }
                //country code
                breedingStationDetail.TryGetValue("Country", out countryCode);

                #endregion                
                var requiredFields = new List<string>();
                //requiredFields.Add("LotID");

                //object type   
                //27=> crosses
                //28=> selections
                //37=> lot set

                //Crosses and selection
                if (args.ObjectType.EqualsIgnoreCase("27") || args.ObjectType.EqualsIgnoreCase("28"))
                {
                    //requiredFields.Add("LotID");
                    //requiredFields.Add("Plot name");
                    //URI = "/api/v1/simplegrid/grid/create/FieldPlots";
                    //URI = "/api/v1/simplegrid/grid/get_ordered_columns/InventoryLots";
                    URI = "/api/v1/simplegrid/grid/get_ordered_columns/InventoryLots";
                    importFrom = "InventoryLots";
                    //importFrom = "BaseObjects"; 
                }
                else
                {
                    URI = "/api/v1/simplegrid/grid/get_ordered_columns/InventorySets";
                    //URI = "/api/v1/simplegrid/grid/get_ordered_columns/InventoryLots";
                    importFrom = "InventorySets";
                    //importFrom = "InventoryLots";
                }
                

                var response = await client.PostAsync(URI, values =>
                {
                    values.Add("object_type", args.ObjectType);
                    values.Add("object_id", args.ObjectID);
                    values.Add("grid_id", args.GridID);
                });
                await response.EnsureSuccessStatusCodeAsync();

                var columnResponse = await response.Content.DeserializeAsync<PhenomeColumnsResponse>();
                if (!columnResponse.Success)
                {
                    result.Errors.Add($"Error getting response from Phenome. Please try again.");
                    return result;
                }


                var notFoundColumns = requiredFields.Where(x => !columnResponse.Columns.Any(y => y.desc.EqualsIgnoreCase(x)));
                if (notFoundColumns.Any())
                {
                    result.Errors.Add($"Following fields are required but not available in the Phenome grid: ({string.Join(",", notFoundColumns)}).");
                    return result;
                }

                if (!args.ForcedImport && columnResponse.Columns.Count > 50)
                {
                    result.Warnings.Add("You are importing more than 50 columns.This can lead to problem. We recommend to reduce the amount of columns in Phenome. Continue?");
                    return result;
                }


                //set display
                URI = $"/api/v1/simplegrid/grid/set_display/{importFrom}";
                var columnstring = columnResponse.Columns.ToJson();// JsonConvert.SerializeObject(columnResponse); //columnResponse

                var response1 = await client.PostAsync(URI, values =>
                {
                    values.Add("object_type", args.ObjectType);
                    values.Add("object_id", args.ObjectID);
                    values.Add("grid_id", args.GridID);
                    values.Add("columns", columnstring);
                });

                await response1.EnsureSuccessStatusCodeAsync();

                var columnResponse1 = await response1.Content.DeserializeAsync<PhenomeResponse>();
                if (!columnResponse1.Success)
                {
                    result.Errors.Add($"Error getting response from Phenome. Please try again.");
                    return result;
                }
                //filter grid
                URI = $"/api/v1/simplegrid/grid/filter_grid/{importFrom}";
                var response12 = await client.PostAsync(URI, values =>
                {
                    values.Add("object_type", args.ObjectType);
                    values.Add("object_id", args.ObjectID);
                    values.Add("grid_id", args.GridID);
                    values.Add("simple_filter", "{}");
                });
                await response12.EnsureSuccessStatusCodeAsync();

                var resp1111 = await response12.Content.DeserializeAsync<PhenomeResponse>();


                //get data
                URI = $"/api/v1/simplegrid/grid/get_json/{importFrom}?" +
                            $"object_type={args.ObjectType}" +
                            $"&object_id={args.ObjectID}" +
                            $"&grid_id={args.GridID}" +
                            "&add_header=1" +
                            "&posStart=0" +
                            "&count=99999";

                var getDataResponse = await client.GetAsync(URI);
                await getDataResponse.EnsureSuccessStatusCodeAsync();

                var datarec = await getDataResponse.Content.ReadAsStringAsync();

                var receivedData = await getDataResponse.Content.DeserializeAsync<PhenomeDataResponse>();
                
                var totalRecords = receivedData.Properties.Max(x => x.Total_count);
                if (totalRecords <= 0)
                {
                    result.Errors.Add("No data to process.");
                    return result;
                }
                var getTraitID = new Func<string, int?>(o =>
                {
                    var traitid = 0;
                    if (int.TryParse(o, out traitid))
                    {
                        if (traitid > 0)
                            return traitid;
                    }
                    return null;
                });

                var columns1 = columnResponse.Columns.Select(x => new
                {
                    ID = x.id,
                    ColumnName = getTraitID(x.variable_id) == null ? x.desc : getTraitID(x.variable_id).ToString(),
                    DataType = string.IsNullOrWhiteSpace(x.data_type) || x.data_type == "C" ? "NVARCHAR(255)" : x.data_type,
                    ColLabel = x.desc,
                    TraitID = getTraitID(x.variable_id)
                });

                
                var columns2 = receivedData.Columns.Select((x, i) => new
                {
                    x.Name,
                    Index = i

                }).GroupBy(g => g.Name).Select(x => new
                {
                    ID = x.Key,
                    x.FirstOrDefault().Index
                });

                //lot columns doesnot return property variable like it did for data inside field so we need to join with name which must be unique.
                var columns = (from t1 in columns1
                               //join t2 in columns2 on t1.ID equals t2.ID
                               join t2 in columns2 on t1.ColLabel.ToText()?.ToLower() equals t2.ID.ToText()?.ToLower()
                               select new
                               {
                                   t2.ID,
                                   t2.Index,
                                   ColName = t1.ColumnName,
                                   t1.DataType,
                                   t1.ColLabel,
                                   t1.TraitID
                               }).ToList();

                if (columns.GroupBy(x => x.ColLabel.Trim(), StringComparer.OrdinalIgnoreCase).Any(g => g.Count() > 1))
                {
                    result.Errors.Add("Duplicate column found on Phenome");
                    return result;
                }
                
                
                for (int i = 0; i < columns.Count; i++)
                {
                    var col = columns[i];
                    var dr = dtColumnsTVP.NewRow();
                    
                    dr["ColumnNr"] = i;
                    dr["TraitID"] = col.TraitID;
                    dr["ColumnLabel"] = col.ColLabel;
                    dr["DataType"] = col.DataType;
                    dtColumnsTVP.Rows.Add(dr);
                }

                var getColIndex = new Func<string, int>(name =>
                {
                    var fldName = columns.FirstOrDefault(o => o.ColLabel.EqualsIgnoreCase(name));
                    if (fldName != null)
                        return fldName.Index;
                    return -1;
                });

                for (int i = 0; i < receivedData.Rows.Count; i++)
                {
                    var dr = receivedData.Rows[i];

                    var drRow = dtRowTVP.NewRow();
                    drRow["RowNr"] = i;
                    drRow["MaterialKey"] = dr.Properties[0].ID;

                   
                    for (int j = 0; j < columns.Count; j++)
                    {
                        var col = columns[j];
                        var drCell = dtCellTVP.NewRow();
                        var cellval = dr.Cells[col.Index].Value;
                        
                        drCell["RowID"] = i;
                        drCell["ColumnID"] = j;
                        drCell["Value"] = cellval;
                        dtCellTVP.Rows.Add(drCell);
                    }                    
                    dtRowTVP.Rows.Add(drRow);
                }
                //check for duplicate material key
                var data = dtRowTVP.AsEnumerable().Select(x => x.Field<string>("MaterialKey"))
                    .GroupBy(g => g)
                    .Select(x => new
                    {
                        MaterialKey = x.Key,
                        Count = x.Count()
                    });

                if (data.Any(x => x.MaterialKey.ToText() == string.Empty))
                {
                    result.Errors.Add("Material Key cannot be null or empty");
                }
                var keys = data.Where(x => x.Count > 1).ToList();
                if (keys.Any())
                {
                    var keylist = keys.Select(x => x.MaterialKey).ToList();
                    var key = keylist.Truncate();
                    result.Errors.Add($"Duplicate Material key {key}");
                }
                if (result.Errors.Any())
                {
                    return result;
                }
                result.CropCode = cropCode;
                result.BrStationCode = breedingStation;
                result.SyncCode = syncCode;
                result.CountryCode = countryCode;
                result.TVPColumns = dtColumnsTVP;
                result.TVPRows = dtRowTVP;
                result.TVPCells = dtCellTVP;

                //TestName and FilePath is same for Phenome
                args.FilePath = args.TestName;
                //import data into database
                await ImportDataAsync(result.CropCode, result.BrStationCode, result.SyncCode, result.CountryCode,
                    args, result.TVPColumns, result.TVPRows, result.TVPCells);

                //get imported data
                var ds = await GetDataAsync(new SeedHealthGetDataRequestArgs
                {
                    TestID = args.TestID,
                    PageNumber = 1,
                    PageSize = 200
                });

                result.Total = ds.Total;
                result.TotalCount = ds.TotalCount;
                result.DataResult = ds.DataResult;                
                return result;
            }
        }

        public async Task AssignMarkersAsync(LFDiskAssignMarkersRequestArgs requestArgs)
        {
            var columnNames = string.Join(",", requestArgs.Filter.Select(x => x.Name));
            var determinations = string.Join(",", requestArgs.Determinations);
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_SH_ASSIGNMARKERS, CommandType.StoredProcedure, args =>
            {
                args.Add("@TestID", requestArgs.TestID);
                args.Add("@Determinations", determinations);
                args.Add("@ColNames", columnNames);
                args.Add("@Filters", requestArgs.FiltersAsSQL());
            });
        }

        public async Task ManageInfoAsync(LeafDiskManageMarkersRequestArgs requestArgs)
        {
            if (requestArgs.Action.EqualsIgnoreCase("add"))
            {
                var determinations = string.Join(",", requestArgs.Determinations);
                var samples = string.Join(",", requestArgs.SampleIDs);
                await DbContext.ExecuteNonQueryAsync(DataConstants.PR_SH_ASSIGNMARKERS, CommandType.StoredProcedure, args =>
                {
                    args.Add("@TestID", requestArgs.TestID);
                    args.Add("@Determinations", determinations);
                    args.Add("@SelectedMaterial", samples);
                    args.Add("@Filters", requestArgs.ToFilterString());
                });
            }
            else if (requestArgs.Action.EqualsIgnoreCase("update"))
            {
                var dataAsJson = requestArgs.ToJson();
                await DbContext.ExecuteNonQueryAsync(DataConstants.PR_SH_MANAGEINFO, CommandType.StoredProcedure, args =>
                {
                    args.Add("@TestID", requestArgs.TestID);
                    args.Add("@DataAsJson", dataAsJson);
                });

            }
            else if (requestArgs.Action.EqualsIgnoreCase("remove"))
            {
                var samples = string.Join(",", requestArgs.SampleIDs);
                await DbContext.ExecuteNonQueryAsync(DataConstants.PR_SH_DELETE_SAMPLETEST, CommandType.StoredProcedure, args =>
                {
                    args.Add("@TestID", requestArgs.TestID);
                    args.Add("@SelectedMaterial", samples);
                });
            }

        }

        public async Task<ExcelDataResult> getDataWithDeterminationsAsync(MaterialsWithMarkerRequestArgs args)
        {
            var result = new ExcelDataResult();
            DbContext.CommandTimeout = 2 * 60; //time out is set to 2 minutes
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_SH_GET_DATA_WITH_MARKER, CommandType.StoredProcedure, args1 =>
            {
                args1.Add("@TestID", args.TestID);
                args1.Add("@Page", args.PageNumber);
                args1.Add("@PageSize", args.PageSize);
                args1.Add("@Filter", args.ToFilterString());
            });
            if (data.Tables.Count == 2)
            {
                var table0 = data.Tables[0];
                if (table0.Columns.Contains("TotalRows"))
                {
                    if (table0.Rows.Count > 0)
                    {
                        result.Total = table0.Rows[0]["TotalRows"].ToInt32();
                    }
                    table0.Columns.Remove("TotalRows");
                }
                if (table0.Columns.Contains("Total"))
                {
                    if (table0.Rows.Count > 0)
                    {
                        result.TotalCount = table0.Rows[0]["Total"].ToInt32();
                    }
                    table0.Columns.Remove("Total");
                }
                //result.DataResult = new ExcelData();
                var dataResult = new ExcelData()
                {
                    Data = table0,
                    Columns = data.Tables[1]
                };
                result.DataResult = dataResult;
            }
            return result;
        }

        public async Task<ExcelDataResult> GetSampleMaterialAsync(LeafDiskGetDataRequestArgs requestargs)
        {
            var result = new ExcelDataResult();
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_SH_GET_SAMPLEMATERIAL,
                CommandType.StoredProcedure, args =>
                {
                    args.Add("@TestID", requestargs.TestID);
                    args.Add("@Page", requestargs.PageNumber);
                    args.Add("@PageSize", requestargs.PageSize);
                    args.Add("@FilterQuery", requestargs.ToFilterString());
                });

            if (data.Tables.Count == 2)
            {
                result.Success = true;
                var table0 = data.Tables[0];
                if (table0.Columns.Contains("TotalRows"))
                {
                    if (table0.Rows.Count > 0)
                    {
                        result.Total = table0.Rows[0]["TotalRows"].ToInt32();
                    }
                    table0.Columns.Remove("TotalRows");
                }
                if (table0.Columns.Contains("Total"))
                {
                    if (table0.Rows.Count > 0)
                    {
                        result.TotalCount = table0.Rows[0]["Total"].ToInt32();
                    }
                    table0.Columns.Remove("Total");
                }
                result.DataResult = new ExcelData
                {
                    Columns = data.Tables[1],
                    Data = table0
                };
            }
            else
            {
                result.Success = false;
                result.Errors.Add("Problem while fetching data.");
            }
            return result;
            //dataset.Tables[0].TableName = "Data";
            //dataset.Tables[1].TableName = "Columns";
            //return dataset;
        }

        public async Task<bool> SaveSampleAsync(SaveSampleRequestArgs requestArgs)
        {
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_SH_SAVESAMPLETEST, CommandType.StoredProcedure, args =>
            {
                args.Add("@TestID", requestArgs.TestID);
                args.Add("@SampleName", requestArgs.SampleName);
                args.Add("@NrOfSamples", requestArgs.NrOfSamples ?? 1);
                args.Add("@SampleID", requestArgs.SampleID);
            });

            return true;
        }

        public async Task<bool> SaveSampleMaterialAsync(SaveSampleLotRequestArgs requestArgs)
        {
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_SH_SAVE_SAMPLEMATERIAL, CommandType.StoredProcedure, args =>
            {
                args.Add("@TestID", requestArgs.TestID);
                args.Add("@Json", requestArgs.ToMaterialJson());
                args.Add("@Action", requestArgs.Action);
            });

            return true;
        }
        public async Task<IEnumerable<GetSampleResult>> GetSampleAsync(int testID)
        {
            var data = await DbContext.ExecuteReaderAsync(DataConstants.PR_LFDISK_GET_SAMPLE, CommandType.StoredProcedure, args =>
            {
                args.Add("@TestID", testID);
            }, reader => new GetSampleResult
            {
                SampleID = reader.Get<int>(0),
                SampleName = reader.Get<string>(1),
            });
            return data;
        }

        private void PrepareTVPS(DataTable dtCellTVP, DataTable dtRowTVP, DataTable dtColumnsTVP)
        {
            dtCellTVP.Columns.Add("RowID", typeof(int));
            dtCellTVP.Columns.Add("ColumnID", typeof(int));
            dtCellTVP.Columns.Add("Value");

            dtRowTVP.Columns.Add("RowNr");
            dtRowTVP.Columns.Add("MaterialKey");
            dtRowTVP.Columns.Add("GID");
            dtRowTVP.Columns.Add("Name");

            dtColumnsTVP.Columns.Add("ColumnNr", typeof(int));
            dtColumnsTVP.Columns.Add("TraitID");
            dtColumnsTVP.Columns.Add("ColumnLabel");
            dtColumnsTVP.Columns.Add("DataType");
        }

        private async Task<Dictionary<string, string>> GetFolderVariablesDetail(RestClient client, string uRI)
        {
            var rgDetail = await client.GetAsync(uRI);
            await rgDetail.EnsureSuccessStatusCodeAsync();
            var researchGroup = await rgDetail.Content.DeserializeAsync<PhenomeFolderInfo>();
            if (researchGroup != null)
            {
                if (researchGroup.Status != "1")
                {
                    throw new UnAuthorizedException(researchGroup.Message);
                }
                var values = (from t1 in researchGroup.Info.RG_Variables
                              join t2 in researchGroup.Info.BO_Variables on t1.VID equals t2.VID
                              select new
                              {
                                  t1.Name,
                                  t2.Value
                              }).ToList();
                return values.ToDictionary(k => k.Name, v => v.Value, StringComparer.OrdinalIgnoreCase);
            }
            return new Dictionary<string, string>();
        }

        private async Task ImportDataAsync(string cropCode, string brStationCode, string syncCode, string countryCode,
            SeedHealthRequestArgs requestArgs, DataTable tVPColumns, DataTable tVPRows,
            DataTable tVPCells)
        {
            var p1 = DbContext.CreateInOutParameter("@TestID", requestArgs.TestID, DbType.Int32, int.MaxValue);
            DbContext.CommandTimeout = 5 * 60; //5 minutes
            var materialType = "LOT";            
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_SH_IMPORT_MATERIALS,
                CommandType.StoredProcedure, args =>
                {
                    args.Add("@TestID", p1);
                    //args.Add("@TestProtocolID", requestArgs.TestProtocolID);
                    args.Add("@CropCode", cropCode);
                    args.Add("@BrStationCode", brStationCode);
                    args.Add("@SyncCode", syncCode);
                    args.Add("@CountryCode", countryCode);
                    args.Add("@UserID", _userContext.GetContext().FullName);
                    args.Add("@TestName", requestArgs.TestName);
                    args.Add("@ObjectID", requestArgs.ObjectID);
                    args.Add("@ImportLevel", materialType);
                    args.Add("@TVPColumns", tVPColumns);
                    args.Add("@TVPRow", tVPRows);
                    args.Add("@TVPCell", tVPCells);
                    args.Add("@FileID", requestArgs.FileID);
                    args.Add("@PlannedDate", requestArgs.PlannedDate);
                    args.Add("@MaterialTypeID", requestArgs.MaterialTypeID);
                    args.Add("@SiteID", requestArgs.SiteID);
                    args.Add("@SampleType", requestArgs.SampleType);
                });
            requestArgs.TestID = p1.Value.ToInt32();
        }

        public async Task<ExcelDataResult> GetSHOverviewAsync(LeafDiskOverviewRequestArgs requestArgs)
        {
            var result = new ExcelDataResult();
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_SH_GETOVERVIEW, CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@Crops", requestArgs.Crops);
                    args.Add("@PageNumber", requestArgs.PageNumber);
                    args.Add("@pageSize", requestArgs.PageSize);
                    args.Add("@Filter", requestArgs.ToFilterString());
                    args.Add("@ExportToExcel", requestArgs.ExportToExcel);
                    args.Add("@Active", requestArgs.Active);
                });
            if(data.Tables.Count != 2)
            {
                result.Success = false;
                result.Errors.Add("Error while getting data from database");
            }
            else
            {
                result.Success = true;
                result.DataResult = new ExcelData
                {
                    Data = data.Tables[0],
                    Columns = data.Tables[1],
                };
                if(result.DataResult.Data.Rows.Count > 0)
                {
                    result.TotalCount = result.DataResult.Data.Rows[0]["TotalRows"].ToInt32();
                    result.Total = result.TotalCount;
                }
                
            }
            
            return result;
        }

        public async Task<DataTable> SHOverviewToExcelAsync(int testID)
        {
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_SH_GETRESULT_TO_EXCEL, CommandType.StoredProcedure, args =>
            {
                args.Add("@TestID", testID);
            });
            return data.Tables[0];
        }

        public async Task<DataTable> ExcelForABSAsync(int testID)
        {
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_SH_TEST_TO_EXCEL_FOR_EXPORT, CommandType.StoredProcedure, args =>
            {
                args.Add("@TestID", testID);
            });
            return data.Tables[0];
        }

        public async Task<SHSendToABSResponse> SendToABSAsync(int testID)
        {
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_SH_TEST_TO_ABS, CommandType.StoredProcedure, args =>
            {
                args.Add("@TestID", testID);
            });
            return new SHSendToABSResponse
            {
                Success = true,
                ErrorMsg = ""
            };
        }

        public async Task<DataTable> ProcessSummaryCalcuationAsync()
        {
            var result = await DbContext.ExecuteDataSetAsync(DataConstants.PR_SH_PROCESS_SUMMARY_CALCULATION,
               CommandType.StoredProcedure);

            return result.Tables[0];
        }

        public async Task<IEnumerable<TestLookup>> GetTests()
        {
            return await DbContext.ExecuteReaderAsync(DataConstants.PR_SH_GET_TEST_TO_SEND_SCORE, CommandType.StoredProcedure, reader => new TestLookup
            {
                TestID = reader.Get<int>(0),
                CropCode = reader.Get<string>(1),
                BreedingStationCode = reader.Get<string>(2),
                PlatePlanName = reader.Get<string>(3),
                TestName = reader.Get<string>(4),
                SiteName = reader.Get<string>(5),
                LDResultSummary = reader.Get<string>(6),
                SampleType = reader.Get<string>(7)
            });
        }
        public async Task<IEnumerable<SHResult>> SHResult(int testID)
        {
            return await DbContext.ExecuteReaderAsync(DataConstants.PR_SH_GET_SCORE, CommandType.StoredProcedure, args =>
            {
                args.Add("@TestID", testID);
            },
            reader => new SHResult
            {
                TestID = reader.Get<int>(0),
                MaterialKey = reader.Get<string>(1),
                FieldID = reader.Get<string>(2),
                ColumnLabel = reader.Get<string>(3),
                DeterminationName = reader.Get<string>(4),
                Score = reader.Get<string>(5),
                MappingColumn = reader.Get<string>(6),
                SHTestResultID = reader.Get<int>(7),
                LotSampleType = reader.Get<string>(8),
                StatusCode = reader.Get<int>(9)
            });
        }

        public async Task<UpdateInventoryLotResult> UpdateInventoryLotAsync(RestClient client, string objectType, string objectID, List<SHResult> resultData)
        {
            var result = new UpdateInventoryLotResult();
            var errorIds = new List<int>();
            var missingColumns = new List<string>();

            LogInfo($"Updating inventory lots to phenome started for testid: {resultData.FirstOrDefault().TestID}");

            //get columns of inventories from phenome
            var inventoryColumns = await GetInventoryLotColumnsAsync(client, objectType, objectID);

            inventoryColumns = inventoryColumns.Where(x => x.id.StartsWith("LOT~")).ToList();

            var lotSampleType = resultData.FirstOrDefault().LotSampleType;

            //if lot sample type is fruit then we can use bulk update (this will be more efficient because all lots are included in one sample and have same result).
            if (lotSampleType.EqualsIgnoreCase("fruit"))
            {
                var url = "/api/v2/inventorylots/put/EditMultipleLots";

                foreach (var _columns in resultData.GroupBy(x => x.ColumnLabel))
                {
                    var colNum = inventoryColumns.Where(x => x.desc.EqualsIgnoreCase(_columns.Key)).Select(x => x.col_num).FirstOrDefault();
                    if (colNum == null)
                    {
                        missingColumns.Add(_columns.Key);
                    }
                }
                //if missing column is found retrun error and send email for missing columns
                if (missingColumns.Any())
                {
                    LogError($"Columns missing in phenome: {string.Join(",", missingColumns)}");
                    result.MissingColumns = missingColumns;
                    return result;
                }

                //this group by is only done from score because score is either positive or negative so it will take more columns and lotID than grouping with column and score
                var groupedData = resultData.GroupBy(x => x.Score);                

                foreach (var _groupedData in groupedData)
                {                    

                    var scoreData = _groupedData.ToList();

                    LogInfo($"URL: ../api/v2/inventorylots/put/EditMultipleLots. Request payload:");
                    var payload = "";
                    var response = await client.PostAsync(url, form =>
                    {
                        var columns = scoreData.GroupBy(x => x.ColumnLabel);

                        foreach (var _columns in columns)
                        {
                            var colNum = inventoryColumns.Where(x => x.desc.EqualsIgnoreCase(_columns.Key)).Select(x => x.col_num).FirstOrDefault();
                            form.Add(colNum, _groupedData.Key);
                            payload = payload + $" {colNum}: {_groupedData.Key}";                            
                            
                        }
                        //for multiple lots if we provide gridtype and objectID in form data it will send error so without providing this field it worked
                        //form.Add("gridType", "InventoryLots");                       
                        //form.Add("objectId", objectID);

                        //payload = payload + " gridType: InventoryLots";
                        //payload = payload + $" objectId: {objectID}";
                        foreach (var data in scoreData.GroupBy(x=>x.MaterialKey))
                        {
                            payload = payload + $" lotIds: {data.Key}";
                            form.Add("lotIds", data.Key);
                        }
                    });
                    LogInfo(payload);
                    await response.EnsureSuccessStatusCodeAsync();
                    var runJobRespContent = await response.Content.ReadAsStringAsync();
                    var resp2 = JsonConvert.DeserializeObject<PhenomeResponse>(runJobRespContent);
                    if (resp2.Status != "1")
                    {
                        errorIds.AddRange(scoreData.Select(o => o.SHTestResultID));
                        //throw new Exception("Updating inventory lots to phenome failed. Error: " + resp2.Message);
                        LogError("Updating inventory lots to phenome failed. Error: " + resp2.Message);
                        result.ErrorMessage = resp2.Message;
                    }
                }
            }
            //use edit single method because this can have different result so updating one lot at a time is efficient.
            else
            {
                var url = "/api/v2/inventorylots/put/EditSingleLot";

                foreach (var _columns in resultData.GroupBy(x => x.ColumnLabel))
                {
                    var colNum = inventoryColumns.Where(x => x.desc.EqualsIgnoreCase(_columns.Key)).Select(x => x.col_num).FirstOrDefault();
                    if (colNum == null)
                    {
                        missingColumns.Add(_columns.Key);
                    }
                }
                //if missing column is found retrun error and send email for missing columns
                if (missingColumns.Any())
                {
                    LogError($"Columns missing in phenome: {string.Join(",", missingColumns)}");
                    result.MissingColumns = missingColumns;
                    return result;
                }
                var groupedData = resultData.GroupBy(x => x.MaterialKey);
                foreach (var _groupedData in groupedData)
                {

                    var scoreData = _groupedData.ToList();

                    LogInfo($"URL: ../api/v2/inventorylots/put/EditSingleLot. Request payload:");
                    var payload = "";
                    var response = await client.PostAsync(url, form =>
                    {
                        form.Add("lotId", _groupedData.Key);
                        payload = $"lotId: {_groupedData.Key}";

                        foreach (var data in scoreData)
                        {
                            var colNum = inventoryColumns.Where(x => x.desc.EqualsIgnoreCase(data.ColumnLabel)).Select(x => x.col_num).FirstOrDefault();

                            if (!string.IsNullOrWhiteSpace(colNum))
                            {
                                payload = payload + $" {colNum}: {data.Score}";
                                form.Add(colNum, data.Score);
                            }
                        }
                        //if (missingColumns.Any())
                        //{
                        //    result.MissingColumns = missingColumns;
                        //    return result;
                        //}
                    });
                    LogInfo(payload);
                    await response.EnsureSuccessStatusCodeAsync();
                    var runJobRespContent = await response.Content.ReadAsStringAsync();
                    var resp2 = JsonConvert.DeserializeObject<PhenomeResponse>(runJobRespContent);
                    if (resp2.Status != "1")
                    {
                        errorIds.AddRange(scoreData.Select(o => o.SHTestResultID));
                        //throw new Exception("Updating inventory lots to phenome failed. Error: " + resp2.Message);
                        LogError("Updating inventory lots to phenome failed. Error: " + resp2.Message);
                        result.ErrorMessage = resp2.Message;
                    }
                }
            }
            if(errorIds.Any())
            {
                LogInfo($"Updating inventory lots to phenome completed for testid: {resultData.FirstOrDefault().TestID} with errors.");
            }
            else
            {
                LogInfo($"Updating inventory lots to phenome completed for testid: {resultData.FirstOrDefault().TestID}");
            }
            
            result.ErrorIDs = errorIds;
            result.MissingColumns = missingColumns;            
            return result;
        }

        public async Task<List<Entities.Results.Column>> GetInventoryLotColumnsAsync(RestClient client, string objectType, string objectID)
        {
            var url = "/api/v1/simplegrid/grid/get_columns_list/InventoryLots";
            var response = await client.PostAsync(url, values =>
            {
                values.Add("object_type", objectType);
                values.Add("object_id", objectID);
                values.Add("base_entity_id", "0");
            });
            await response.EnsureSuccessStatusCodeAsync();
            var resp = await response.Content.DeserializeAsync<InventoryLotColumnsResponse>();
            if (resp.Status != "1")
            {
                throw new Exception("Couldn't fetch inventory columns information from phenome.");
            }
            return resp.All_Columns.Select(o =>
            {
                var value = Regex.Replace(o.id, "LOT~", string.Empty, RegexOptions.IgnoreCase);//columnid for inventory update method                
                o.col_num = value;
                return o;
            }).ToList();
        }
        
        public async Task UpdateTestResultStatusAsync(int testID, string testResultIDs, int statusCode )
        {
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_SH_UPDATE_TEST_RESULT_STATUS, CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@TestID", testID);
                    args.Add("@TestResultIDs", testResultIDs);
                    args.Add("@StatusCode", statusCode);
                });
        }

        private void LogInfo(string msg)
        {
            Console.WriteLine(msg);
            _logger.Info(msg);
        }

        private void LogError(string msg)
        {
            Console.WriteLine(msg);
            _logger.Error(msg);
        }


        public async Task<IEnumerable<SHDataToPrint>> GetDataToPrintAsync(SHPrintStickerRequestArgs requestargs)
        {
             return await DbContext.ExecuteReaderAsync(DataConstants.PR_SH_GET_DATA_TO_PRINT, CommandType.StoredProcedure, args =>
                 {
                     args.Add("@TestID", requestargs.TestID);
                 }, reader => new SHDataToPrint
                 {
                     TestID = reader.Get<int>(0),
                     TestName = reader.Get<string>(1),
                     DeterminationID = reader.Get<int>(2),
                     DeterminationName = reader.Get<string>(3),
                     SampleID = reader.Get<int>(4),
                     SampleName = reader.Get<string>(5)
                 });
        }

        public async Task<ReceiveSHResultsReceiveResult> ReceiveSHResultsAsync(ReceiveSHResultsRequestArgs requestArgs)
        {
            try
            {
                var data = requestArgs.Samples.SelectMany(x => x.Determinations.SelectMany(y => y.Results.Select(z => new
                {
                    x.SampleTestID,
                    y.DeterminationID,
                    z.Key,
                    z.Value
                }))).ToList();

                var dataAsJson = data.ToJson();
                await DbContext.ExecuteReaderAsync(DataConstants.PR_SH_RECEIVE_RESULTS, CommandType.StoredProcedure, args =>
                {
                    args.Add("@Json", dataAsJson);
                });

                return new ReceiveSHResultsReceiveResult() { Success = "True", ErrorMsg = "" };
            }
            catch (Exception ex)
            {
                return new ReceiveSHResultsReceiveResult() { Success = "False", ErrorMsg = ex.Message };
            }
        }

    }
}