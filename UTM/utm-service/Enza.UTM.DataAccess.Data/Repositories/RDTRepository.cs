using System;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using Enza.UTM.DataAccess.Abstract;
using Enza.UTM.DataAccess.Data.Interfaces;
using Enza.UTM.DataAccess.Interfaces;
using Enza.UTM.Entities;
using Enza.UTM.Entities.Args;
using Enza.UTM.Entities.Results;
using System.Configuration;
using Enza.UTM.Common.Extensions;
using Enza.UTM.Services.Proxies;
using System.Net;
using System.Net.Http;
using Enza.UTM.Services.Abstract;
using Enza.UTM.Common.Exceptions;
using System.Linq;
using Enza.UTM.Common;
using log4net;

namespace Enza.UTM.DataAccess.Data.Repositories
{
    public class RDTRepository : Repository<object>, IRDTRepository
    {
        private readonly IUserContext userContext;
        readonly IExcelDataRepository excelDataRepo;
        private readonly string BASE_SVC_URL = ConfigurationManager.AppSettings["BasePhenomeServiceUrl"];
        private readonly ILog _logger =
           LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);
        public RDTRepository(IDatabase dbContext, IUserContext userContext, IExcelDataRepository excelDataRepository) : base(dbContext)
        {
            this.userContext = userContext;
            this.excelDataRepo = excelDataRepository;
        }

        public async Task<PhenoneImportDataResult> ImportDataFromPhenomeAsync(HttpRequestMessage request, PhenomeImportRequestArgs args)
        {
            var result = new PhenoneImportDataResult();

            string cropCode = "";
            string breedingStation = "";
            string syncCode = "";
            string countryCode = "";

            #region prepare datatables for stored procedure call
            var dtCellTVP = new DataTable();
            var dtRowTVP = new DataTable();
            var dtListTVP = new DataTable();
            var dtColumnsTVP = new DataTable();
            var TVPS2SCapacity = new DataTable();

            PrepareTVPS(dtCellTVP, dtRowTVP, dtListTVP, dtColumnsTVP, TVPS2SCapacity);

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


                //call service to get Breeding station and SyncCode based on breeding station level call on phenome from folder in tree structure.
                URI = $"/api/v1/folder/info/{ args.FolderID}";
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
                //countrycode
                if (!breedingStationDetail.TryGetValue("Country", out countryCode))
                {
                    result.Errors.Add("Country not found. Please add Country first.");
                    return result;
                }
                if (string.IsNullOrWhiteSpace(countryCode))
                {
                    result.Errors.Add("Country can not be null or empty.");
                    return result;
                }

                #endregion


                if (args.ImportLevel.EqualsIgnoreCase("list"))
                    URI = "/api/v1/simplegrid/grid/create/FieldNursery";
                else
                    URI = "/api/v1/simplegrid/grid/create/FieldPlants";
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
                    throw new UnAuthorizedException(columnResponse.Message);
                }

                if (!columnResponse.Columns.Any())
                {
                    result.Errors.Add("No columns found.");
                    return result;
                }
                if (!args.ForcedImport && columnResponse.Columns.Count > 50)
                {
                    result.Warnings.Add("You are importing more than 50 columns.This can lead to problem. We recommend to reduce the amount of columns in Phenome. Continue?");
                    return result;
                }

                if (args.ImportLevel.EqualsIgnoreCase("list"))
                    URI = "/api/v1/simplegrid/grid/get_json/FieldNursery?" +
                                                      $"object_type={args.ObjectType}&" +
                                                      $"object_id={args.ObjectID}&" +
                                                      $"grid_id={args.GridID}&" +
                                                      "add_header=1&" +
                                                      "posStart=0&" +
                                                      "count=99999";
                else
                    URI = "/api/v1/simplegrid/grid/get_json/FieldPlants?" +
                                                      $"object_type={args.ObjectType}&" +
                                                      $"object_id={args.ObjectID}&" +
                                                      $"grid_id={args.GridID}&" +
                                                      "add_header=1&" +
                                                      "posStart=0&" +
                                                      "count=99999";

                response = await client.GetAsync(URI);

                await response.EnsureSuccessStatusCodeAsync();

                var dataResponse = await response.Content.DeserializeAsync<PhenomeDataResponse>();
                var totalRecords = dataResponse.Properties.Max(x => x.Total_count);
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
                    ColName = getTraitID(x.variable_id) == null ? x.desc : getTraitID(x.variable_id).ToString(),
                    DataType = string.IsNullOrWhiteSpace(x.data_type) || x.data_type == "C" ? "NVARCHAR(255)" : x.data_type,
                    ColLabel = x.desc,
                    TraitID = getTraitID(x.variable_id)
                }).GroupBy(g => g.ColName.Trim(), StringComparer.OrdinalIgnoreCase)
                .Select(y =>
                {
                    var elem = y.FirstOrDefault();
                    var item = new
                    {
                        ColumnName = elem.ColName,
                        elem.ID,
                        elem.DataType,
                        elem.ColLabel,
                        elem.TraitID
                    };
                    return item;
                });

                var columns2 = dataResponse.Columns.Select((x, i) => new
                {
                    ID = x.Properties[0].ID,
                    Index = i

                }).GroupBy(g => g.ID).Select(x => new
                {
                    ID = x.Key,
                    Index = x.FirstOrDefault().Index
                });


                var columns = (from t1 in columns1
                               join t2 in columns2 on t1.ID equals t2.ID
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
                    result.Errors.Add("Duplicate column found on " + args.Source);
                    return result;
                }

                var foundGIDColumn = false;
                var foundLotNrColumn = false;
                var foundEntryCode = false;
                var foundPlantName = false;
                var foundMasterNr = false;
                var foundvariety = false;
                for (int i = 0; i < columns.Count; i++)
                {
                    var col = columns[i];
                    var dr = dtColumnsTVP.NewRow();
                    if (col.ColLabel.EqualsIgnoreCase("GID"))
                    {
                        foundGIDColumn = true;
                    }
                    else if (col.ColLabel.EqualsIgnoreCase("LotNr"))
                    {
                        foundLotNrColumn = true;
                    }
                    else if (col.ColLabel.EqualsIgnoreCase("MasterNr"))
                    {
                        foundMasterNr = true;
                    }
                    else if (col.ColLabel.EqualsIgnoreCase("Variety"))
                    {
                        foundvariety = true;
                    }
                    else if (col.ColLabel.EqualsIgnoreCase("Entry Code"))
                    {
                        foundEntryCode = true;
                    }
                    else if (col.ColLabel.EqualsIgnoreCase("plant name"))
                    {
                        foundPlantName = true;
                    }
                    dr["ColumnNr"] = i;
                    dr["TraitID"] = col.TraitID;
                    dr["ColumnLabel"] = col.ColLabel;
                    dr["DataType"] = col.DataType;
                    dtColumnsTVP.Rows.Add(dr);
                }

                var missedMendatoryColumns = new List<string>();

                if (!foundGIDColumn)
                {
                    missedMendatoryColumns.Add("GID");
                }
                if (!foundEntryCode)
                {
                    missedMendatoryColumns.Add("Entry Code");
                }
                if (!foundMasterNr)
                {
                    missedMendatoryColumns.Add("MasterNr");
                }
                if(!foundvariety)
                {
                    missedMendatoryColumns.Add("Variety");
                }
                if (args.ImportLevel.EqualsIgnoreCase("list") && !foundLotNrColumn)
                {
                    missedMendatoryColumns.Add("LotNr");
                }
                if (!args.ImportLevel.EqualsIgnoreCase("list") && !foundPlantName)
                {
                    missedMendatoryColumns.Add("Plant name");
                }


                if (missedMendatoryColumns.Any())
                {
                    result.Errors.Add("Please add following columns during import: " + string.Join(",", missedMendatoryColumns));
                    return result;
                }
                var getColIndex = new Func<string, int>(name =>
                {
                    var fldName = columns.FirstOrDefault(o => o.ColLabel.EqualsIgnoreCase(name));
                    if (fldName != null)
                        return fldName.Index;
                    return -1;
                });

                for (int i = 0; i < dataResponse.Rows.Count; i++)
                {
                    var dr = dataResponse.Rows[i];
                    var drRow = dtRowTVP.NewRow();
                    drRow["RowNr"] = i;
                    drRow["MaterialKey"] = dr.Properties[0].ID;

                    //prepare rows for list tvp as well
                    var drList = dtListTVP.NewRow();
                    drList["RowID"] = dr.Properties[0].ID;
                    drList["GID"] = dr.Cells[getColIndex("GID")].Value;
                    drList["EntryCode"] = getColIndex("EntryCode") > 0 ? dr.Cells[getColIndex("EntryCode")].Value : "";


                    //foreach (var col in columns)
                    for (int j = 0; j < columns.Count; j++)
                    {
                        var col = columns[j];
                        var drCell = dtCellTVP.NewRow();
                        var cellval = dr.Cells[col.Index].Value;

                        if (col.ColLabel.EqualsIgnoreCase("GID"))
                        {
                            if (string.IsNullOrWhiteSpace(cellval))
                            {
                                result.Errors.Add("GID value can not be empty.");
                                return result;
                            }
                            else
                            {
                                drRow["GID"] = cellval;
                            }
                        }
                        drCell["RowID"] = i;
                        drCell["ColumnID"] = j;
                        drCell["Value"] = cellval;
                        dtCellTVP.Rows.Add(drCell);
                    }
                    dtListTVP.Rows.Add(drList);
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
                result.TVPList = dtListTVP;

                //TestName and FilePath is same for Phenome
                args.FilePath = args.TestName;
                //import data into database
                await excelDataRepo.ImportDataAsync(result.CropCode, result.BrStationCode, result.SyncCode, result.CountryCode,
                    args, result.TVPColumns, result.TVPRows, result.TVPCells, result.TVPList);

                return result;
            }
        }

        public async Task<MaterialsWithMarkerResult> GetMaterialWithtTestsAsync(MaterialsWithMarkerRequestArgs args)
        {
            var result = new MaterialsWithMarkerResult();
            DbContext.CommandTimeout = 2 * 60; //time out is set to 2 minutes
            var crops = ConfigurationManager.AppSettings["MaxSelectCrops"];
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_RDT_GET_MATERIAL_WITH_TESTS, CommandType.StoredProcedure, args1 =>
            {
                args1.Add("@TestID", args.TestID);
                args1.Add("@Page", args.PageNumber);
                args1.Add("@PageSize", args.PageSize);
                args1.Add("@Filter", args.ToFilterString());
                args1.Add("@MaxSelectCrops", crops);
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
                result.Data = new
                {
                    Columns = data.Tables[1],
                    Data = table0
                };
            }
            return result;
        }

        public async Task<Test> AssignTestAsync(AssignDeterminationForRDTRequestArgs request)
        {
            var data = await DbContext.ExecuteReaderAsync(DataConstants.PR_SAVE_TEST_MATERIAL_DETERMINATION_ForRDT, CommandType.StoredProcedure, args =>
            {
                args.Add("@TestTypeID", request.TestTypeID);
                args.Add("@TestID", request.TestID);
                args.Add("@Columns", request.ToColumnsString());
                args.Add("@Filter", request.ToFilterString());
                args.Add("@TVPTestWithExpDate", request.ToTVPTestMaterialDetermation());
                args.Add("@Determinations", request.ToTVPDeterminations());
                args.Add("@TVPProperty", request.ToTVPPropertyValue());
            },
            reader => new Test
            {
                TestID = reader.Get<int>(0),
                StatusCode = reader.Get<int>(1)

            });
            return data.FirstOrDefault();

        }

        public async Task<RequestSampleTestResult> RequestSampleTestAsync(TestRequestArgs request)
        {
            ////test code to trace the time of insert of data
            //var query = "INSERT INTO RDTTempTable(DataJson, Type, ReceivedTime) VALUES(@DataJson,@Type, @ReceivedTime)";
            //await DbContext.ExecuteNonQueryAsync(query, CommandType.Text, args =>
            //{
            //    args.Add("@DataJson", request.TestID);
            //    args.Add("@Type", "RequestSampleTest");
            //    args.Add("@ReceivedTime", DateTime.Now);

            //});
            //Prepare data
            var data = await DbContext.ExecuteReaderAsync(DataConstants.PR_RDT_GetMaterialForUpload, CommandType.StoredProcedure, args =>
            {
                args.Add("@TestID", request.TestID);
            },
            reader => new RequestSampleTest
            {
                Crop = reader.Get<string>(0),
                BrStation = reader.Get<string>(1),
                Country = reader.Get<string>(2),
                Level = reader.Get<string>(3),
                TestType = reader.Get<string>(4),
                RequestID = reader.Get<int>(5),
                RequestingSystem = reader.Get<string>(6),
                DeterminationID = reader.Get<int>(7), //Lims determination id
                MaterialID = reader.Get<int>(8),
                Name = reader.Get<string>(9),
                ExpectedResultDate = reader.Get<DateTime>(10).ToString("yyyy-MM-dd"),
                MaterialStatus = reader.Get<string>(11),
                Site = reader.Get<string>(12),
                PlantID = reader.Get<string>(13),
                PlantName = reader.Get<string>(14),
                GID = reader.Get<int>(15),
                Enumber = reader.Get<string>(16),
                MasterNr = reader.Get<string>(17),
                LotNumber = reader.Get<string>(18)
            });

            var responseOfLims = await ExecuteRequestSampleTest(data.ToList());

            //query = "INSERT INTO RDTTempTable(DataJson, Type, ReceivedTime) VALUES(@DataJson,@Type, @ReceivedTime)";
            //await DbContext.ExecuteNonQueryAsync(query, CommandType.Text, args =>
            //{
            //    args.Add("@DataJson", request.TestID);
            //    args.Add("@Type", "RequestSampleTestCompleted");
            //    args.Add("@ReceivedTime", DateTime.Now);

            //});
            return responseOfLims;
        }

        private async Task<RequestSampleTestResult> ExecuteRequestSampleTest(List<RequestSampleTest> request)
        {
            await Task.Delay(1);
            var limsServiceUser = ConfigurationManager.AppSettings["LimsServiceUser"];


            var data = request.GroupBy(g => new { g.RequestID })
                .Select(o => new RequestSampleTestRequest
                {
                    Crop = o.FirstOrDefault().Crop,
                    BrStation = o.FirstOrDefault().BrStation,
                    Country = o.FirstOrDefault().Country,
                    Level = o.FirstOrDefault().Level,
                    TestType = o.FirstOrDefault().TestType,
                    RequestID = o.Key.RequestID,
                    Site = o.FirstOrDefault().Site,
                    RequestingUser = limsServiceUser,
                    RequestingName = limsServiceUser,
                    RequestingSystem = o.FirstOrDefault().RequestingSystem,
                    Determinations = o.GroupBy(y => y.DeterminationID).Select(p => new Entities.Results.DeterminationDT
                    {
                        DeterminationID = p.Key,
                        Materials = p.Select(q => new Entities.Results.MaterialDT
                        {
                            MaterialID = q.MaterialID,
                            Name = q.Name,
                            ExpectedResultDate = q.ExpectedResultDate,
                            MaterialStatus = q.MaterialStatus
                        }).ToList()
                    }).ToList(),
                    MaterialInfo = o.GroupBy(y => y.MaterialID).Select(p => {
                        var detail = p.FirstOrDefault();
                        var material = new Material
                        {
                            MaterialID = p.Key,
                            //data for list : data for plant
                            Info = string.IsNullOrWhiteSpace(detail.PlantName) ? new List<KeyValuePair<string, string>>
                            {
                                new KeyValuePair<string, string>("GID", detail.GID.ToText()),
                                new KeyValuePair<string, string>("ENumber", detail.Enumber),
                                new KeyValuePair<string, string>("MasterNr", detail.MasterNr),
                                new KeyValuePair<string, string>("LotNumber", detail.LotNumber)
                            } : new List<KeyValuePair<string, string>>
                            {
                                new KeyValuePair<string, string>("PlantID", detail.PlantID),
                                new KeyValuePair<string, string>("PlantName", detail.PlantName),
                                new KeyValuePair<string, string>("GID", detail.GID.ToText()),
                                new KeyValuePair<string, string>("ENumber", detail.Enumber),
                                new KeyValuePair<string, string>("MasterNr", detail.MasterNr),
                                new KeyValuePair<string, string>("LotNumber", detail.LotNumber)
                            }
                        };
                        return material;
                    }).ToList()
                }).FirstOrDefault();
            var client = new LimsServiceRestClient();
            return client.RequestSampleTestAsync(data);
        }

        private void PrepareTVPS(DataTable dtCellTVP, DataTable dtRowTVP, DataTable dtListTVP, DataTable dtColumnsTVP, DataTable TVPS2SCapacity)
        {

            dtCellTVP.Columns.Add("RowID", typeof(int));
            dtCellTVP.Columns.Add("ColumnID", typeof(int));
            dtCellTVP.Columns.Add("Value");

            dtRowTVP.Columns.Add("RowNr");
            dtRowTVP.Columns.Add("MaterialKey");
            dtRowTVP.Columns.Add("GID");
            dtRowTVP.Columns.Add("EntryCode");

            dtListTVP.Columns.Add("RowID");
            dtListTVP.Columns.Add("GID");
            dtListTVP.Columns.Add("EntryCode");

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

        public async Task<List<MaterialState>> GetmaterialStatusAsync()
        {
            var list = new List<MaterialState>()
            {
                new MaterialState{Code ="DH",Name = "DH"},
                new MaterialState{Code ="Breeding Line",Name = "Breeding Line"},
                new MaterialState{Code ="Parent",Name = "Parent"},
                new MaterialState{Code ="Variety",Name = "Variety"},
            };
            return await Task.FromResult(list);
        }

        public async Task<PlatePlanResult> GetRDTtestsOverviewAsync(PlatePlanRequestArgs requestArgs)
        {
            var ds = await DbContext.ExecuteDataSetAsync(DataConstants.PR_RDT_GET_TEST_OVERVIEW,
                CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@Active", requestArgs.Active);
                    args.Add("@Crops", requestArgs.Crops);
                    args.Add("@Filter", requestArgs.ToFilterString());
                    args.Add("@Sort", "");
                    args.Add("@Page", requestArgs.PageNumber);
                    args.Add("@PageSize", requestArgs.PageSize);
                });

            var dt = ds.Tables[0];
            var result = new PlatePlanResult();
            if (dt.Rows.Count > 0)
            {
                result.Total = dt.Rows[0]["TotalRows"].ToInt32();
                dt.Columns.Remove("TotalRows");
            }
            result.Data = dt;
            return result;
        }
        //public async Task<RequestSampleTestCallbackResult> RequestSampleTestCallbackAsync1(RequestSampleTestCallBackRequestArgs request, string JsonString)
        //{
        //    var query = "INSERT INTO RDTTempTable(DataJson, Type, ReceivedTime) VALUES(@DataJson,@Type, @ReceivedTime)";
        //    await DbContext.ExecuteNonQueryAsync(query, CommandType.Text, args =>
        //    {
        //        args.Add("@DataJson", JsonString);
        //        args.Add("@Type", "Callback");
        //        args.Add("@ReceivedTime", DateTime.Now);

        //    });
        //    //await DbContext.ExecuteReaderAsync(DataConstants.PR_RDT_REQUEST_SAMPLE_TEST_CALLBACK, CommandType.StoredProcedure, args =>
        //    //{
        //    //    args.Add("@TestID", request.RequestID);
        //    //    args.Add("@FolderName", request.FolderName);
        //    //    args.Add("@TVPDeterminationMaterial", request.ToTVPDeterminationMaterial());
        //    //});

        //    return new RequestSampleTestCallbackResult() { Success = "True" };
        //}

        public async Task<RequestSampleTestCallbackResult> RequestSampleTestCallbackAsync(RequestSampleTestCallBackRequestArgs request, string JsonString)
        {
            var req = request.RequestID;
            var folder = request.FolderName;
            var ddd = request.ToTVPDeterminationMaterial();

            await DbContext.ExecuteReaderAsync(DataConstants.PR_RDT_REQUEST_SAMPLE_TEST_CALLBACK, CommandType.StoredProcedure, args =>
            {
                args.Add("@TestID", request.RequestID);
                args.Add("@FolderName", request.FolderName);
                args.Add("@TVPDeterminationMaterial", request.ToTVPDeterminationMaterial());
            });
            return new RequestSampleTestCallbackResult() { Success = "True" };
        }

        public async Task<ReceiveRDTResultsReceiveResult> ReceiveRDTResultsAsync(ReceiveRDTResultsRequestArgs request)
        {
            await DbContext.ExecuteReaderAsync(DataConstants.PR_RDT_RECEIVE_RESULTS, CommandType.StoredProcedure, args =>
            {
                args.Add("@TestID", request.RequestID);
                args.Add("@TestFlowType", request.TestFlowType);
                args.Add("@TVP_RDTScore", request.ToTVPRDTScore());
            });

            return new ReceiveRDTResultsReceiveResult() { Success = "True" };
        }

        public async Task<PrintLabelResult> PrintLabelAsync(PrintLabelForRDTRequestArgs reqArgs)
        {
            var printlabelResult = new List<PrintLabelResult>();
            //var result = await DbContext.ExecuteReaderAsync()
            //key of dictionary should contain following 
            //REFID,Testname, LimsID, MaterNr, GID, NrOfPlants (Flow 1)
            //REFID, TestName, LimsID, E-Number,LotNr, NrOfPlants (flow 2)
            //REFID, PlantName, LimsID, PlantID, 
            var resultdata = await DbContext.ExecuteReaderAsync(DataConstants.PR_RDT_GET_MATERIAL_TO_PRINT, CommandType.StoredProcedure, args =>
            {
                args.Add("@TestID", reqArgs.TestID);
                args.Add("@MaterialStatus", string.Join(",", reqArgs.MaterialStatus));
                args.Add("@TVP_TMD", reqArgs.ToTMDTable());
            }, reader => new RDTPrintData
            {
                LimsID = reader.Get<int>(0),
                MaterialStatus = reader.Get<string>(1),
                NrOfPlants = reader.Get<int>(2),
                DeterminationName = reader.Get<string>(3),
                MaterialKey = reader.Get<string>(4),
                GID = reader.Get<string>(5),
                PlantName = reader.Get<string>(6),
                LotNr = reader.Get<string>(7),
                Variety = reader.Get<string>(8),
                MasterNr = reader.Get<string>(9),
                ImportLevel = reader.Get<string>(10),
                FolderNr = reader.Get<string>(11)

            });
            if (resultdata.Any())
            {
                var listPrintData = new Dictionary<string, RDTPrintResult>();
                //plant materials 
                var plantMaterials = resultdata.Where(x => x.ImportLevel.EqualsIgnoreCase("plt")).ToList();

                //varietymaterials
                var vareityMaterials = resultdata.Where(x => !x.ImportLevel.EqualsIgnoreCase("plt") && x.MaterialStatus.EqualsIgnoreCase("variety")).ToList();

                //parent, breeding line, dh
                var parentOrBreedingLineOrDH = resultdata.Where(x => !x.ImportLevel.EqualsIgnoreCase("plt") && !x.MaterialStatus.EqualsIgnoreCase("variety")).ToList();

                var labelType = "";

                if (plantMaterials.Any())
                {
                    labelType = ConfigurationManager.AppSettings["RDTPlantMaterialLabelType"];
                    if (string.IsNullOrWhiteSpace(labelType.ToText()))
                        throw new Exception("Please specify LabelType in settings with value for RDTPlantMaterialLabelType");

                    var printData = new RDTPrintResult();
                    printData.Labels = new List<Entities.Results.Label>();
                    printData.Copies = 1;
                    printData.LabelType = labelType;
                    printData.User = userContext.GetContext().Name;

                    foreach (var _plantMaterial in plantMaterials)
                    {
                        var dict = new Dictionary<string, string>();
                        dict["QRCODE"] = _plantMaterial.LimsID.ToText();
                        dict["PLANTNAME"] = _plantMaterial.PlantName;
                        dict["PLANTID"] = _plantMaterial.MaterialKey;
                        dict["FOLDERNR"] = _plantMaterial.FolderNr;
                        printData.Labels.Add(new Entities.Results.Label
                        {
                            LabelData = dict,

                        });

                    }
                    listPrintData.Add(labelType, printData);

                }

                if (vareityMaterials.Any())
                {
                    labelType = ConfigurationManager.AppSettings["RDTVarietyMaterialLabelType"];
                    if (string.IsNullOrWhiteSpace(labelType.ToText()))
                        throw new Exception("Please specify LabelType in settings with value for RDTVarietyMaterialLabelType");

                    var printData = new RDTPrintResult();
                    printData.Labels = new List<Entities.Results.Label>();
                    printData.Copies = 1;
                    printData.LabelType = labelType;
                    printData.User = userContext.GetContext().Name;

                    foreach (var _vareityMaterials in vareityMaterials)
                    {
                        var dict = new Dictionary<string, string>();
                        dict["QRCODE"] = _vareityMaterials.LimsID.ToText();
                        dict["TESTNAME"] = _vareityMaterials.DeterminationName;
                        dict["VARIETY"] = _vareityMaterials.Variety;
                        dict["LOTNR"] = _vareityMaterials.LotNr;
                        dict["NROFPLANTS"] = _vareityMaterials.NrOfPlants.ToText();
                        dict["FOLDERNR"] = _vareityMaterials.FolderNr;
                        printData.Labels.Add(new Entities.Results.Label
                        {
                            LabelData = dict
                        });

                    }
                    listPrintData.Add(labelType, printData);

                }
                //print rest of the material if any
                if (parentOrBreedingLineOrDH.Any())
                {
                    labelType = ConfigurationManager.AppSettings["RDTBreedingMaterialLabelType"];
                    if (string.IsNullOrWhiteSpace(labelType.ToText()))
                        throw new Exception("Please specify LabelType in settings with value for RDTBreedingMaterialLabelType");
                    //print plant materials here
                    var printData = new RDTPrintResult();
                    printData.Labels = new List<Entities.Results.Label>();
                    printData.Copies = 1;
                    printData.LabelType = labelType;
                    printData.User = userContext.GetContext().Name;

                    foreach (var _parentOrBreedingLineOrDH in parentOrBreedingLineOrDH)
                    {
                        var dict = new Dictionary<string, string>();
                        dict["QRCODE"] = _parentOrBreedingLineOrDH.LimsID.ToText();
                        dict["TESTNAME"] = _parentOrBreedingLineOrDH.DeterminationName;
                        dict["MASTERNR"] = _parentOrBreedingLineOrDH.MasterNr;
                        dict["GID"] = _parentOrBreedingLineOrDH.GID;
                        dict["NROFPLANTS"] = _parentOrBreedingLineOrDH.NrOfPlants.ToText();
                        dict["FOLDERNR"] = _parentOrBreedingLineOrDH.FolderNr;
                        printData.Labels.Add(new Entities.Results.Label
                        {
                            LabelData = dict
                        });

                    }
                    listPrintData.Add(labelType, printData);
                }
                //now print data based on label type.
                foreach (var _printData in listPrintData)
                {
                    var result = await PrintToBartenderAsync(_printData.Value, _printData.Key);
                    if (result == null)
                    {
                        var item = printlabelResult.FirstOrDefault(x => x.Error == "Some of the print is not completed");
                        if (item == null)
                        {
                            printlabelResult.Add(new PrintLabelResult
                            {
                                Error = "Some of the print is not completed",
                                Success = false
                            });
                        }

                    }
                    else if (!result.Success)
                    {
                        var item = printlabelResult.FirstOrDefault(x => x.Error.ToText().Trim() == result.Error.ToText().Trim());
                        if (item == null)
                        {
                            printlabelResult.Add(new PrintLabelResult
                            {
                                Error = result.Error,
                                Success = false
                            });
                        }

                    }
                }
                //now collect the result and sent it to UI.
                var error = printlabelResult.FirstOrDefault(x => !string.IsNullOrWhiteSpace(x.Error));
                if (error != null)
                {
                    var errorMessage = string.Join("," + Environment.NewLine, printlabelResult.Select(x => x.Error));

                    return new PrintLabelResult
                    {
                        Error = errorMessage,
                        Success = false
                    };
                }
                else
                {
                    return new PrintLabelResult
                    {
                        Error = "Successfully request sent for printing sticker.",
                        Success = true
                    };
                }
            }
            else
            {
                return new PrintLabelResult
                {
                    Error = "Data not found for printing.",
                    Success = false
                };
            }

        }

        private async Task<PrintLabelResult> PrintToBartenderAsync(RDTPrintResult printData, string labelType)
        {
            var loggedInUser = userContext.GetContext().Name;
            var credentials = Credentials.GetCredentials();
            using (var svc = new BartenderSoapClient
            {
                Url = ConfigurationManager.AppSettings["BartenderServiceUrl"],
                Credentials = new NetworkCredential(credentials.UserName, credentials.Password)
            })
            {
                svc.Model = printData;

                var result = await svc.PrintToBarTenderAsync();
                return new PrintLabelResult
                {
                    Success = result.Success,
                    Error = result.Error,
                    PrinterName = labelType
                };
            }
        }
        private async Task<PrintLabelResult> PrintToBartenderAsync(Dictionary<string, string> data, string labelType)
        {
            //var labelType = ConfigurationManager.AppSettings["RDTPrinterLabelType"];
            if (string.IsNullOrWhiteSpace(labelType))
                throw new Exception("Please specify LabelType in settings.");

            var loggedInUser = userContext.GetContext().Name;
            var credentials = Credentials.GetCredentials();
            using (var svc = new BartenderSoapClient
            {
                Url = ConfigurationManager.AppSettings["BartenderServiceUrl"],
                Credentials = new NetworkCredential(credentials.UserName, credentials.Password)
            })
            {
                svc.Model = new
                {
                    User = loggedInUser,
                    LabelType = labelType,
                    Copies = 1,
                    Labels = new
                    {
                        LabelData = data
                    }
                };
                var result = await svc.PrintToBarTenderAsync();
                return new PrintLabelResult
                {
                    Success = result.Success,
                    Error = result.Error,
                    PrinterName = labelType
                };
            }

        }
        public async Task<IEnumerable<TestLookup>> GetTests()
        {
            return await DbContext.ExecuteReaderAsync(DataConstants.PR_RDT_GET_TEST_TO_SEND_SCORE, CommandType.StoredProcedure, reader => new TestLookup
            {
                TestID = reader.Get<int>(0),
                CropCode = reader.Get<string>(1),
                BreedingStationCode = reader.Get<string>(2),
                PlatePlanName = reader.Get<string>(3),
                TestName = reader.Get<string>(4),
                SiteName = reader.Get<string>(5)
            });

        }

        public async Task<IEnumerable<RDTScore>> GetRDTScores(int testID)
        {
            return await DbContext.ExecuteReaderAsync(DataConstants.PR_RDT_GET_SCORE,
                CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@TestID", testID);
                },
                reader => new RDTScore
                {
                    TestID = reader.Get<int>(0),
                    MaterialKey = reader.Get<string>(1),
                    FieldID = reader.Get<string>(2),
                    ColumnLabel = reader.Get<string>(3),
                    DeterminationScore = reader.Get<string>(4),
                    ObservationID = reader.Get<int>(5),
                    ImportLevel = reader.Get<string>(6),
                    MaterialID = reader.Get<int>(7),
                    TestResultID = reader.Get<int>(8),
                    ResultStatus = reader.Get<int>(9),
                    TratiDetResultID = reader.Get<int>(10),
                    TraitScore = reader.Get<string>(11),
                    FlowType = reader.Get<int>(12)
                });
        }

        public async Task UpdateObsrvationIDAsync(int testID, DataTable dt)
        {
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_RDT_UPDATE_OBSERVATIONID, CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@TestID", testID);
                    args.Add("@TVP_PropertyValue", dt);
                });
        }

        public async Task<int> MarkSentResultAsync(int testID, string testResultIDs)
        {
            var p1 = DbContext.CreateOutputParameter("@TestStatus", DbType.Int32);
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_RDT_MARK_SENT_RESULT, CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@TestID", testID);
                    args.Add("@TestResultIDs", testResultIDs);
                    args.Add("@TestStatus", p1);
                });
            return p1.Value.ToInt32();
        }

        public async Task MarkMissingConversionResultAsync(int testID, string testResultIDs)
        {
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_RDT_MARK_MISSINGCONVERSION, CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@TestID", testID);
                    args.Add("@TestResultIDs", testResultIDs);
                });
        }

        public async Task ErrorSentResultAsync(int testID, string testResultIDs)
        {
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_RDT_MARK_RESULT_ERROR, CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@TestID", testID);
                    args.Add("@TestResultIDs", testResultIDs);
                });
        }

        public async Task<List<string>> GetMappingColumnsAsync()
        {
            //var list = new List<string>
            //{
            //    "Average",
            //    "std av score",
            //    "Weighted average",
            //    "Av score weighted to RC and VC",
            //    "C&Tid",
            //    "#pl score1",
            //    "#pl score2",
            //    "#pl score3",
            //    "#pl score4",
            //    "#pl score5",
            //    "#pl score6",
            //    "#pl score7",
            //    "#pl score8",
            //    "#pl score9"
            //};
            var list = new List<string>
            {
                "Avg",
                "std",
                "Wavg",
                "WavgQC",
                "C&Tid",
                "#plscore1",
                "#plscore2",
                "#plscore3",
                "#plscore4",
                "#plscore5",
                "#plscore6",
                "#plscore7",
                "#plscore8",
                "#plscore9",
                "#selplants"
            };
            return await Task.FromResult(list);
        }

        public async Task<DataSet> RDTResultToExcelAsync(int testID, bool isMarkerScore)
        {
            return await DbContext.ExecuteDataSetAsync(DataConstants.PR_RDT_GET_RESULT_FOR_EXCEL, CommandType.StoredProcedure, args =>
            {
                args.Add("@TestID", testID);
                args.Add("@IsMarkerScore", isMarkerScore);
            });
        }
        public async Task<IEnumerable<RDTMissingConversion>> GetMissingConversionData(int testID)
        {
            return await DbContext.ExecuteReaderAsync(DataConstants.PR_RDT_GET_MAPPING_MISSING_SCORE, CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@TestID", testID);
                },
                reader => new RDTMissingConversion
                {
                    CropCode = reader.Get<string>(0),
                    TestName = reader.Get<string>(1),
                    DeterminationName = reader.Get<string>(2),
                    TraitName = reader.Get<string>(3),
                    DeterminationValue = reader.Get<string>(4),
                    MappingColumn = reader.Get<string>(5),
                    RDTTestResultID = reader.Get<int>(6)
                });
        }
        public async Task<RequestSampleTestResult> RDTUpdatesampletestinfoAsync(TestRequestArgs request)
        {
            _logger.Info("Get data for updatetestinfo.");

            //Prepare data            
            var data = await DbContext.ExecuteReaderAsync(DataConstants.PR_RDT_GETUPDATETESTINFO, CommandType.StoredProcedure, args =>
            {
                args.Add("@TestID", request.TestID);
            },
            reader => new UpdatedTestInfo
            {
                TestID = reader.Get<int>(0),
                MaterialID = reader.Get<int>(1),
                DeterminationID = reader.Get<int>(2),
                InterfaceRefID = reader.Get<int>(3),
                MaxSelect = reader.Get<int>(4),
                StatusCode = reader.Get<int>(5)
            });

            _logger.Info("Get data for updatetestinfo completed.");

            //execute lims service
            _logger.Info("Send to lims.");
            return await ExecuteRDTUpdatesampletestinfoAsync(data.ToList());
            _logger.Info("Send to lims completed.");

        }


        private async Task<RequestSampleTestResult> ExecuteRDTUpdatesampletestinfoAsync(List<UpdatedTestInfo> request)
        {
            await Task.Delay(1);
            var limsServiceUser = ConfigurationManager.AppSettings["LimsServiceUser"];
            var updateSuccess = true;
            var updateMessage = "";
            var cancelMessage = "";
            var cancelSuccess = true;

            var updateData = request.Where(x => x.StatusCode == 300).ToList();
            var cancelledData = request.Where(x => x.StatusCode == 200);

            var data = new Updatesampletestinfo();

            if (updateData.Any())
            {
                data = updateData.GroupBy(g => new { g.TestID })
                    .Select(x => new Updatesampletestinfo
                    {
                        Action = "Update",
                        RequestID = x.FirstOrDefault().TestID,
                        RequestingSystem = "UTM",
                        RequestingUser = limsServiceUser,
                        InterfaceRefIds = x.GroupBy(y => y.InterfaceRefID)
                                        .Select(z => new InterfaceRef
                                        {
                                            InterfaceRefId = z.Key,
                                            Info = new List<Dictionary<string, string>>{ new Dictionary<string, string>
                                            {
                                                {"Maxplt",z.FirstOrDefault().MaxSelect.ToText() }

                                            }
                                            }.ToList()
                                        }).ToList()
                    }).FirstOrDefault();
                var client = new LimsServiceRestClient();
                _logger.Info("send to lims for update started.");
                var resp = client.UpdatesampletestinfoAsync(data);
                _logger.Info("send to lims for update completed.");
                updateSuccess = resp.Success.EqualsIgnoreCase("True") ? true : false;
                if (!updateSuccess)
                {
                    updateMessage = resp.ErrorMsg;
                }

            }
            if (cancelledData.Any())
            {
                data = cancelledData.GroupBy(g => new { g.TestID })
                    .Select(x => new Updatesampletestinfo
                    {
                        Action = "Cancel",
                        RequestID = x.FirstOrDefault().TestID,
                        RequestingSystem = "UTM",
                        RequestingUser = limsServiceUser,
                        InterfaceRefIds = x.GroupBy(y => y.InterfaceRefID)
                                        .Select(z => new InterfaceRef
                                        {
                                            InterfaceRefId = z.Key,
                                            Info = new List<Dictionary<string, string>>()
                                        }).ToList()
                    }).FirstOrDefault();
                var client = new LimsServiceRestClient();
                _logger.Info("send to lims for cancel started.");
                var resp = client.UpdatesampletestinfoAsync(data);
                _logger.Info("send to lims for cancel completed.");
                cancelSuccess = resp.Success.EqualsIgnoreCase("True") ? true : false;
                if (!cancelSuccess)
                {
                    cancelMessage = resp.ErrorMsg;
                }
            }
            if (cancelSuccess && updateSuccess)
            {
                //update test status to 500 and mark InterfaceRefId to proper status (400 or 500 based on condition)
                var interfaceRefIDs = string.Join(",", request.GroupBy(x => x.InterfaceRefID).Select(y => y.Key));
                await UpdateRDTTestStatusAsync(new UpdateTestStatusRequestArgs { StatusCode = 500, TestId = request.FirstOrDefault().TestID }, interfaceRefIDs);

                return new RequestSampleTestResult() { Success = "True" };

            }
            else
                return new RequestSampleTestResult() { Success = "False", ErrorMsg = updateMessage + cancelMessage };

        }
        private async Task UpdateRDTTestStatusAsync(UpdateTestStatusRequestArgs request, string InterfaceRefID)
        {
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_RDT_UPDATE_TEST_STATUS, CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@TestID", request.TestId);
                    args.Add("@StatusCode", request.StatusCode);
                    args.Add("@InterfaceRefID", InterfaceRefID);
                });
        }

        public async Task UpdateRDTTestStatusAsync(UpdateTestStatusRequestArgs request)
        {
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_RDT_UPDATE_TEST_STATUS, CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@TestID", request.TestId);
                    args.Add("@StatusCode", request.StatusCode);
                });
        }

    }

}
