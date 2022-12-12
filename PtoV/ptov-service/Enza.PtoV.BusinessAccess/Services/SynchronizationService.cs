using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Enza.PtoV.BusinessAccess.Interfaces;
using Enza.PtoV.Common.Extensions;
using Enza.PtoV.Entities.Results;
using Enza.PtoV.Services.Abstract;
using System.Data;
using System.Linq;
using System.Xml.Linq;
using System.Configuration;
using Enza.PtoV.Common;
using Enza.PtoV.Entities.Args.Abstract;
using Enza.PtoV.Services.Interfaces;
using Enza.PtoV.Services.Proxies;
using log4net;
using System.Net.Http;
using System.Security;
using Enza.PtoV.Entities;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Enza.PtoV.BusinessAccess.Services
{
    public class SynchronizationService : ISynchronizationService
    {
        private readonly IUELService _uelService;
        private readonly IGermplasmService _germplasmService;
        private readonly string _baseServiceUrl = ConfigurationManager.AppSettings["BasePhenomeServiceUrl"];
        private static readonly ILog _logger =
            LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);
        public SynchronizationService(IUELService uelService, IGermplasmService germplasmService)
        {
            _uelService = uelService;
            _germplasmService = germplasmService;
        }

        public async Task<List<ExecutableError>> SyncGermplasmsAsync()
        {
            //var success = true;
            var errorMessage = new List<ExecutableError>();
            try
            {


                var batchSize = ConfigurationManager.AppSettings["PhenomeBatchSize"].ToInt32();
                var varmasUserName = ConfigurationManager.AppSettings["VarmsUserName"];
                using (var client = new RestClient(_baseServiceUrl))
                {
                    //login
                    LogInfo("Begin login to phenome.");

                    var resp = await SignInAsync(client);
                    await resp.EnsureSuccessStatusCodeAsync();

                    var result = await resp.Content.DeserializeAsync<PhenomeResponse>();
                    if (result.Status != "1")
                    {
                        //LogError("Invalid user name or password.");
                        throw new Exception("Invalid user name or password.");
                    }
                    LogInfo("Login successful to phenome.");

                    //Get Phenome object and its associated columns details to fetch data from phenome
                    var crops = await _germplasmService.GetCropsAsync();
                    //var crops1 = crops.Where(x => x.CropCode == "ED");
                    //Sync data for each crops
                    foreach (var crop in crops)
                    {
                        try
                        {
                            #region Crop Wise Processing

                            LogInfo($"Synchronization processing for the crop code  {crop.CropCode}.");

                            await SyncToVarmasAsync(varmasUserName, crop.CropCode, errorMessage);


                            var cropCols = (await _germplasmService.GetPhenomeObjectDetailAsync(crop.CropCode)).ToList();
                            
                            
                            //new method to sync data from phenome to PtoV

                            var url1 = "/api/v2/germplasm/get_data_by_update_time";
                            var recordStartPosition = 0;
                            var recordCount = 500;
                            var totalRecord = 501;
                            var researchGroupID = crop.ObjectID;
                            var modified_after = crop.VarietySyncTIme.ToString("yyyy-MM-dd HH:mm:ss"); //"2022-05-17 03:50:00";
                            var variableIDS = string.Concat("[", string.Join(", ", cropCols.Select(x => x.VariableID)), "]"); //"[5844, 5845]";

                            //var url1 = "/api/v2/germplasm/get_data_by_update_time";
                            //var recordStartPosition = 0;
                            //var recordCount = 500;
                            //var totalRecord = 501;
                            //var researchGroupID = 3068;
                            //var modified_after = "2022-05-17 03:50:00";
                            //var variableIDS = "[5844, 5845]";


                            //declare datatable to sync data from phenome to ptov 
                            var dt = new DataTable("TVP_Synchronization");
                            dt.Columns.Add("GID", typeof(int));
                            dt.Columns.Add("ColumnID", typeof(int));
                            dt.Columns.Add("Value", typeof(string));

                            while (recordStartPosition < totalRecord)
                            {
                                var response123 = await client.PostAsync(url1, values =>
                                {
                                    values.Add("research_group_id", researchGroupID.ToText());
                                    values.Add("modified_after", modified_after);
                                    values.Add("record_start_position", recordStartPosition.ToText());
                                    values.Add("records_count", recordCount.ToText());
                                    values.Add("add_parent_ids", "0");
                                    values.Add("variable_ids", variableIDS);
                                });
                                await response123.EnsureSuccessStatusCodeAsync();
                                var stringResult = await response123.Content.ReadAsStringAsync();
                                var val = (JObject)JsonConvert.DeserializeObject(stringResult);


                                totalRecord = val["data"]["total_records_count"].Value<int>();//.ToString();

                                var val1 = val["data"]["gids"].Value<JObject>();
                                //var val2 = val["data"]["gids"];

                                if (val1.HasValues)
                                {
                                    foreach (var _val1 in val1)
                                    {
                                        var GID = _val1.Key;
                                        if (_val1.Value.HasValues)
                                        {
                                            {
                                                var variablesIDS = val1[GID].Value<JObject>();
                                                foreach(var _variableID in variablesIDS)
                                                {
                                                    if(_variableID.Key == "vars")
                                                    {
                                                        var changedvalue = variablesIDS["vars"].Value<JObject>();
                                                        foreach(var _changedValue in changedvalue)
                                                        {
                                                            var varID = _changedValue.Key;
                                                            var colID = cropCols.FirstOrDefault(x => x.VariableID == varID)?.ColumnID;
                                                            if(colID != null && colID > 0)
                                                            {
                                                                var drRow = dt.NewRow();
                                                                drRow["GID"] = GID;
                                                                drRow["ColumnID"] = colID;
                                                                drRow["Value"] = _changedValue.Value.ToText();
                                                                dt.Rows.Add(drRow);
                                                            }
                                                            
                                                        }
                                                                                                              
                                                    }
                                                }
                                            }
                                        }

                                    }
                                }
                                recordStartPosition = recordStartPosition + recordCount;
                                //totalRecord = resp
                            }

                            //now sync from phone to ptov
                            LogInfo("Synchronizing data from Phenome to PtoV started.");
                            await _germplasmService.SynchonizePhoneAsync(dt);
                            LogInfo("Synchronizing data from Phenome to PtoV completed.");

                            //update the datetime value in database
                            await _germplasmService.UpdateSyncedDateTimeAsync(crop.CropCode, crop.CurrentUTCTime);


                            LogInfo("Synchronizing data from PtoV to Varmas started.");
                            //sync from ptov to varmas
                            //var errors = new List<string>();
                            await SyncToVarmasAsync(varmasUserName, crop.CropCode, errorMessage);
                            if (errorMessage.Any())
                            {
                                //success = false;
                                continue;
                            }
                            LogInfo("Synchronizing data from PtoV to Varmas completed.");

                            #endregion
                        }
                        catch (Exception ex)
                        {
                            LogError(ex.Message);
                            errorMessage.Add(new ExecutableError
                            {
                                Success = false,
                                ErrorType = "Exception",
                                Exception = ex,
                            });
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                LogError(ex.Message);
                errorMessage.Add(new ExecutableError
                {
                    Success = false,
                    ErrorType = "Exception",
                    Exception = ex,
                });
            }
            return errorMessage;
        }

        private async Task SyncToVarmasAsync(string userName, string cropCode, List<ExecutableError> errors)
        {
            var url = ConfigurationManager.AppSettings["VarmasServiceUrl"];
            var data = await _germplasmService.GetVarmasDataToSyncAsync(cropCode);
            var batchSize = ConfigurationManager.AppSettings["BatchSize"].ToInt32();
            //set default batch size
            if (batchSize <= 0)
                batchSize = 1000;

            using (var client = new VarmasSoapClient())
            {
                //var missingTrait = new List<(string TraitName, string ColumnLabel)>();
                //var missingValue = new List<(string TraitName, string ColumnLabel)>();
                var missingConversion = new List<VarmasDataResult>();

                //group data by synccode first and process in batches
                var groups = data.GroupBy(g => g.SyncCode);
                foreach (var group in groups)
                {
                    LogInfo($"Sending data to Varmas for Sync Code: { group.Key}.");
                    var batches = group.OrderBy(x=>x.GID).BatchBy(batchSize);
                    foreach (var _batch in batches)
                    {
                        try
                        {
                            //validate data in batch
                            var invalidData = _batch.Where(o => !o.IsValid);
                            if (invalidData.Any())
                            {
                                //if screeningnr is blank than relation is missing else value is missing 
                                //var error = invalidData.Where(x => string.IsNullOrWhiteSpace(x.ScreeningFieldNr?.ToString()))
                                //    .Select(y => (y.TraitName, y.ColumnLabel))
                                //    .Distinct();
                                //missingTrait.AddRange(error);

                                //var valueError = invalidData.Where(x => !string.IsNullOrWhiteSpace(x.ScreeningFieldNr?.ToString()))
                                //    .Select(y => (y.TraitName, y.ColumnLabel))
                                //    .Distinct();
                                //missingValue.AddRange(valueError);
                                //continue;                                
                                missingConversion.AddRange(invalidData);
                            }
                            var batch = _batch.Where(o => o.IsValid);
                            if (batch.Any())
                            {
                                var germplasms = batch.GroupBy(g => new
                                {
                                    g.SyncCode,
                                    g.GID,
                                    g.VarietyNr,
                                    g.LotNumber
                                }).Select(o => new
                                {
                                    o.Key.SyncCode,
                                    o.Key.GID,
                                    o.Key.VarietyNr,
                                    o.Key.LotNumber,
                                    ScreeningFields = o.Select(x => new
                                    {
                                        x.ScreeningFieldNr,
                                        ScreeningFieldValue = SecurityElement.Escape(x.ScreeningFieldValue)
                                    }).ToList()
                                }).ToList();

                                var model = new
                                {
                                    UserName = userName,
                                    Germplasms = germplasms
                                };
                                //LogInfo($"Sending data to Varmas with batch size: {batch.Count()}");
                                var response = await client.SyncToVarmasAsync(url, model);
                                //Update status into Cell table and make Modified=0
                                if (response.EqualsIgnoreCase("Success"))
                                {
                                    var cellIDs = string.Join(",", batch.Select(x => x.CellID).ToList());
                                    await _germplasmService.UpdateModifiedData(cellIDs);
                                }
                                else if (response.StartsWith("Failure:GIDs"))
                                {
                                    var errorGIDs = "";
                                    var errorResp = response.Split('-');
                                    if (errorResp.Length > 1)
                                    {
                                        errorGIDs = errorResp[1];
                                    }
                                    var gid = batch.Select(x => x.GID.ToText());
                                    var validGIDs = gid.Except(errorGIDs.Split(','));
                                    var cellIDs = string.Join(",", (from t1 in batch
                                                                    join t2 in validGIDs on t1.GID.ToText() equals t2
                                                                    select t1.CellID).ToList());
                                    await _germplasmService.UpdateModifiedData(cellIDs);
                                    errors.Add(new ExecutableError
                                    {
                                        Success = false,
                                        CropCode = cropCode,
                                        SyncCode = group.Key,
                                        ErrorType = "data",
                                        ErrorMessage = response
                                    });
                                       
                                }
                                else
                                {
                                    throw new Exception(response);
                                }
                            }
                        }
                        catch (Exception ex)
                        {
                            LogError(ex.Message);
                            errors.Add(new ExecutableError
                            {
                                Success = false,
                                ErrorType = "Exception",
                                Exception = ex
                            });
                            
                        }
                    }
                    if(missingConversion.Any())
                    {
                        LogInfo($"conversion missing for crop {cropCode}");
                        var msg = Environment.NewLine +
                                 $"Conversion missing for crop {cropCode}:<br/>";

                        
                        //msg = msg + "Trait \t\t ScreeningField \t\t TraitValue";
                        //var groupedData = missingConversion.GroupBy(x => new { x.ColumnLabel, x.ScreeningFieldNr , x.ScreeningFieldValue}).Select(y => (y.Key.ColumnLabel, y.Key.ScreeningFieldNr, y.Key.ScreeningFieldValue)).Distinct();
                        var groupedData = missingConversion.GroupBy(x => new {x.ColumnLabel,  x.ScreeningFieldValue }).Select(y=>  y.Key).ToList();
                        bool addedHeader = false;
                        foreach(var _groupedData in groupedData)
                        {
                            if(!addedHeader)
                            {
                                //this is for table
                                msg = msg + "<table border=\"1\" cellpadding=\"0\" cellspacing=\"0\" width=\"400\">";
                                //this is for table header
                                msg = msg + @"<tr bgcolor='#C1BFBF'>
                                                    <th>Trait</th>
                                                    <th>TraitValue</th>
                                                </tr>";
                               // msg = msg + "Trait\t\t\tTraitValue <br/>";
                                addedHeader = true;
                            }
                            //now append for table data
                            msg = msg + "<tr>"+
                                            "<td>" + _groupedData.ColumnLabel + "</td>"+
                                            "<td>" + _groupedData.ScreeningFieldValue + "</td>" +
                                        "</tr>";
                            //msg = msg  + _groupedData.ColumnLabel + " \t\t\t" + _groupedData.ScreeningFieldValue + "<br/>";
                        }
                        if(!errors.Any(x=>x.ErrorMessage.EqualsIgnoreCase(msg)))
                        {
                            errors.Add(new ExecutableError
                            {
                                Success = false,
                                CropCode = cropCode,
                                SyncCode = group.Key,
                                ErrorType = "data",
                                ErrorMessage = msg
                            });
                        }
                    }
                    //if (missingTrait.Any())
                    //{
                    //    var traits = string.Join(",", missingTrait.Select(x => x.ColumnLabel).Distinct());
                    //    var msg = Environment.NewLine +
                    //        $"Relation Mapping of Trait and ScreeningNr is missing for Trait(s): ({traits})." + Environment.NewLine;
                    //    //errors.Add(msg);

                    //    //LogError($"Relation mapping missing => {string.Join(", ", missingTrait.Select(x => $"(TraitName = {x.TraitName}, ColumnLabel = {x.ColumnLabel})"))}.");

                    //    errors.Add(new ExecutableError
                    //    {
                    //        Success = false,
                    //        CropCode = cropCode,
                    //        SyncCode = group.Key,
                    //        ErrorType = "data",
                    //        ErrorMessage = msg
                    //    });
                    //}
                    //if (missingValue.Any())
                    //{
                    //    var traits = string.Join(",", missingValue.Select(x => x.ColumnLabel).Distinct());
                    //    var msg = Environment.NewLine +
                    //        $"Conversion data is missing for Trait(s): ({traits})." + Environment.NewLine;
                    //    //errors.Add(msg);

                    //    //LogError($"Conversion data missing => {string.Join(", ", missingValue.Select(x => $"(TraitName = {x.TraitName}, ColumnLabel = {x.ColumnLabel})"))}.");
                    //    errors.Add(new ExecutableError
                    //    {
                    //        Success = false,
                    //        CropCode = cropCode,
                    //        SyncCode = group.Key,
                    //        ErrorType = "data",
                    //        ErrorMessage = msg
                    //    });
                    //}
                    LogInfo($"Sending data to Varmas for Sync Code: { group.Key} completed.");
                }                
            }
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

        private async Task SendToUELAsync(Exception ex)
        {
            try
            {
                await _uelService.LogAsync(ex);
            }
            catch (Exception innerEx)
            {
                //log it to file if cordys UEL service throws any exception
                _logger.Error(innerEx);
            }
        }

        private async Task<HttpResponseMessage> SignInAsync(RestClient client)
        {
            var ssoEnabled = ConfigurationManager.AppSettings["SSO:Enabled"].ToBoolean();
            if (!ssoEnabled)
            {
                var (UserName, Password) = Credentials.GetCredentials("SyncPhenomeCredentials");
                return await client.PostAsync("/login_do", values =>
                {
                    values.Add("username", UserName);
                    values.Add("password", Password);
                });
            }
            else
            {
                var phenome = new PhenomeSSOClient();
                return await phenome.SignInAsync(client);
            }
        }

    }
}
