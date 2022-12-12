using Enza.PtoV.BusinessAccess.Interfaces;
using Enza.PtoV.Common.Extensions;
using Enza.PtoV.DataAccess.Data.Interfaces;
using Enza.PtoV.Entities;
using Enza.PtoV.Entities.Results;
using Enza.PtoV.Entities.VtoP;
using Enza.PtoV.Services.Abstract;
using log4net;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;

namespace Enza.PtoV.BusinessAccess.Services
{
    public class ENumberSyncService : IENumberSyncService
    {
        private readonly IENumberSyncRepository _eNumberSyncRepository;
        private readonly string _basePhenomeServiceUrl = ConfigurationManager.AppSettings["BasePhenomeServiceUrl"];
        private static readonly ILog _logger =
            LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);
        public ENumberSyncService(IENumberSyncRepository eNumberSyncRepository)
        {
            _eNumberSyncRepository = eNumberSyncRepository;
        }
        public async Task<List<ExecutableError>> SynchronizeAsync()
        {
            var rgIDS = new List<int>();
            var errorMessage = new List<ExecutableError>();
            try
            {
                string[] format = { "dd/MM/yy HH:mm:ss", "dd/MM/yyyy HH:mm:ss,fff" };
                //var success = true;
                var varietySyncLogs = await _eNumberSyncRepository.GetVarmasVarietySyncLogsAsync();
                if (varietySyncLogs.Any())
                {
                    var getStatusDetail = await _eNumberSyncRepository.GetStatusDetailAsync();
                    var userName = ConfigurationManager.AppSettings["VarmsUserName"];
                    using (var phenomeClient = new RestClient(_basePhenomeServiceUrl))
                    {
                        //sign to phenome
                        await _eNumberSyncRepository.SignInToPhenomeAsync(phenomeClient);

                        //get e-number
                        var getENumber = new Func<PtoV.Services.Proxies.VtoPSyncClient.VarietyInfo, string>(o =>
                        {
                            if (o == null)
                                return string.Empty;
                            var item = o.ProgramFields.FirstOrDefault(x => x.ProgramFieldCode.EqualsIgnoreCase("vvarc_enumber"));
                            if (item == null)
                                return string.Empty;
                            return item.ProgramFieldValue;

                        });

                        //get variety 
                        var getVarietyName = new Func<PtoV.Services.Proxies.VtoPSyncClient.VarietyInfo, string>(o =>
                        {
                            if (o == null)
                                return string.Empty;
                            var item = o.ProgramFields.FirstOrDefault(x => x.ProgramFieldCode.EqualsIgnoreCase("vvarc_shortname"));
                            if (item == null)
                                return string.Empty;
                            return item.ProgramFieldValue;
                        });

                        var getVarietyStatus = new Func<PtoV.Services.Proxies.VtoPSyncClient.VarietyInfo, string>(o =>
                        {
                            if (o == null)
                                return string.Empty;
                            var item = o.ProgramFields.FirstOrDefault(x => x.ProgramFieldCode.EqualsIgnoreCase("status"));
                            if (item == null)
                                return string.Empty;
                            return item.ProgramFieldValue;
                        });

                        var getLotNumber = new Func<PtoV.Services.Proxies.VtoPSyncClient.VarietyInfo, string>(o =>
                        {
                            if (o == null)
                                return string.Empty;
                            var item = o.ProgramFields.FirstOrDefault(x => x.ProgramFieldCode.EqualsIgnoreCase("blotn_lotnum"));
                            if (item == null)
                                return string.Empty;
                            return item.ProgramFieldValue;
                        });

                        var getGenerationCode = new Func<PtoV.Services.Proxies.VtoPSyncClient.VarietyInfo, string>(o =>
                        {
                            if (o == null)
                                return string.Empty;
                            var item = o.ProgramFields.FirstOrDefault(x => x.ProgramFieldCode.EqualsIgnoreCase("bgenc_genercod"));
                            if (item == null)
                                return string.Empty;
                            return item.ProgramFieldValue;
                        });

                        var getVarmasStatus = new Func<PtoV.Services.Proxies.VtoPSyncClient.VarietyInfo, string>(o =>
                        {
                            var item = o.ProgramFields.FirstOrDefault(x => x.ProgramFieldCode.EqualsIgnoreCase("xstac"));
                            if (item == null)
                                return string.Empty;
                            return item.ProgramFieldValue;
                        });


                        //process local changed data to phenome (sync changed variety of ptov to phenome).
                        foreach(var vLog in varietySyncLogs)
                        {
                            try
                            {
                                //get variety information based on sync code and crop code to sync to Phenome
                                var logs = await _eNumberSyncRepository.GetVarietyLogsAsync(vLog.SyncCode, vLog.CropCode);

                                //sync normal variety which is available on ptoV variety table
                                LogInfo($"Sync data to phenome for changed variety for CropCode {vLog.CropCode} and SyncCode {vLog.SyncCode}.");
                                var requiredColumns = new List<string>();
                                requiredColumns.Add("Gen");
                                var UploadToPhenomeResponse = await UpdateVarietydataToPhenome(phenomeClient, logs, errorMessage, requiredColumns);
                                if (!UploadToPhenomeResponse)
                                {
                                    _logger.Error($"Something went wrong while syncing data to phenome");
                                    continue;
                                }

                                //get researchGroup and apply lock
                                var researchGroup = await _eNumberSyncRepository.GetResearchGroupObjectID(vLog.CropCode);
                                if (researchGroup.Any())
                                {
                                    var rgID = researchGroup.FirstOrDefault().ObjectID;
                                    if (rgID > 0)
                                    {
                                        LogInfo($"RGID for CropCode { vLog.CropCode} found with value {rgID}");
                                        var variables = new List<string>()
                                                    {
                                                        "E-number",
                                                        "Variety",
                                                        "VrStagVc",
                                                        "Gen",
                                                        "Pedigree",
                                                        "GenebankNr"
                                                    };

                                        await _eNumberSyncRepository.ApplyLockVariablesAsync(phenomeClient, rgID, variables, "Lock");
                                    }
                                    else
                                    {
                                        LogInfo($"RGID for CropCode { vLog.CropCode} not found");
                                    }
                                }
                            }
                            catch (Exception ex)
                            {
                                LogError(ex);
                                errorMessage.Add(new ExecutableError
                                {
                                    Success = false,
                                    ErrorType = "exception",
                                    Exception = ex

                                });
                            }
                            
                        }


                        //process data for each sync code.
                        foreach (var vLog in varietySyncLogs)
                        {
                            try
                            {
                                var synchedTime = DateTime.ParseExact(vLog.VarSychedTime, format, CultureInfo.InvariantCulture, DateTimeStyles.None).ToString(format.FirstOrDefault());
                                LogInfo($"Fetching data for sync code: {vLog.SyncCode} and CropCode {vLog.CropCode} for time stamp {synchedTime}");
                                
                                //get varieties data from varmas service based on crop code, sync code and timestamp
                                var response = await _eNumberSyncRepository.GetVarmasVarietiesAsync(new VarmasVarietiesArgs
                                {
                                    UserName = userName,
                                    SyncCode = vLog.SyncCode,
                                    Timestamp = synchedTime,
                                    Crop = vLog.CropCode,
                                    VarietyNr = 0, //always send value 0 on initial call (this will have real value when requested timestamp is equal to timestamp we receive from response
                                    RequestedData = "vvarc_shortname,vvarc_enumber,blotn_lotnum,vcroc_cropcod,xstac,status,bgenc_genercod,vvarc_stbdescr,vvarc_genenumber"
                                });
                                if (response.Varieties.Any())
                                {
                                    while (response.Varieties.Any())
                                    {
                                        LogInfo($"Data received with last sync time {response.Timestamp}");
                                        

                                        //Update Enumbers to PtoV database before synching to Phenome
                                        var data = response.Varieties.Select(o => new
                                        {
                                            VNr = o.VarietyNr,
                                            ENr = getENumber(o),
                                            VName = getVarietyName(o),
                                            VStatus = getVarietyStatus(o), //this is variety status indicating active or inactive (INAC / ACT)
                                            VarmasStatus = getVarmasStatus(o), //Varmas returns statusName in response.
                                            LotNr = getLotNumber(o)
                                        }).Where(o => !string.IsNullOrWhiteSpace(o.ENr))
                                        .ToList();

                                        //update variety information (e-number and variety name, status, generation) into Variety table in PtoV
                                        var dataAsJson = data.Serialize();
                                        await _eNumberSyncRepository.UpdateVarietyENumbersAsnyc(dataAsJson);


                                        //now change syncTime to which was originally we recieved from database, change it from db value to response we get from service.
                                        synchedTime = response.Timestamp;
                                        bool UploadToPhenomeResponse = false;


                                        //get variety information based on sync code and crop code to sync to Phenome
                                        var logs = await _eNumberSyncRepository.GetVarietyLogsAsync(vLog.SyncCode, vLog.CropCode);

                                        //sync normal variety which is available on ptoV variety table
                                        LogInfo($"Sync data to phenome for changed variety that is saved in PtoV database.");
                                        var additionalColumns = new List<string>();
                                        additionalColumns.Add("Gen");
                                        UploadToPhenomeResponse = await UpdateVarietydataToPhenome(phenomeClient, logs, errorMessage, additionalColumns);
                                        if (!UploadToPhenomeResponse)
                                        {
                                            _logger.Error($"Something went wrong while syncing data to phenome");
                                            response.Varieties.Clear();
                                            continue;
                                        }

                                        // Sync data for external Lots : They has no Variety record but only RelationPtoV record
                                        //Get VarietyNr list from response
                                        var varietyNrList = string.Join(",", response.Varieties.Select(o => o.VarietyNr));

                                        //Get GID and other detail from database to upload to phenome.
                                        var varietyLogs = await _eNumberSyncRepository.GetVarietyLogsForVarietyAsync(varietyNrList, vLog.SyncCode, vLog.CropCode);

                                        if (varietyLogs.Any())
                                        {
                                            LogInfo($"Sync data to phenome for changed (external) variety.");
                                            var exVarList = varietyLogs.Where(x => !logs.Any(y => y.GID == x.GID)).Select(o => new Entities.Results.VarietyLogResult
                                            {
                                                GID = o.GID,
                                                CropCode = vLog.CropCode,
                                                ObjectID = o.ObjectID,
                                                ObjectType = o.ObjectType,
                                                ENumber = getENumber(response.Varieties.FirstOrDefault(p => p.VarietyNr == o.VarietyNr)),
                                                VarietyName = getVarietyName(response.Varieties.FirstOrDefault(p => p.VarietyNr == o.VarietyNr)),
                                                VarmasVarietyStatus = getStatusDetail.FirstOrDefault(x => x.StatusName.EqualsIgnoreCase(getVarmasStatus(response.Varieties.FirstOrDefault(p => p.VarietyNr == o.VarietyNr))) && x.StatusTable.EqualsIgnoreCase("VarmasStatus"))?.StatusDescription, // variety response returns the name ,
                                                ProgramFieldData = response.Varieties.FirstOrDefault(x => x.VarietyNr == o.VarietyNr).ProgramFields.Select(x=>new Entities.Results.ProgramField { ProgramFieldCode = x.ProgramFieldCode, ProgramFieldValue = x.ProgramFieldValue}).ToList()

                                            });
                                            if (exVarList.Any())
                                            {
                                                var requiredColumns = new List<string>()
                                                {
                                                    "Variety",
                                                    "Pedigree",
                                                    "PedigrAbbr",
                                                    "GenebankNr",
                                                    "Gen"
                                                };                                                

                                                UploadToPhenomeResponse = await UpdateVarietydataToPhenome(phenomeClient, exVarList, errorMessage, requiredColumns);
                                                if (!UploadToPhenomeResponse)
                                                {
                                                    _logger.Error($"Something went wrong while syncing data to phenome");
                                                    response.Varieties.Clear();
                                                    continue;
                                                }
                                            }
                                        }
                                        var varietyNr = 0;
                                        //update synctime only when datetime received from service response is different.
                                        if (DateTime.ParseExact(vLog.VarSychedTime, format, CultureInfo.InvariantCulture, DateTimeStyles.None) == DateTime.ParseExact(synchedTime, format, CultureInfo.InvariantCulture, DateTimeStyles.None))
                                        {
                                            varietyNr = response.Varieties.Max(x => x.VarietyNr);
                                        }

                                        //update timeStamp
                                        LogInfo($"Updating timestamp for sync code: {vLog.SyncCode} and CropCode {vLog.CropCode} with time stamp {response.Timestamp} ");
                                        await _eNumberSyncRepository.UpdateSyncedTimestampAsync(vLog.CropCode, vLog.SyncCode, response.Timestamp);

                                        vLog.VarSychedTime = response.Timestamp;

                                        //clear earlier response
                                        response.Varieties.Clear();

                                        LogInfo($"Fetching data for sync code: {vLog.SyncCode} and CropCode {vLog.CropCode} for time stamp {synchedTime} with varietyNr {varietyNr}");
                                        response = await _eNumberSyncRepository.GetVarmasVarietiesAsync(new VarmasVarietiesArgs
                                        {
                                            UserName = userName,
                                            SyncCode = vLog.SyncCode,
                                            Timestamp = synchedTime,
                                            Crop = vLog.CropCode,
                                            VarietyNr = varietyNr,
                                            RequestedData = "vvarc_shortname,vvarc_enumber,blotn_lotnum,vcroc_cropcod,xstac,status,bgenc_genercod,vvarc_stbdescr,vvarc_genenumber"
                                        });

                                        if (!response.Varieties.Any())
                                        {
                                            //get researchGroup and apply lock
                                            var researchGroup = await _eNumberSyncRepository.GetResearchGroupObjectID(vLog.CropCode);
                                            if (researchGroup.Any())
                                            {
                                                var rgID = researchGroup.FirstOrDefault().ObjectID;
                                                if (rgID > 0)
                                                {
                                                    LogInfo($"RGID for CropCode { vLog.CropCode} found with value {rgID}");
                                                    var variables = new List<string>()
                                                    {
                                                        "E-number",
                                                        "Variety",
                                                        "VrStagVc",
                                                        "Gen",
                                                        "Pedigree",
                                                        "GenebankNr"
                                                    };                                                    
                                                    await _eNumberSyncRepository.ApplyLockVariablesAsync(phenomeClient, rgID, variables, "Lock");
                                                }
                                                else
                                                {
                                                    LogInfo($"RGID for CropCode { vLog.CropCode} not found");
                                                }
                                            }
                                        }
                                        
                                    }
                                }
                                else
                                {
                                    LogInfo($"Updating timestamp for sync code: {vLog.SyncCode} and CropCode {vLog.CropCode} with time stamp {response.Timestamp} ");
                                    await _eNumberSyncRepository.UpdateSyncedTimestampAsync(vLog.CropCode, vLog.SyncCode, response.Timestamp);
                                }
                                

                            }
                            catch (Exception ex)
                            {
                                LogError(ex);
                                errorMessage.Add(new ExecutableError
                                {
                                    Success = false,
                                    ErrorType = "exception",
                                    Exception = ex

                                });
                            }

                        }
                    }

                }
            }
            catch(Exception e)
            {
                LogError(e);
                errorMessage.Add(new ExecutableError
                {
                    Success = false,
                    ErrorType = "Exception",
                    Exception = e,
                });
            }
            //return success;
            return errorMessage;
        }


        private async Task<bool> UpdateVarietydataToPhenome(RestClient phenomeClient, IEnumerable<Entities.Results.VarietyLogResult> varietiesToSync, List<ExecutableError> errorMessage, List<string> requiredExtraColumns)
        {
            try
            {
                if (varietiesToSync.Any())
                {
                    var researchGroup = varietiesToSync.FirstOrDefault(x=>x.ObjectID > 0);
                    if (researchGroup ==null)
                    {
                        _logger.Error("Invalid Research group ID");
                        errorMessage.Add(new ExecutableError
                        {
                            Success = false,
                            CropCode = varietiesToSync.FirstOrDefault().CropCode,
                            ErrorType = "data",
                            ErrorMessage = "Invalid Research group ID."

                        });
                        return false;
                    }
                    var group = varietiesToSync.FirstOrDefault();

                    var germplasmColumns = await _eNumberSyncRepository.GetGermplasmColumnsAsync(phenomeClient,
                        group.ObjectType, group.ObjectID);
                    
                    //E-number 
                    var eNumberColumn = germplasmColumns.FirstOrDefault(o => o.desc.EqualsIgnoreCase("E-Number"));
                    if (eNumberColumn == null)
                    {
                        _logger.Error("Couldn't find E-number column in phenome.");
                        errorMessage.Add(new ExecutableError
                        {
                            Success = false,
                            CropCode = group.CropCode,
                            ErrorType = "data",
                            ErrorMessage = "Couldn't find E-number column in phenome."

                        });
                        return false;
                    }
                    //variety
                    var varietyNameColumn = germplasmColumns.FirstOrDefault(o => o.desc.EqualsIgnoreCase("Variety"));
                    if (varietyNameColumn == null)
                    {
                        _logger.Error("Couldn't find Variety column in phenome.");
                        errorMessage.Add(new ExecutableError
                        {
                            Success = false,
                            CropCode = group.CropCode,
                            ErrorType = "data",
                            ErrorMessage = "Couldn't find Variety column in phenome."

                        });
                        return false;
                    }
                    //variety Status
                    var varietyStatusColumn = germplasmColumns.FirstOrDefault(o => o.desc.EqualsIgnoreCase("VrStagVc"));
                    if(varietyStatusColumn == null)
                    {
                        _logger.Error("Couldn't find VrStagVc column in phenome.");
                        errorMessage.Add(new ExecutableError
                        {
                            Success = false,
                            CropCode = group.CropCode,
                            ErrorType = "data",
                            ErrorMessage = "Couldn't find VrStagVc column in phenome."

                        });
                        return false;
                    
                    }

                   

                    if (requiredExtraColumns.Any())
                    {
                        foreach (var _col in requiredExtraColumns)
                        {
                            var foundColumn = germplasmColumns.FirstOrDefault(o => o.desc.EqualsIgnoreCase(_col));
                            if (foundColumn == null)
                            {
                                _logger.Error($"Couldn't find {_col} column in phenome.");
                                errorMessage.Add(new ExecutableError
                                {
                                    Success = false,
                                    CropCode = group.CropCode,
                                    ErrorType = "data",
                                    ErrorMessage = $"Couldn't find {_col} column in phenome."

                                });
                                return false;
                            }
                        }
                    }

                    var mappedCols = await GetMappedColumnsAsync();
                    var dictValues = new Dictionary<string, string>();
                    foreach (var log in varietiesToSync)
                    {
                        //just get short code instead of description. eg: if 'R2 research 2' is desc just send 'R2' to phenome.                        
                        if(!string.IsNullOrWhiteSpace(log.VarmasVarietyStatus))
                        {
                            var statusDesc = log.VarmasVarietyStatus.Split(' ');
                            dictValues[varietyStatusColumn.id] = statusDesc.ElementAtOrDefault(0); ;
                        }
                        dictValues[eNumberColumn.id] = log.ENumber;
                        dictValues[varietyNameColumn.id] = log.VarietyName;
                        

                        //if extra column is there update the value too
                        if (requiredExtraColumns.Any())
                        {
                            var columnValues = GetColumnValues(log, mappedCols);

                            var columns = (from t1 in mappedCols
                                           join t2 in germplasmColumns on t1.PColumnName.ToText().ToLower() equals t2.desc.ToText().ToLower()
                                           join t3 in columnValues on t1.PColumnName.ToText().ToLower() equals t3.Key.ToText().ToLower()
                                           select new
                                           {
                                               t2.id,
                                               ColumnValue = t3.Value
                                           });   
                            foreach(var _columns in columns)
                            {
                                dictValues[_columns.id] = _columns.ColumnValue;
                            }
                        }


                        var args = new UpdateGermplasmDataArgs
                        {
                            ObjectType = log.ObjectType,
                            ObjectID = log.ObjectID,
                            GID = log.GID,
                            Values = dictValues
                            //Values = new Dictionary<string, string>
                            //                            {
                            //                                { eNumberColumn.id, log.ENumber },
                            //                                { varietyNameColumn.id, log.VarietyName },
                            //                                { varietyStatusColumn.id, varmasStatusDesc}
                            //                            }
                        };
                        await _eNumberSyncRepository.UpdateGermplasmDataAsync(phenomeClient, args);
                        //change variety status to 200 once E-Number and variety name column is synced to Phenome
                        await _eNumberSyncRepository.UpdateVarietyStatusAsync(log.VarietyID);
                    }
                }
                
            }
            catch(Exception e)
            {
                LogError(e);
                errorMessage.Add(new ExecutableError
                {
                    Success = false,
                    ErrorType = "Exception",
                    Exception = e,
                });
                return false;

            }
            return true;

        }

        //this method is used to get additional column which is not available in ptov database.
        public Task<List<VtoPColumnMapping>> GetMappedColumnsAsync()
        {
            var result = new List<VtoPColumnMapping>
            {
                
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

        private Dictionary<string, string> GetColumnValues(VarietyLogResult data, List<VtoPColumnMapping> mappedCols)
        {
            var values = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (var mappedCol in mappedCols)
            {
                var columnValue = data.ProgramFieldData.FirstOrDefault(o => o.ProgramFieldCode.EqualsIgnoreCase(mappedCol.VColumnName));
                values.Add(mappedCol.PColumnName, columnValue != null ? columnValue.ProgramFieldValue : string.Empty);
            }
            return values;
        }
        private void LogError(Exception msg)
        {
            Console.WriteLine(msg.Message);
            _logger.Error(msg);
        }

        private void LogInfo(string msg)
        {
            Console.WriteLine(msg);
            _logger.Info(msg);
        }
    }
}
