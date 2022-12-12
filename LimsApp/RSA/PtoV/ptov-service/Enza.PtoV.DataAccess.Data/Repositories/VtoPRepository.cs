using System;
using System.Collections.Generic;
using System.Configuration;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Xml.Linq;
using Enza.PtoV.Common;
using Enza.PtoV.Common.Extensions;
using Enza.PtoV.DataAccess.Abstract;
using Enza.PtoV.DataAccess.Data.Interfaces;
using Enza.PtoV.DataAccess.Interfaces;
using Enza.PtoV.Entities.Args.Abstract;
using Enza.PtoV.Entities.Results;
using Enza.PtoV.Entities.VtoP;
using Enza.PtoV.Services.Abstract;
using Enza.PtoV.Services.Proxies;
using log4net;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Enza.PtoV.DataAccess.Data.Repositories
{
    public class VtoPRepository : Repository<object>, IVtoPRepository
    {
        private readonly IUserContext userContext;
        private readonly IPhenomeServiceRespsitory _phenomeRepo;
        private readonly string _baseServiceUrl = ConfigurationManager.AppSettings["BasePhenomeServiceUrl"];
        private static readonly ILog _logger =
            LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);
        public VtoPRepository(IDatabase dbContext, IUserContext userContext,IPhenomeServiceRespsitory phenomeRepo) : base(dbContext)
        {
            this.userContext = userContext;
            _phenomeRepo = phenomeRepo;
        }

        public async Task SignInToPhenomeAsync(RestClient client)
        {
            HttpResponseMessage response;
            //sign in to Phenome
            LogInfo("Login to phenome started.");

            var ssoEnabled = ConfigurationManager.AppSettings["SSO:Enabled"].ToBoolean();
            if (!ssoEnabled)
            {
                var (UserName, Password) = Credentials.GetCredentials("SyncPhenomeCredentials");
                response = await client.PostAsync("/login_do", values =>
               {
                   values.Add("username", UserName);
                   values.Add("password", Password);
               });
            }
            else
            {
                var phenome = new PhenomeSSOClient();
                response = await phenome.SignInAsync(client);
            }
            await response.EnsureSuccessStatusCodeAsync();
            var result = await response.Content.DeserializeAsync<PhenomeResponse>();
            if (result.Status != "1")
                throw new Exception("Invalid user name or password");

            LogInfo("Login to phenome successful.");

            //var settingsData = await _phenomeRepo.GetSettingsAsync(client, 2997);
            ////lock variables
            //var variables = new List<string>()
            //    {
            //        "MasterNr",
            //        "E-number",
            //        "GenebankNr",
            //        "PedigrAbbr",
            //        "Pedigree",
            //        "Variety",
            //        "Gen",
            //        "Stem"
            //    };
            //await _phenomeRepo.ApplylockVariablesAsync(client, 2997, settingsData, variables, "Lock");

            ////unlock variables
            //variables = new List<string>()
            //    {
            //        "MasterNr",
            //        "E-number",
            //        "GenebankNr",
            //        //"PedigrAbbr", //this should remain unlocked
            //        "Pedigree",
            //        "Variety",
            //        "Gen",
            //        "Stem"
            //    };
            //await _phenomeRepo.ApplylockVariablesAsync(client, 2997, settingsData, variables, "Unlock");
        }

        public async Task<IEnumerable<GermplasmColumnInfo>> GetGermplasmColumnsAsync(RestClient client, int objectType, int objectID)
        {
            var url = "/api/v2/baseentity/germplasms/columns/get";
            var response = await client.PostAsync(url, values =>
            {
                values.Add("objectType", objectType.ToString());
                values.Add("objectId", objectID.ToString());
            });
            await response.EnsureSuccessStatusCodeAsync();
            //var resp2 = await response.Content.ReadAsStringAsync();
            var resp = await response.Content.DeserializeAsync<GermplasmColumnResponse>();
            if (resp.Status != "1")
            {
                throw new Exception("Couldn't fetch germplasm columns information from phenome.");
            }
            return resp.Available.ToList();
        }

        public async Task<CreateGermplasmResult> CreateGermplasmAsync(RestClient client, CreateGermplasmArgs args)
        {
            LogInfo("Creating germplasm to phenome started.");
            LogInfo($"Request paylod: name: {args.Name}, objectId: {args.ObjectID}.");
            //create germplasms
            var url = "/api/v2/baseentity/germplasmset/germplasm/set";
            var response = await client.PostAsync(url, values =>
            {
                values.Add("name", args.Name);
                values.Add("objectId", args.ObjectID.ToString());
            });
            await response.EnsureSuccessStatusCodeAsync();
            var resp2 = await response.Content.DeserializeAsync<CreateGermplasmResult>();
            if (resp2.status != "1")
            {
                throw new Exception("Creating germplasm to phenome failed.");
            }
            LogInfo("Creating germplasm to phenome successful.");
            return resp2;
        }

        public async Task UpdateGermplasmDataAsync(RestClient client, UpdateGermplasmDataArgs args,int rgID)
        {
            var colIDs = JsonConvert.SerializeObject(args.Values.Keys);
            var colValues = JsonConvert.SerializeObject(args.Values.Values);
            LogInfo($"Updating created Germplasm for GID {args.GID}. " +
                $"URL: ../api/v1/simplegrid/grid/save_grid/Germplasms" +
                $" Request payload:" +                
                $"object_type: {args.ObjectType.ToString()}, " +                
                $"object_id: {args.ObjectID.ToString()}," +
                $"row_ids: [\"{ args.GID }\"]," +
                $"col_ids: {colIDs}," +
                $"values:  [{ colValues }]");

            var url = "/api/v1/simplegrid/grid/save_grid/Germplasms";
            var response = await client.PostAsync(url, values =>
            {
                values.Add("object_type", args.ObjectType.ToString());
                values.Add("object_id", args.ObjectID.ToString());
                values.Add("row_ids", $"[\"{ args.GID }\"]");
                values.Add("col_ids", colIDs);
                values.Add("values", $"[{ colValues }]");
            });
            await response.EnsureSuccessStatusCodeAsync();
            var resp = await response.Content.DeserializeAsync<PhenomeResponse>();
            if (resp.Status != "1")
            {
                if (resp.Message.ToLower().Contains("column locked for editing"))
                {
                    //unlock variables
                    var settingsData = await _phenomeRepo.GetSettingsAsync(client, rgID);
                    var variables = new List<string>()
                    {
                        "MasterNr",
                        "E-number",
                        "Gen",
                        "Variety",
                        "Pedigree",
                        "PedigrAbbr",
                        "GenebankNr",
                        "Stem"
                    };
                    await _phenomeRepo.ApplylockVariablesAsync(client, rgID, settingsData, variables, "Unlock");
                    response = await client.PostAsync(url, values =>
                    {
                        values.Add("object_type", args.ObjectType.ToString());
                        values.Add("object_id", args.ObjectID.ToString());
                        values.Add("row_ids", $"[\"{ args.GID }\"]");
                        values.Add("col_ids", colIDs);
                        values.Add("values", $"[{ colValues }]");
                    });

                    await response.EnsureSuccessStatusCodeAsync();
                    resp = await response.Content.DeserializeAsync<PhenomeResponse>();
                    if (resp.Status != "1")
                    {
                        var msg = "Unable to update germplasm fields. Error : " + resp.Message;
                        throw new Exception(msg);
                    }

                }
                else
                {
                    var msg = "Unable to update germplasm fields. Error : " + resp.Message;
                    throw new Exception(msg);
                }
            }
            LogInfo($"Update Germplasm sucessful.");
        }
        
        public async Task<InventoryLotResult> GetInventoryLotAsync(RestClient client, int gid, string lotNr, int folderID, List<Column> columnsToLoad,string objectType)
        {
            //set few columns into grid
            //var gridID = "VtoP1234";
            var gridID = new Random().Next(10000000, 99999999).ToText();

            var colsAsJson = columnsToLoad.Where(x=>x.id.StartsWith("GER~") || x.id.StartsWith("LOT~")).Serialize();
            var url = "/api/v1/simplegrid/grid/set_display/InventoryLots";
            var response = await client.PostAsync(url, values =>
            {
                values.Add("grid_id", gridID);
                values.Add("columns", colsAsJson);
            });
            await response.EnsureSuccessStatusCodeAsync();
            var resp = await response.Content.DeserializeAsync<PhenomeResponse>();
            if (resp.Status != "1")
            {
                throw new Exception("Setting display columns failed.");
            }
            //prepare filter
            string gidFilterString = "=" + gid.ToText();
            var filterList = new Dictionary<string, string>
            {
                { "GER~id", gidFilterString }
            };
            //add Lotnr in filter list if it is not null or empty
            if(!string.IsNullOrWhiteSpace(lotNr))
            {
                var lotNrColumn = columnsToLoad.FirstOrDefault(o => o.desc.EqualsIgnoreCase("Lotnr") && o.id.ToLower().StartsWith("lot"));
                if (lotNrColumn != null)
                {
                    var lorNrFilterValue = "=" + lotNr;
                    filterList.Add(lotNrColumn.id, lorNrFilterValue);
                }
            }

            var filter = JsonConvert.SerializeObject(filterList);

            //filter data based on gid
            url = "/api/v1/simplegrid/grid/filter_grid/InventoryLots";
            var response2 = await client.PostAsync(url, values =>
            {
                values.Add("object_type", objectType);
                values.Add("object_id", folderID.ToString());
                values.Add("grid_id", gridID);
                values.Add("gems_map_id", "0");
                values.Add("admin_mode", "0");
                values.Add("simple_filter", filter);
                //values.Add("simple_filter", $"{{\"GER~id\":\"{gid}\"}}");
            });
            await response2.EnsureSuccessStatusCodeAsync();
            var resp2 = await response2.Content.DeserializeAsync<PhenomeResponse>();
            if (resp2.Status != "1")
            {
                throw new Exception("Filtering into grid failed.");
            }
           
            //get data from inventory grid
            url = $"/api/v1/simplegrid/grid/show_grid/InventoryLots?object_type={objectType}&object_id={folderID}&grid_id={gridID}&gems_map_id=0" +
                "&add_header=1&rows_per_page=1&use_name=name&display_column=0";
            var response3 = await client.GetAsync(url);
            await response3.EnsureSuccessStatusCodeAsync();
            var resp3 = await response3.Content.ReadAsStreamAsync();

            var xml = XDocument.Load(resp3);
            var doc = xml.Element("rows");
            var columns = doc.Element("head").Descendants("column")
                .Select((o, i) => new
                {
                    id = o.Attribute("id")?.Value,
                    index = i
                });

            var getIndexByColumnID = new Func<string, int>(id =>
            {
                var elem = columns.FirstOrDefault(o => o.id == id);
                if (elem != null)
                    return elem.index;
                return -1;
            });

            var data = doc.Descendants("row")
                .Select((o, i) =>
                {
                    var cells = o.Descendants("cell").ToList();
                    return new InventoryLotResult
                    {
                        LotID = o.Attribute("id").Value,
                        GID = gid.ToString() //cells[getIndexByColumnID("GER~id")].Value
                    };
                });

            return data.FirstOrDefault();
        }

        public async Task<List<Column>> GetInventoryLotColumnsAsync(RestClient client, int objectType, int objectID)
        {
            var url = "/api/v1/simplegrid/grid/get_columns_list/InventoryLots";
            var response = await client.PostAsync(url, values =>
            {
                values.Add("object_type", objectType.ToString());
                values.Add("object_id", objectID.ToString());
                values.Add("base_entity_id", "0");
            });
            await response.EnsureSuccessStatusCodeAsync();
            //var resp2 = await response.Content.ReadAsStringAsync();
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
            //return resp.All_Columns.Where(x => x.id.ToText().ToLower().StartsWith("lot"))
            //    .Select(o =>
            //    {
            //        var value = Regex.Replace(o.id, "LOT~", string.Empty, RegexOptions.IgnoreCase);//columnid for inventory update method
            //        o.col_num = value;
            //        return o;
            //    }).ToList();

        }

        public async Task<List<Column>> GetAllGermplasmColumnsAsync(RestClient client, int objectType, int objectID)
        {
            var url = "/api/v1/simplegrid/grid/get_columns_list/Germplasms";
            var response = await client.PostAsync(url, values =>
            {
                values.Add("object_type", objectType.ToString());
                values.Add("object_id", objectID.ToString());
                values.Add("base_entity_id", objectID.ToString());
            });
            await response.EnsureSuccessStatusCodeAsync();
            //var resp2 = await response.Content.ReadAsStringAsync();
            var resp = await response.Content.DeserializeAsync<InventoryLotColumnsResponse>();
            if (resp.Status != "1")
            {
                throw new Exception("Couldn't fetch Germplasm columns information from phenome.");
            }
            return resp.All_Columns.Where(x=>x.id.ToText().ToLower().StartsWith("ger"))
                .Select(o =>
                {
                    var value = Regex.Replace(o.id, "GER~", string.Empty, RegexOptions.IgnoreCase);
                    o.col_num = value;
                    return o;
                }).ToList();
        }

        public async Task UpdateInventoryLotAsync(RestClient client, string lotID, int objectType, 
            List<VtoPColumnMapping> mappedCols, List<Column> phenomeInventoryColumns, VtoPSyncClient.Lot data, 
            Dictionary<string, string> additionalValues)
        {
            LogInfo("Updating inventory lots to phenome started.");

            //get only inventory related mapping columns
            mappedCols = mappedCols.Where(o => o.TableName.EqualsIgnoreCase("Lot")).ToList();
            var columnValues = GetColumnValues(data, mappedCols);
            //add additional values here
            if (additionalValues != null && additionalValues.Any())
            {
                foreach (var key in additionalValues.Keys)
                {
                    columnValues[key] = additionalValues[key];
                }
            }
            //
            phenomeInventoryColumns = phenomeInventoryColumns.Where(x => x.id.StartsWith("LOT~")).ToList();

            //get lot columns informations
            var columns = (from t1 in mappedCols
                           join t2 in phenomeInventoryColumns on t1.PColumnName.ToText().ToLower() equals t2.desc.ToText().ToLower()
                           join t3 in columnValues on t1.PColumnName.ToLower() equals t3.Key.ToLower()
                           select new
                           {
                               ColumnID = t2.col_num,
                               ColumnValue = t3.Value
                           });
            if (!columns.Any()) return;            

            var url = "/api/v2/inventorylots/put/EditSingleLot";
            LogInfo($"URL: ../api/v2/inventorylots/put/EditSingleLot. Request payload:");
            var payload = "";
            var response = await client.PostAsync(url, form =>
            {
                form.Add("lotId", lotID);
                payload = $"lotId: {lotID}";
                foreach (var column in columns)
                {
                    payload = payload + $" {column.ColumnID}: {column.ColumnValue}";
                    if(column.ColumnID.EqualsIgnoreCase("creation_date") && !string.IsNullOrWhiteSpace(column.ColumnValue))
                    {
                        DateTime dateValue = new DateTime();

                        if (DateTime.TryParseExact(column.ColumnValue, "yyyyMMdd", CultureInfo.InvariantCulture, DateTimeStyles.AssumeLocal, out dateValue))
                        {
                            var unixTime = new DateTimeOffset(dateValue).ToUnixTimeMilliseconds();

                            form.Add(column.ColumnID, unixTime.ToText());
                        }
                    }
                    else
                    {
                        form.Add(column.ColumnID, column.ColumnValue);
                    }
                    
                }
            });
            LogInfo(payload);
            await response.EnsureSuccessStatusCodeAsync();
            var resp2 = await response.Content.DeserializeAsync<PhenomeResponse>();
            if (resp2.Status != "1")
            {
                throw new Exception("Updating inventory lots to phenome failed. Error: "+resp2.Message);
            }
            LogInfo("Updating inventory lots to phenome successful.");
        }

        public async Task<string> CreateInventoryLotAsync(RestClient client, int objectID, string gid, List<VtoPColumnMapping> mappedCols)
        {

            var url = "/api/v2/inventorylots/put/CreateLots";
            var val = "[\"" + gid + "\"]";
            var content = new MultipartFormDataContent
            {
                { new StringContent(val), "germplasmIds" },
                { new StringContent(objectID.ToText()), "researchGroupId" },
                { new StringContent("1"), "nrOfLots" },

            };
            var resp = await client.PostAsync(url, content);
            var rs = await resp.Content.ReadAsStringAsync();
            var result = await resp.Content.DeserializeAsync<CreateInventoryResult>();
            if(result.Status!="1")
            {
                var msg = "Creating inventory to phenome failed." + result.Message;
                throw new Exception(msg);
            }
            LogInfo($"Creating inventory to phenome successful for researchGroup {objectID.ToText()}.");

            var v1 = result.Data[0][gid].FirstOrDefault();
            return v1;

        }

        public Task<IEnumerable<VtoPSyncConfig>> GetSyncConfigsAsync()
        {
            return DbContext.ExecuteReaderAsync(DataConstants.PR_VTOPSYNC_GET_CONFIGS, System.Data.CommandType.StoredProcedure,
                args => { }, reader => new VtoPSyncConfig
                {
                    SyncConfigID = reader.Get<int>(0),
                    CropCode = reader.Get<string>(1),
                    SyncCode = reader.Get<string>(2),
                    GermplasmSetID = reader.Get<int>(3),
                    GBTHExternalLotFolderID = reader.Get<int>(4),
                    ABSLotFolderID = reader.Get<int>(5),
                    Level = reader.Get<string>(6),
                    LotNr = reader.Get<int>(7),
                    SelfingFieldSetID = reader.Get<int>(8),
                    HasOp = reader.Get<bool>(9),
                });
        }

        public async Task<IEnumerable<VtoPSyncClient.Lot>> GetVarmasLotsAndVarietiesAsync(VarmasLotsAndVarietiesArgs requestArgs)
        {
            using (var client = new VtoPSyncClient()) 
            {
                var url = ConfigurationManager.AppSettings["VarmasServiceUrl"];
                return await client.GetLotsAndVarietiesAsync(url, requestArgs, requestArgs.RequestedData);
            }
        }

        public async Task<bool> UpdateExtenalLotsToVarmasAsync(UpdateExternalLotsToVarmasArgs requestArgs)
        {
            using (var client = new VtoPSyncClient())
            {
                var url = ConfigurationManager.AppSettings["VarmasServiceUrl"];
                return await client.UpdateExtenalLotsAsync(url, requestArgs);
            }
        }

        public Task UpdatePtoVRelationshipAsync(string dataAsJson)
        {
            return DbContext.ExecuteNonQueryAsync(DataConstants.PR_VTOPSYNC_UPDATE_PTOV_RELATIONSHIP, System.Data.CommandType.StoredProcedure,
                args => args.Add("@DataAsJson", dataAsJson));
        }

        public Task UpdateLastLotNrToSyncConfigTableAsync(int syncConfigID, int LotNr)
        {
            return DbContext.ExecuteNonQueryAsync(DataConstants.PR_VTOPSYNC_UPDATE_LAST_LOTNR, System.Data.CommandType.StoredProcedure,
               args =>
               {
                   args.Add("@SyncConfigID", syncConfigID);
                   args.Add("@LotNr", LotNr);
               });
        }

        public async Task<string> GetGermplasmNameFromVarietyNrAsync(int varietyNr)
        {
            var p1 = DbContext.CreateOutputParameter("@GermplasmName", System.Data.DbType.String, int.MaxValue);
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_VTOPSYNC_GET_GERMPLASM_NAME_FROM_EZID,
                System.Data.CommandType.StoredProcedure, args =>
                {
                    args.Add("@VarietyNR", varietyNr);
                    args.Add("@GermplasmName", p1);
                });
            return p1.Value.ToText();
        }

        public Task<List<VtoPColumnMapping>> GetMappedColumnsAsync()
        {
            var result = new List<VtoPColumnMapping>
            {
                new VtoPColumnMapping
                {
                    TableName = "Lot",
                    VColumnName = string.Empty, //"blotn_lotnum", value for this column will be mapped later in the program as additionalcolumnvalues.
                    PColumnName ="Lotnr",
                    PCategory = 4
                },
                
                new VtoPColumnMapping
                {
                    TableName = "Lot",
                    VColumnName ="blotc_stock",
                    PColumnName ="SeedStock",
                    PCategory = 4
                },
                new VtoPColumnMapping
                {
                    TableName = "Lot",
                    VColumnName ="blotd_createdat",
                    PColumnName ="Creation Date",
                    PCategory = 4
                },
                new VtoPColumnMapping
                {
                    TableName = "Lot",
                    VColumnName =string.Empty, //value for this column will be mapped later in the program as additionalcolumnvalues
                    PColumnName ="GER Name",
                    PCategory = 12
                },
                new VtoPColumnMapping
                {
                    TableName = "Variety",
                    VColumnName =string.Empty,
                    PColumnName ="Crop",
                    PCategory = 4
                },
                new VtoPColumnMapping
                {
                    TableName = "Variety",
                    VColumnName ="bvarc_mastnumber",
                    PColumnName ="MasterNr",
                    PCategory = 4
                },
                new VtoPColumnMapping
                {
                    TableName = "Variety",
                    VColumnName ="vvarc_enumber",
                    PColumnName ="E-number",
                    PCategory = 4
                },
                new VtoPColumnMapping
                {
                    TableName = "Variety",
                    VColumnName ="bgenc_genercod",
                    PColumnName ="Gen",
                    PCategory = 4
                },
                new VtoPColumnMapping
                {
                    TableName = "Variety",
                    VColumnName ="vvarc_shortname",
                    PColumnName ="Variety",
                    PCategory = 4
                }                ,
                new VtoPColumnMapping
                {
                    TableName = "Variety",
                    VColumnName ="vvarc_stbdescr",
                    PColumnName ="Pedigree",
                    PCategory = 4
                },
                new VtoPColumnMapping
                {
                    TableName = "Variety",
                    VColumnName ="vvarc_stbdescr",
                    PColumnName ="PedigrAbbr",
                    PCategory = 4
                },
                new VtoPColumnMapping
                {
                    TableName = "Variety",
                    VColumnName ="vvarc_genenumber",
                    PColumnName ="GenebankNr",
                    PCategory = 4
                }
            };
            return Task.FromResult(result);
        }
        public async Task<int> GetPhenomeGIDFromVarietyNrAsync(int varietyNr)
        {
            string query = "SELECT GID FROM RelationPtoV WHERE VarietyNr = @VarietyNr";
            var data = await DbContext.ExecuteScalarAsync(query, args => args.Add("@VarietyNr", varietyNr));
            return data.ToInt32();
            
        }

        public async Task<VarietyWithLot> GetGIDDetailFromLotNrAsync(int originLotNr)
        {
            string query = @"SELECT TOP 1 
                                R.GID,
                                L.VarmasLot AS LotNr,
                                R.NewGID,                             
                                R.VarietyNr
                              FROM Lot L                              
                              JOIN RelationPtoV R ON R.GID = L.GID
                            WHERE L.VarmasLot = @originLotNr";
            var data = await DbContext.ExecuteReaderAsync(query, args => args.Add("@originLotNr", originLotNr),
            reader=>new VarietyWithLot
            {
                BaseGID = reader.Get<int>(0),
                LotNr = reader.Get<int>(1),
                NewGID = reader.Get<int>(2),
                VarietyNr = reader.Get<int>(3),
            });
            return data.FirstOrDefault();
            //return data.ToInt32();

        }
        public async Task<VarietyWithLot> GetGIDDetailFromPhenomeGIDAsync(int PhenomeGID)
        {
            string query = @"SELECT TOP 1 
                                GID,
                                NewGID,                             
                                VarietyNr
                              FROM RelationPtoV
                              WHERE GID = @GID";
            var data = await DbContext.ExecuteReaderAsync(query, args => args.Add("@GID", PhenomeGID),
            reader => new VarietyWithLot
            {
                BaseGID = reader.Get<int>(0),
                NewGID = reader.Get<int>(1),
                VarietyNr = reader.Get<int>(2),
            });
            return data.FirstOrDefault();
            //return data.ToInt32();

        }
        public async Task<VarietyWithLot> GetGIDDetailFromVarietyNrAsync(int VarietyNr)
        {
            string query = @"SELECT TOP 1 
                                GID,                                
                                NewGID,                             
                                VarietyNr
                              FROM RelationPtoV
                              WHERE VarietyNr = @VarietyNr";
            var data = await DbContext.ExecuteReaderAsync(query, args => args.Add("@VarietyNr", VarietyNr),
            reader => new VarietyWithLot
            {
                BaseGID = reader.Get<int>(0),
                NewGID = reader.Get<int>(1),
                VarietyNr = reader.Get<int>(2),
            });
            return data.FirstOrDefault();
            //return data.ToInt32();

        }

        #region Private Methods

        private string CreateCsvData(VtoPSyncClient.Lot data, List<VtoPColumnMapping> mappedCols, string lotNr)
        {
            var sr = new StringWriter();
            //get only GER Name column. rest of the columns will be updated later
            //var colNames = new[] { "GER Name", "Lotnr" };
            //mappedCols = mappedCols.Where(o => colNames.Contains(o.PColumnName, StringComparer.OrdinalIgnoreCase))
            //    .ToList();

            var fields = mappedCols.Select(o => o.PColumnName)
            .ToList();
            //write header
            sr.WriteLine(string.Join(",", fields));
            //prepare values
            var columnValues = GetColumnValues(data, mappedCols);
            columnValues["Lotnr"] = lotNr;
            //write values
            sr.WriteLine(string.Join(",", columnValues.Values));
            return sr.ToString();
        }

        private Dictionary<string, string> GetColumnValues(VtoPSyncClient.Lot data, List<VtoPColumnMapping> mappedCols)
        {
            var values = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (var mappedCol in mappedCols)
            {
                var columnValue = data.ProgramFields.FirstOrDefault(o => o.ProgramFieldCode.EqualsIgnoreCase(mappedCol.VColumnName));
                values.Add(mappedCol.PColumnName, columnValue != null ? columnValue.ProgramFieldValue : string.Empty);
            }
            return values;
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


        #endregion
    }

    public class FieldMappings
    {
        public FieldMappings()
        {
            Common = new CommonMapping();
            Crops = new List<CropMapping>();
        }
        public CommonMapping Common { get; set; }

        public List<CropMapping> Crops { get; set; }

        public class CommonMapping
        {
            public CommonMapping()
            {
                Lots = new List<FieldMapping>();
                Varieties = new List<FieldMapping>();
            }
            public List<FieldMapping> Lots { get; set; }
            public List<FieldMapping> Varieties { get; set; }
        }

        public class CropMapping
        {
            public CropMapping()
            {
                Lots = new List<FieldMapping>();
                Varieties = new List<FieldMapping>();
            }
            public string CropCode { get; set; }
            public List<FieldMapping> Lots { get; set; }
            public List<FieldMapping> Varieties { get; set; }
        }

        public class FieldMapping
        {
            public string VColumnName { get; set; }
            public string PColumnName { get; set; }
            public int Category { get; set; }
        }
    }
}
