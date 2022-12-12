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

namespace Enza.UTM.DataAccess.Data.Repositories
{
    public class LeafDiskRepository : Repository<object>, ILeafDiskRepository
    {
        private readonly IUserContext _userContext;
        private readonly string BASE_SVC_URL = ConfigurationManager.AppSettings["BasePhenomeServiceUrl"];

        public LeafDiskRepository(IDatabase dbContext, IUserContext userContext) : base(dbContext)
        {
            _userContext = userContext;
        }

        public async Task<ExcelDataResult> GetDataAsync(LeafDiskGetDataRequestArgs requestArgs)
        {
            var result = new ExcelDataResult();
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_LFDISK_GET_DATA, CommandType.StoredProcedure,
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

        public async Task<DataTable> GetConfigurationListAsync(string crops)
        {
            var ds = await DbContext.ExecuteDataSetAsync(DataConstants.PR_LFDISK_GET_CONFIGURATIONLIST, CommandType.StoredProcedure, args =>
            {
                args.Add("@Crops", crops);
            });

            return ds.Tables[0];
        }

        public async Task<bool> SaveConfigurationNameAsync(SaveSampleConfigurationRequestArgs requestArgs)
        {
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_LFDISK_SAVE_CONFIGURATION_NAME, CommandType.StoredProcedure, args =>
            {
                args.Add("@TestID", requestArgs.TestID);
                args.Add("@SamleConfigName", requestArgs.SampleConfigName);
            });

            return true;
        }

        public async Task<PhenoneImportDataResult> ImportDataFromPhenomeAsync(HttpRequestMessage request, LeafDiskRequestArgs args)
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

                //Required fields
                //Plot: FEID and Plot name
                //Selection: GID and Origin
                //Cross: GID and Female code
                var requiredFields = new List<string>();

                //object type 
                //24 => list/nursery (list/plants)
                //25=> maps
                //26=> Plots
                //27=> crosses
                //28=> selections
                //29=> observations

                //plots
                if (args.ObjectType.EqualsIgnoreCase("26"))
                {
                    requiredFields.Add("FEID");
                    requiredFields.Add("Plot name");
                    URI = "/api/v1/simplegrid/grid/create/FieldPlots";
                    importFrom = "FieldPlots";
                }
                //selection
                else if (args.ObjectType.EqualsIgnoreCase("28"))
                {
                    requiredFields.Add("GID");
                    requiredFields.Add("Origin");
                    URI = "/api/v1/simplegrid/grid/create/FieldSelections";
                    importFrom = "FieldSelections";
                }
                //crosses
                else if(args.ObjectType.EqualsIgnoreCase("27"))
                {
                    requiredFields.Add("GID");
                    requiredFields.Add("Female code");
                    URI = "/api/v1/simplegrid/grid/create/FieldCrosses";
                    importFrom = "FieldCrosses";
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

                //apply sorting for selection with  origin field
                if (args.ObjectType.EqualsIgnoreCase("28"))
                {
                    var originColumnID = columnResponse.Columns.Where(x => x.desc.EqualsIgnoreCase("origin")).FirstOrDefault().id;

                    var sortingValue = new[] { new { id = originColumnID, sort_type = "auto", direction = "asc" } };
                    var jsonSortingString = sortingValue.ToArray().ToJson();
                    URI = "api/v1/simplegrid/grid/create_rows/FieldSelections";
                    var response1 = await client.PostAsync(URI, values =>
                    {
                        values.Add("object_type", args.ObjectType);
                        values.Add("object_id", args.ObjectID);
                        values.Add("grid_id", args.GridID);
                        values.Add("simple_filter", "{}");
                        values.Add("sort", jsonSortingString);

                    });
                    var sortingResponse = await response1.Content.DeserializeAsync<PhenomeResponse>();
                    if(!sortingResponse.Success)
                    {
                        result.Errors.Add("Unable to apply sorting in Phenome.");
                        return result;
                    }
                }
                //apply sorting for crosses with female code
                else if (args.ObjectType.EqualsIgnoreCase("27"))
                {
                    var femaleCodeColumnID = columnResponse.Columns.Where(x => x.desc.EqualsIgnoreCase("female code")).FirstOrDefault().id;
                    var sortingValue = new[] { new { id = femaleCodeColumnID, sort_type = "auto", direction = "asc" } };
                    var jsonSortingString = sortingValue.ToJson();

                    URI = "api/v1/simplegrid/grid/create_rows/FieldCrosses";
                    
                    var response1 = await client.PostAsync(URI, values =>
                    {
                        values.Add("object_type", args.ObjectType);
                        values.Add("object_id", args.ObjectID);
                        values.Add("grid_id", args.GridID);
                        values.Add("simple_filter", "{}");
                        values.Add("sort", jsonSortingString);

                    });
                    var sortingResponse = await response1.Content.DeserializeAsync<PhenomeResponse>();
                    if (!sortingResponse.Success)
                    {
                        result.Errors.Add("Unable to apply sorting in Phenome.");
                        return result;
                    }
                }

                URI = $"/api/v1/simplegrid/grid/get_json/{importFrom}?" +
                            $"object_type={args.ObjectType}" +
                            $"&object_id={args.ObjectID}" +
                            $"&grid_id={args.GridID}" +
                            "&gems_map_id=0" +
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

                var columns2 = receivedData.Columns.Select((x, i) => new
                {
                    x.Properties[0].ID,
                    Index = i

                }).GroupBy(g => g.ID).Select(x => new
                {
                    ID = x.Key,
                    x.FirstOrDefault().Index
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
                var ds = await GetDataAsync(new LeafDiskGetDataRequestArgs
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

        public async Task<PhenoneImportDataResult> ImportDataFromConfigurationAsync(LDImportFromConfigRequestArgs requestArgs)
        {
            var p1 = DbContext.CreateInOutParameter("@TestID", requestArgs.TestID, DbType.Int32, int.MaxValue);
            DbContext.CommandTimeout = 5 * 60; //5 minutes

            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_LFDISK_IMPORT_FROM_CONFIGURATION,
                CommandType.StoredProcedure, args =>
                {
                    args.Add("@TestID", p1);
                    args.Add("@SourceID", requestArgs.SourceID);
                    //args.Add("@TestProtocolID", requestArgs.TestProtocolID);
                    //args.Add("@CropCode", cropCode);
                    //args.Add("@BrStationCode", brStationCode);
                    //args.Add("@SyncCode", syncCode);
                    //args.Add("@CountryCode", countryCode);
                    args.Add("@UserID", _userContext.GetContext().FullName);
                    args.Add("@TestProtocolID", requestArgs.TestProtocolID);
                    args.Add("@TestName", requestArgs.TestName);
                    //args.Add("@ObjectID", requestArgs.ObjectID);
                    //args.Add("@ImportLevel", materialType);
                    //args.Add("@TVPColumns", tVPColumns);
                    //args.Add("@TVPRow", tVPRows);
                    //args.Add("@TVPCell", tVPCells);
                    //args.Add("@FileID", requestArgs.FileID);
                    args.Add("@PlannedDate", requestArgs.PlannedDate);
                    args.Add("@MaterialTypeID", requestArgs.MaterialTypeID);
                    args.Add("@SiteID", requestArgs.SiteID);
                });
            requestArgs.TestID = p1.Value.ToInt32();

            var result = new PhenoneImportDataResult();
            //get imported data
            var ds = await GetDataAsync(new LeafDiskGetDataRequestArgs
            {
                TestID = requestArgs.TestID,
                PageNumber = 1,
                PageSize = 200
            });

            result.Total = ds.Total;
            result.TotalCount = ds.TotalCount;
            result.DataResult = ds.DataResult;
            return result;
        }

        public async Task AssignMarkersAsync(LFDiskAssignMarkersRequestArgs requestArgs)
        {
            var columnNames = string.Join(",", requestArgs.Filter.Select(x => x.Name));
            var determinations = string.Join(",", requestArgs.Determinations);
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_LFDISK_ASSIGNMARKERS, CommandType.StoredProcedure, args =>
            {
                args.Add("@TestID", requestArgs.TestID);
                args.Add("@Determinations", determinations);
                args.Add("@ColNames", columnNames);
                args.Add("@Filters", requestArgs.FiltersAsSQL());
            });
        }

        public async Task ManageInfoAsync(LeafDiskManageMarkersRequestArgs requestArgs)
        {
            if(requestArgs.Action.EqualsIgnoreCase("add"))
            {
                var determinations = string.Join(",", requestArgs.Determinations);
                var samples = string.Join(",", requestArgs.SampleIDs);
                await DbContext.ExecuteNonQueryAsync(DataConstants.PR_LFDISK_ASSIGNMARKERS, CommandType.StoredProcedure, args =>
                {
                    args.Add("@TestID", requestArgs.TestID);
                    args.Add("@Determinations", determinations);
                    args.Add("@SelectedMaterial", samples);
                    args.Add("@Filters", requestArgs.ToFilterString());
                });
            }
            else if(requestArgs.Action.EqualsIgnoreCase("update"))
            {
                var dataAsJson = requestArgs.ToJson();
                await DbContext.ExecuteNonQueryAsync(DataConstants.PR_LFDISK_MANAGEINFO, CommandType.StoredProcedure, args =>
                {
                    args.Add("@TestID", requestArgs.TestID);
                    args.Add("@DataAsJson", dataAsJson);
                });

            }
            else if(requestArgs.Action.EqualsIgnoreCase("remove"))
            {
                var samples = string.Join(",", requestArgs.SampleIDs);
                await DbContext.ExecuteNonQueryAsync(DataConstants.PR_LFDISK_DELETE_SAMPLETEST, CommandType.StoredProcedure, args =>
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
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_LFDISK_GET_DATA_WITH_MARKER, CommandType.StoredProcedure, args1 =>
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
            var nrOfSamples = ConfigurationManager.AppSettings["TotalPlantsInSample"];
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_LFDISK_GET_SAMPLEMATERIAL,
                CommandType.StoredProcedure, args =>
                {
                    args.Add("@TestID", requestargs.TestID);
                    args.Add("@Page", requestargs.PageNumber);
                    args.Add("@PageSize", requestargs.PageSize);
                    args.Add("@FilterQuery", requestargs.ToFilterString());
                    args.Add("@TotalPlantsInSample", nrOfSamples);
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
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_LFDISK_SAVE_SAMPLETEST, CommandType.StoredProcedure, args =>
            {
                args.Add("@TestID", requestArgs.TestID);
                args.Add("@SampleName", requestArgs.SampleName);
                args.Add("@NrOfSamples", requestArgs.NrOfSamples ?? 1);
                args.Add("@SampleID", requestArgs.SampleID);
            });

            return true;
        }

        public async Task<bool> SaveSampleMaterialAsync(SaveSamplePlotRequestArgs requestArgs)
        {
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_LFDISK_SAVE_SAMPLEMATERIAL, CommandType.StoredProcedure, args =>
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
                args.Add("@TestID",testID);
            },reader=>new GetSampleResult
            {
                SampleID = reader.Get<int>(0),
                SampleName = reader.Get<string>(1),
            });
            return data;
        }

        public async Task<LeafDiskPunchlist> GetPunchlistAsync(int testID)
        {
            var data = await DbContext.ExecuteReaderAsync(DataConstants.PR_LFDISK_GET_PUNCHLIST, CommandType.StoredProcedure, args =>
            {
                args.Add("@TestID", testID);
            }, reader => new LDSampleMaterial
            {
                SampleID = reader.Get<int>(0),
                SampleName = reader.Get<string>(1),
                MaterialID = reader.Get<int>(2),
                Material = reader.Get<string>(3)
            });
            var nrOfSample = 20;
            int.TryParse(ConfigurationManager.AppSettings["TotalPlantsInSample"],out nrOfSample);
            
            var punchlistData = new LeafDiskPunchlist();

            for (int i = 1; i <= nrOfSample; i++)
            {
                punchlistData.Columns.Add(new LeafDiskPunchlist.Column
                {
                    ColumnNr = i,
                    ColumnHeader = "PL-" + i
                });
            }

            var dataCell = data.GroupBy(x => x.SampleID).Select((x, index) => new LeafDiskPunchlist.Row
            {
                RowNr = index + 1,
                RowHeader = x.FirstOrDefault().SampleName,
                Cells = x.Select((y, index1) => new LeafDiskPunchlist.Cell { RowNr = index + 1, ColumnNr = index1 + 1, Value = y.Material }).ToList()

            }).ToList();

            //get row cells which do not contain all required number of cells
            var cellData = dataCell.Where(x => x.Cells.Count < 20).Select(x => x).ToList();
            foreach (var _cellData in cellData)
            {
                var count = _cellData.Cells.Count;
                for (int i = count + 1; i <= nrOfSample; i++)
                {
                    _cellData.Cells.Add(new LeafDiskPunchlist.Cell { RowNr = _cellData.RowNr, ColumnNr = i, Value = "" });
                }
            }
            punchlistData.Rows = dataCell;
            punchlistData.CellsPerRow = nrOfSample / 2;
            return punchlistData;
        }

        public async Task<IEnumerable<PlateLabelLeafDisk>> GetPrintLabelsAsync(int testID)
        {
            return await DbContext.ExecuteReaderAsync(DataConstants.PR_LFDISK_GET_PRINT_LABELS,
                CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@TestID", testID);
                }, reader => new PlateLabelLeafDisk
                {
                    CropCode = reader.Get<string>(0),
                    SampleName = reader.Get<string>(1)
                });
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
            LeafDiskRequestArgs requestArgs, DataTable tVPColumns, DataTable tVPRows, 
            DataTable tVPCells)
        {
            var p1 = DbContext.CreateInOutParameter("@TestID", requestArgs.TestID, DbType.Int32, int.MaxValue);
            DbContext.CommandTimeout = 5 * 60; //5 minutes
            var materialType = "Plot";
            if(requestArgs.ObjectType.EqualsIgnoreCase("26"))
            {
                materialType = "PLOT";
            }
            else if (requestArgs.ObjectType.EqualsIgnoreCase("27"))
            {
                materialType = "CROSSES";
            }
            else if (requestArgs.ObjectType.EqualsIgnoreCase("28"))
            {
                materialType = "SELECTIONS";
            }
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_LFDISK_IMPORT_MATERIALS,
                CommandType.StoredProcedure, args =>
                {
                    args.Add("@TestID", p1);                    
                    args.Add("@TestProtocolID", requestArgs.TestProtocolID);
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
                });
            requestArgs.TestID = p1.Value.ToInt32();
        }

        private async Task<DataTable> GetDataWithMarkerForExcelAsync(int testID)
        {
            //this will return dataset with data and only determination columns
            var ds =  await DbContext.ExecuteDataSetAsync(DataConstants.PR_CNT_GET_DATA_WITH_MARKER_FOR_EXCEL,
                CommandType.StoredProcedure, args =>
                {
                    args.Add("@TestID", testID);
                });
            return ds.Tables[0];
        }

        public async Task<bool> UpdateMaterialAsync(UpdateMaterialRequestArgs requestArgs)
        {
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_LFDISK_UPDATE_TEST_MATERIAL, CommandType.StoredProcedure, args =>
            {
                args.Add("@TestID", requestArgs.TestID);
                args.Add("@Json", requestArgs.Materials.ToJson());
            });

            return true;
        }

        public async Task<ExcelDataResult> GetLeafDiskOverviewAsync(LeafDiskOverviewRequestArgs requestArgs)
        {
            var result = new ExcelDataResult();
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_LFDISK_GETOVERVIEW, CommandType.StoredProcedure,
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
                result.Errors.Add("Problem getting data from database");
            }
            else
            {
                result.Success = true;
                result.DataResult = new ExcelData
                {
                    Data = data.Tables[0],
                    Columns = data.Tables[1]
                };
                if (result.DataResult.Data.Rows.Count > 0)
                {
                    result.TotalCount = result.DataResult.Data.Rows[0]["TotalRows"].ToInt32();
                    result.Total = result.TotalCount;
                }

            }
            
            return result;
        }

        public async Task<DataTable> LeafDiskOverviewToExcelAsync(int testID)
        {
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_LFDISK_GETRESULT_TO_EXCEL, CommandType.StoredProcedure, args =>
            {
                args.Add("@TestID", testID);
            });
            return data.Tables[0];
        }

        public async Task<LDRequestSampleTestResult> LDRequestSampleTestAsync(TestRequestArgs requestArgs)
        {
            //Prepare data            
            var data = await DbContext.ExecuteReaderAsync(DataConstants.PR_LFDISK_GetSamplesForUpload, CommandType.StoredProcedure, args =>
            {
                args.Add("@TestID", requestArgs.TestID);
            },
            reader => new LDRequestSampleTest
            {
                Crop = reader.Get<string>(0),
                BrStation = reader.Get<string>(1),
                RequestID = reader.Get<int>(2),
                Site = reader.Get<string>(3),
                RequestingSystem = reader.Get<string>(4),
                SampleTestDetID = reader.Get<int>(5),
                SampleID = reader.Get<int>(6),
                DeterminationID = reader.Get<int>(7), //Lims determination id
                MethodCode = reader.Get<string>(8),
                SampleName = reader.Get<string>(9),
                ReferenceCode = reader.Get<string>(10)

            });
            return await ExecuteRequestSampleTestLD(data.ToList());
        }

        private async Task<LDRequestSampleTestResult> ExecuteRequestSampleTestLD(List<LDRequestSampleTest> request)
        {
            await Task.Delay(1);
            var limsServiceUser = ConfigurationManager.AppSettings["LimsServiceUser"];

            var data = request.GroupBy(g => new { g.RequestID })
                .Select(o => new LDRequestSampleTestRequest
                {
                    Crop = o.FirstOrDefault().Crop,
                    BrStation = o.FirstOrDefault().BrStation,
                    RequestID = o.Key.RequestID,
                    Site = o.FirstOrDefault().Site,
                    RequestingUser = limsServiceUser,
                    RequestingName = limsServiceUser,
                    RequestingSystem = o.FirstOrDefault().RequestingSystem,
                    SampleDeterminations = o.Select(p => new SampleDetermination
                    {
                        SampleTestDetID = p.SampleTestDetID,
                        SampleID = p.SampleID,
                        DeterminationID = p.DeterminationID,
                        MethodCode = p.MethodCode
                    }).ToList(),
                    SamplesInfo = o.GroupBy(x=>x.SampleID).Select(y=>new SampleInfo
                    {
                        SampleID = y.Key,
                        //Info = new Dictionary<string, string>() { {"SampleName", y.FirstOrDefault().SampleName},{ "TubeCode", y.FirstOrDefault().ReferenceCode } }
                        Info = new List<Dictionary<string, string>>() { new Dictionary<string, string>() { { "Samplename", y.FirstOrDefault().SampleName} }, new Dictionary<string, string>() { { "TubeCode", y.FirstOrDefault().ReferenceCode } } }
                    }).ToList()
                }).FirstOrDefault();
            var client = new LimsServiceRestClient();


            // This code needs to be removed when real service is called
            //return new LDRequestSampleTestResult
            //{
            //    Success = "True",
            //    ErrorMsg = ""
            //};

            //Calling LIMS web service is not implemented yet
            return client.RequestSampleTestLDAsync(data);
        }

        public async Task<ReceiveLDResultsReceiveResult> ReceiveLDResultsAsync(ReceiveLDResultsRequestArgs requestArgs)
        {
            var reess = requestArgs.Results.ToJson();
            await DbContext.ExecuteReaderAsync(DataConstants.PR_LFDISK_RECEIVE_RESULTS, CommandType.StoredProcedure, args =>
            {
                args.Add("@TestID", requestArgs.RequestID);
                args.Add("@Json", requestArgs.Results.ToJson());
            });

            return new ReceiveLDResultsReceiveResult() { Success = "True", ErrorMsg = "" };
        }

        public async Task<DataSet> ProcessSummaryCalcuationAsync()
        {
            return await DbContext.ExecuteDataSetAsync(DataConstants.PR_LFDISK_PROCESS_SUMMARY_CALCULATION,
               CommandType.StoredProcedure);
        }
    }
}