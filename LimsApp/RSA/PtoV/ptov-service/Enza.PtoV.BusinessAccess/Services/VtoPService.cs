using Enza.PtoV.BusinessAccess.Interfaces;
using Enza.PtoV.Common.Extensions;
using Enza.PtoV.DataAccess.Data.Interfaces;
using Enza.PtoV.Entities;
using Enza.PtoV.Entities.Results;
using Enza.PtoV.Entities.VtoP;
using Enza.PtoV.Services.Abstract;
using Enza.PtoV.Services.Proxies;
using log4net;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;

namespace Enza.PtoV.BusinessAccess.Services
{
    public class VtoPService : IVtoPService
    {
        private readonly IVtoPRepository _vtoPRepository;
        private readonly IPhenomeServiceRespsitory _phenomeRepository;
        private string _basePhenomeServiceUrl = ConfigurationManager.AppSettings["BasePhenomeServiceUrl"];
        private static readonly ILog _logger =
            LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);
        public VtoPService(IVtoPRepository vtoPRepository,IPhenomeServiceRespsitory phenomeServiceRespsitory)
        {
            _vtoPRepository = vtoPRepository;
            _phenomeRepository = phenomeServiceRespsitory;
        }
        public async Task<List<ExecutableError>> VtoPSynchronizeAsync()
        {
            var errorMessage = new List<ExecutableError>();
            try
            {
                //var success = true;
                var getData = true;
                //all syncronization logic goes here
                LogInfo($"Get configuration of migrated data per crop per sync code started.");
                var logs = await _vtoPRepository.GetSyncConfigsAsync();
                LogInfo($"Fetched sync configuration");
                var researchGroupDictionary = new Dictionary<string, int>();
                var methodCodeperCrop = new Dictionary<string, string>();
                if (logs.Any())
                {
                    getData = true;
                    const string absLot = "abs";
                    var userName = ConfigurationManager.AppSettings["VarmsUserName"];

                    using (var phenomeClient = new RestClient(_basePhenomeServiceUrl))
                    {
                        //sign to phenome                    
                        await _phenomeRepository.SignInToPhenomeAsync(phenomeClient);
                        foreach (var log in logs)
                        {
                            try
                            {
                                getData = true;
                                var researchGroupID = 0;
                                var selfingMethodCode = "";
                                if (!researchGroupDictionary.ContainsKey(log.CropCode))
                                {
                                    LogInfo($"Get Research group ID for Crop {log.CropCode} using API.");
                                    LogInfo($"/api/v1/entity/basecontainer/getPermissions/{log.ABSLotFolderID}");
                                    var url = $"/api/v1/entity/basecontainer/getPermissions/{log.ABSLotFolderID}";
                                    //var url = $"/api/v1/tree/baseobjectnavigator/get_node/m?id={log.ABSLotFolderID}";
                                    var treedata = await phenomeClient.GetAsync(url);
                                    await treedata.EnsureSuccessStatusCodeAsync();
                                    var rs = await treedata.Content.ReadAsStringAsync();

                                    var json = JsonConvert.DeserializeObject<PhenomePermissionsResult>(rs);
                                    researchGroupID = json.Permissions.RGID.ToInt32();
                                    LogInfo($"Research group ID for Crop {log.CropCode} is {researchGroupID}");
                                    researchGroupDictionary[log.CropCode] = researchGroupID;

                                    if (researchGroupID <= 0)
                                    {
                                        //LogError($"Research Group ID not found to create Inventory for Crop {log.CropCode} and Sync code {log.SyncCode}.");
                                        //success = false;
                                        errorMessage.Add(new ExecutableError
                                        {
                                            Success = false,
                                            CropCode = log.CropCode,
                                            SyncCode = log.SyncCode,
                                            ErrorType = "data",
                                            ErrorMessage = $"Research Group ID not found to create Inventory for Crop {log.CropCode} and Sync code {log.SyncCode}."

                                        });
                                        getData = false;
                                        break;
                                    }
                                }
                                else
                                    researchGroupID = researchGroupDictionary[log.CropCode];

                                

                                var objectType = 4; // for research group level value is 5 and for folder level value is 4  eg: breeding,NL,FR                         

                                LogInfo($"Get data from Varmas for CropCode {log.CropCode} and Sync Code: {log.SyncCode} with LotNr {log.LotNr}");

                                var varmasLots = await _vtoPRepository.GetVarmasLotsAndVarietiesAsync(new VarmasLotsAndVarietiesArgs
                                {
                                    UserName = userName,
                                    CropCode = log.CropCode,
                                    SyncCode = log.SyncCode,
                                    LotNr = log.LotNr,
                                    RequestedData = "GB,TH,ABS"
                                });
                                if (!varmasLots.Any())
                                {
                                    LogInfo($"Crop Code: {log.CropCode}, Sync Code: {log.SyncCode} => There is no data to process.");
                                    continue;
                                }
                                //get columns of inventories from phenome
                                var inventoryColumns = await _vtoPRepository.GetInventoryLotColumnsAsync(phenomeClient, objectType, log.ABSLotFolderID);

                                //get germplasm columns
                               

                                //get column details to load data 
                                var invCols = new[] { "GID", "Lotnr" };
                                var columnsToLoad = inventoryColumns
                                    .Where(o => invCols.Contains(o.desc, StringComparer.OrdinalIgnoreCase))
                                    .ToList();
                                LogInfo($"Get Mapped column");
                                var mappedCols = await _vtoPRepository.GetMappedColumnsAsync();
                                var syncLogs = new List<ExternalLotInfo>();
                                var gridID = "";

                                while (varmasLots.Any())
                                {
                                    getData = true;
                                    LogInfo($"Data received from Varmas.");  
                                    //sort data based on lotnr because LotNr is the key for tracking sync log.
                                    varmasLots = varmasLots.OrderBy(o => o.LotNr).ToList();
                                    var UpdateToVarmas = false;

                                    //prepare data for phenome
                                    foreach (var varmasLot in varmasLots)
                                    {
                                        syncLogs.Clear();
                                        var ABSLot = new VarietyWithLot();
                                        int folderID = log.ABSLotFolderID;

                                        LogInfo($"LotNr:{varmasLot.LotNr}, Status: {varmasLot.OriginLotSeedStatus}, LotRef: {varmasLot.LotReference}, lottype: {varmasLot.LotType}, OriginLotNr: {varmasLot.OriginLot}, PhenomeGID: {varmasLot.PhenomeGID}, VarietyNr: {varmasLot.VarietyNr}");
                                        
                                        //get phenomeGID from either varietyNr or from originLot
                                        
                                        if (varmasLot.LotType.EqualsIgnoreCase(absLot))
                                        {
                                            #region get method code for creating new gid using selfing method
                                            //this code runs only once to fetch method code
                                            //now get method code
                                            if (!methodCodeperCrop.ContainsKey(log.CropCode))
                                            {
                                                var getMethodURL = $"/api/v2/germplasm/methods/get?rgId={researchGroupID}&methodType=DER";
                                                var methodResp = await phenomeClient.GetAsync(getMethodURL);
                                                await methodResp.EnsureSuccessStatusCodeAsync();
                                                var selfing = "Selfing";
                                                var methodRespContent = JsonConvert.DeserializeObject<GetMethodResult>(await methodResp.Content.ReadAsStringAsync());
                                                if (methodRespContent.Success)
                                                { 
                                                    selfingMethodCode = methodRespContent.Combo.FirstOrDefault(x => x.Label.EqualsIgnoreCase(selfing))?.Value;
                                                    if(!string.IsNullOrWhiteSpace(selfingMethodCode))
                                                    {
                                                        methodCodeperCrop[log.CropCode] = selfingMethodCode;
                                                    }
                                                    else
                                                    {
                                                        throw new Exception("Selfing method not found");
                                                    }
                                                }
                                                else
                                                {
                                                    throw new Exception("Invalid response of get method for selfing.");
                                                }

                                                //get columns and add required column only once
                                                LogInfo($"Get Columns from Phenome for field {log.SelfingFieldSetID}");
                                                var setGridURL = "/api/v1/simplegrid/grid/create/FieldSelections";
                                                gridID = new Random().Next(10000000, 99999999).ToText();
                                                var columnsResp = await PrepareFilterGrid(phenomeClient, setGridURL, log.SelfingFieldSetID.ToText(), gridID, "{}", "28");

                                                LogInfo($"Set required Columns from Phenome for field {log.SelfingFieldSetID}");
                                                var requiredColumns = new List<string>();
                                                requiredColumns.Add("gid");
                                                requiredColumns.Add("name");
                                                var setOrderURL = "/api/v2/fieldentity/columns/set_order";
                                                var keyvalues = new List<Tuple<string, string>>();
                                                //add column if not added earlier
                                                var addColumnsResp = await AddColumns(phenomeClient, setOrderURL, keyvalues, requiredColumns, columnsResp, log.SelfingFieldSetID.ToText(), "6");
                                                if (!addColumnsResp)
                                                {
                                                    LogError($"Unable to set column in selection grid on fieldID: {log.SelfingFieldSetID}");
                                                    throw new Exception($"Unable to set column in selection grid on fieldID: {log.SelfingFieldSetID}");
                                                }
                                            }
                                            else
                                                selfingMethodCode = methodCodeperCrop[log.CropCode];

                                            #endregion
                                            var RecordNotFoundErrorMsg = "";

                                            if(varmasLot.OriginLot > 0 && log.HasOp)
                                            {
                                                //now get GID from originLot
                                                ABSLot = await _vtoPRepository.GetGIDDetailFromLotNrAsync(varmasLot.OriginLot);
                                                RecordNotFoundErrorMsg = $"Record not found in lotTable for ABS lot with Originlot {varmasLot.OriginLot}";
                                            }
                                            else if(varmasLot.PhenomeGID > 0)
                                            {
                                                //get gid from gid sent in response
                                                ABSLot = await _vtoPRepository.GetGIDDetailFromPhenomeGIDAsync(varmasLot.PhenomeGID);
                                                RecordNotFoundErrorMsg = $"Record not found in lotTable for ABS lot with phenomeGID {varmasLot.PhenomeGID}";
                                            }
                                            else
                                            {
                                                //get gid from varietyNr async
                                                ABSLot = await _vtoPRepository.GetGIDDetailFromVarietyNrAsync(varmasLot.VarietyNr);
                                                RecordNotFoundErrorMsg = $"Record not found in RelationPtoV for ABS lot with varietyNr {varmasLot.VarietyNr}";
                                            }
                                            if (ABSLot ==null)
                                            {
                                                throw new Exception(RecordNotFoundErrorMsg);
                                            }
                                            //selfing is done only for ABS lot and OP crops
                                            if (ABSLot.NewGID <=0  && varmasLot.OriginLotSeedStatus.EqualsIgnoreCase("bs") && log.HasOp)
                                            {
                                                varmasLot.PhenomeGID = ABSLot.BaseGID;                                                
                                                //create new selfing record and get newly created GID in the list
                                                var newRecord = await CreateSelfing(log.SelfingFieldSetID,ABSLot.BaseGID, phenomeClient, selfingMethodCode, researchGroupID, columnsToLoad,gridID);
                                                //update inventory record here 
                                                if (!string.IsNullOrWhiteSpace(newRecord.Item2))
                                                {
                                                    var notMappedValues = new Dictionary<string, string>
                                                    {
                                                        {"Lotnr", varmasLot.LotReference.ToString() }
                                                    };
                                                    await _vtoPRepository.UpdateInventoryLotAsync(phenomeClient, newRecord.Item2, objectType, mappedCols,
                                                    inventoryColumns, varmasLot, notMappedValues);

                                                    //maintain log for succeeded calls
                                                    syncLogs.Add(new ExternalLotInfo
                                                    {
                                                        LotNr = varmasLot.LotNr,
                                                        VarietyNr = varmasLot.VarietyNr,
                                                        PhenomeGID = ABSLot.BaseGID.ToText(),
                                                        PhenomeLotNr = newRecord.Item2,
                                                        NewGID = newRecord.Item1
                                                    });
                                                }
                                                else
                                                {
                                                    LogInfo($"no lot id found.");
                                                }
                                            }
                                            else
                                            {                                                
                                                var GIDForLot = 0;
                                                if (ABSLot.NewGID <= 0)
                                                {
                                                    GIDForLot = ABSLot.BaseGID;
                                                }
                                                else
                                                    GIDForLot = ABSLot.NewGID;

                                                varmasLot.PhenomeGID = GIDForLot;
                                                var mappedcolForInventory = mappedCols.Where(x => x.TableName.EqualsIgnoreCase("lot")).ToList();
                                                // check if lot record is already created or not
                                                //get inventory lot record
                                                LogInfo($"Get inventory lot for GID: {GIDForLot} and LotReference {varmasLot.LotReference}");
                                                var phenomeLot = await _vtoPRepository.GetInventoryLotAsync(phenomeClient, GIDForLot,
                                                varmasLot.LotReference, folderID, columnsToLoad, objectType.ToText());
                                                var lotID = "";
                                                //create lot if not created yet with reference attribute
                                                if (phenomeLot == null)
                                                {
                                                    phenomeLot = new InventoryLotResult
                                                    {
                                                        GID = varmasLot.PhenomeGID.ToText()
                                                    };                                                    
                                                    LogInfo($"Creating Inventory for GID: {GIDForLot} , LotNr: {varmasLot.LotNr} and LotReference: {varmasLot.LotReference}.");

                                                    //phenomeLot.LotID = await _vtoPRepository.CreateInventoryLotAsync(phenomeClient, researchGroupID, GIDForLot.ToText(), mappedcolForInventory);
                                                    lotID = await _vtoPRepository.CreateInventoryLotAsync(phenomeClient, researchGroupID, GIDForLot.ToText(), mappedcolForInventory);
                                                }
                                                else
                                                {
                                                    lotID = phenomeLot.LotID;
                                                }                                                
                                                //update inventory record here 
                                                if (!string.IsNullOrWhiteSpace(lotID))
                                                {
                                                    var notMappedValues = new Dictionary<string, string>
                                                    {
                                                        {"Lotnr", varmasLot.LotReference.ToString() }
                                                    };
                                                    await _vtoPRepository.UpdateInventoryLotAsync(phenomeClient, lotID, objectType, mappedCols,
                                                    inventoryColumns, varmasLot, notMappedValues);

                                                    //maintain log for succeeded calls
                                                    syncLogs.Add(new ExternalLotInfo
                                                    {
                                                        LotNr = varmasLot.LotNr,
                                                        VarietyNr = varmasLot.VarietyNr,
                                                        PhenomeGID = ABSLot.BaseGID.ToText(),
                                                        PhenomeLotNr = lotID,
                                                        NewGID = ABSLot.NewGID.ToText()
                                                    });
                                                }
                                            }
                                        }
                                        else
                                        {
                                            //get gid from vareitynr if lottype is not abs or crop is not OP
                                            if (varmasLot.PhenomeGID <= 0)
                                                varmasLot.PhenomeGID = await _vtoPRepository.GetPhenomeGIDFromVarietyNrAsync(varmasLot.VarietyNr);
                                        }


                                        if (varmasLot.LotType.EqualsIgnoreCase(absLot) && varmasLot.PhenomeGID <= 0)
                                        {

                                            LogError($"Germplasm not found on PtoV relation table to create Inventory on phenome of ABS lot for VarietyNr: {varmasLot.VarietyNr}.");
                                            //success = false;
                                            errorMessage.Add(new ExecutableError
                                            {
                                                Success = false,
                                                CropCode = log.CropCode,
                                                SyncCode = log.SyncCode,
                                                ErrorType = "data",
                                                ErrorMessage = $"Germplasm not found on PtoV relation table to create Inventory on phenome of ABS lot for VarietyNr: { varmasLot.VarietyNr}."

                                            });
                                            getData = false;
                                            break;
                                        }
                                        //if (varmasLot.LotType.EqualsIgnoreCase(absLot) || (!varmasLot.LotType.EqualsIgnoreCase(absLot) && varmasLot.PhenomeGID > 0))
                                        else if (varmasLot.PhenomeGID > 0 && !varmasLot.LotType.EqualsIgnoreCase(absLot))
                                        {
                                            UpdateToVarmas = false;
                                            LogInfo($"GID {varmasLot.PhenomeGID} found for VarietyNr : {varmasLot.VarietyNr}.");

                                            //get inventory lot record
                                            LogInfo($"Get inventory lot for GID: {varmasLot.PhenomeGID} and LotReference {varmasLot.LotReference}");
                                            var phenomeLot = await _vtoPRepository.GetInventoryLotAsync(phenomeClient, varmasLot.PhenomeGID,
                                                varmasLot.LotReference, folderID, columnsToLoad, objectType.ToText());
                                            //create lot if not created yet with reference attribute
                                            if (phenomeLot == null)
                                            {
                                                phenomeLot = new InventoryLotResult
                                                {
                                                    GID = varmasLot.PhenomeGID.ToText()
                                                };
                                                var mappedcolForInventory = mappedCols.Where(x => x.TableName.EqualsIgnoreCase("lot")).ToList();
                                                LogInfo($"Inventory not found for GID: {varmasLot.PhenomeGID} , LotNr: {varmasLot.LotNr} and LotReference: {varmasLot.LotReference}.");
                                                LogInfo($"Creating Inventory for GID: {varmasLot.PhenomeGID} , LotNr: {varmasLot.LotNr} and LotReference: {varmasLot.LotReference}.");
                                                
                                                phenomeLot.LotID = await _vtoPRepository.CreateInventoryLotAsync(phenomeClient, researchGroupID, varmasLot.PhenomeGID.ToText(), mappedcolForInventory);
                                            }
                                            //if still lot is not created, break it
                                            if (string.IsNullOrWhiteSpace(phenomeLot.LotID))
                                            {
                                                LogInfo($"Inventory record not created for LotNr : {varmasLot.LotNr}, Lot Reference: {varmasLot.LotReference}.");
                                                //success = false;
                                                errorMessage.Add(new ExecutableError
                                                {
                                                    Success = false,
                                                    CropCode = log.CropCode,
                                                    SyncCode = log.SyncCode,
                                                    ErrorType = "data",
                                                    ErrorMessage = $"Inventory record not created for LotNr : {varmasLot.LotNr}, Lot Reference: {varmasLot.LotReference}."

                                                });
                                                getData = false;
                                                break;
                                            }
                                            //now update additional informaiton on inventory                                        
                                            LogInfo($"Update inventory record for LotID : {phenomeLot.LotID}.");

                                            var notMappedValues = new Dictionary<string, string>
                                            {
                                                {"Lotnr", varmasLot.LotReference.ToString() }
                                            };

                                            await _vtoPRepository.UpdateInventoryLotAsync(phenomeClient, phenomeLot.LotID, objectType, mappedCols,
                                                inventoryColumns, varmasLot, notMappedValues);

                                            //maintain log for succeeded calls
                                            syncLogs.Add(new ExternalLotInfo
                                            {
                                                LotNr = varmasLot.LotNr,
                                                VarietyNr = varmasLot.VarietyNr,
                                                PhenomeGID = phenomeLot.GID,
                                                PhenomeLotNr = phenomeLot.LotID
                                            });
                                        }
                                        //All ABS condition is already implemented in earlier condition so this is only needed for other variety like gb, th.
                                        else if (!varmasLot.LotType.EqualsIgnoreCase(absLot))
                                        {
                                            UpdateToVarmas = true;

                                            var germplasmName = await _vtoPRepository.GetGermplasmNameFromVarietyNrAsync(varmasLot.VarietyNr);
                                            if (string.IsNullOrWhiteSpace(germplasmName))
                                            {                                                
                                                errorMessage.Add(new ExecutableError
                                                {
                                                    Success = false,
                                                    CropCode = log.CropCode,
                                                    SyncCode = log.SyncCode,
                                                    ErrorType = "data",
                                                    ErrorMessage = $"GID: {varmasLot.PhenomeGID} => It seems the range of EZID in EZVarietyRelation is full. Please update the range of EZID."

                                                });
                                                LogInfo($"It seems the range of EZID in EZVarietyRelation is full. Please update the range of EZID.");
                                                getData = false;
                                                break;
                                            }
                                            //create germplasm
                                            var result = await _vtoPRepository.CreateGermplasmAsync(phenomeClient, new CreateGermplasmArgs
                                            {
                                                ObjectID = log.GermplasmSetID,
                                                Name = germplasmName
                                            });
                                            var gid = Convert.ToInt32(result.row_id); //newly created gid of germplasms
                                            var additionalFields = varmasLot.ProgramFields; //.Where(o => !o.ProgramFieldCode.EqualsIgnoreCase(varietyNameFieldName));
                                            if (additionalFields.Any())
                                            {
                                                //update additional program field data/attributes
                                                var germplasmColumns = await _vtoPRepository.GetGermplasmColumnsAsync(phenomeClient, 6, log.ABSLotFolderID);
                                                if (germplasmColumns.Any())
                                                {
                                                    var columnValues = (from t1 in mappedCols.Where(o => o.TableName.EqualsIgnoreCase("Variety"))
                                                                        join t2 in additionalFields on t1.VColumnName.ToLower() equals t2.ProgramFieldCode.ToLower()
                                                                        join t3 in germplasmColumns on t1.PColumnName.ToLower() equals t3.desc.ToLower()
                                                                        select new
                                                                        {
                                                                            ColumnID = t3.id,
                                                                            ColumnValue = t2.ProgramFieldValue
                                                                        }).Distinct().ToDictionary(k => k.ColumnID, v => v.ColumnValue);
                                                    //check stem column
                                                    if(varmasLot.LotType.EqualsIgnoreCase("GB"))
                                                    {
                                                        var stemExists = germplasmColumns.FirstOrDefault(x => x.desc.EqualsIgnoreCase("stem"));
                                                        if(stemExists != null)
                                                        {
                                                            columnValues.Add(stemExists.id, "GB" + varmasLot.VarietyNr);
                                                        }
                                                        else
                                                        {
                                                            errorMessage.Add(new ExecutableError
                                                            {
                                                                Success = false,
                                                                CropCode = log.CropCode,
                                                                SyncCode = log.SyncCode,
                                                                ErrorType = "data",
                                                                ErrorMessage = $"GID: {varmasLot.PhenomeGID} Stem column not found on GermplasmSet: {log.GermplasmSetID}."

                                                            });
                                                            LogInfo($"GID: {varmasLot.PhenomeGID} Stem column not found on GermplasmSet: {log.GermplasmSetID}.");
                                                            getData = false;
                                                            break;
                                                        }
                                                    }
                                                    if (columnValues.Any())
                                                    {
                                                        //update addiotional column data
                                                        await _vtoPRepository.UpdateGermplasmDataAsync(phenomeClient, new UpdateGermplasmDataArgs
                                                        {
                                                            ObjectType = 6,
                                                            ObjectID = log.GermplasmSetID,
                                                            GID = gid,
                                                            Values = columnValues
                                                        },researchGroupID);
                                                    }
                                                }
                                            }

                                            //get lot information                                       
                                            var phenomeLot = await _vtoPRepository.GetInventoryLotAsync(phenomeClient, gid, null,
                                                folderID, columnsToLoad,objectType.ToText());

                                            //if still lot is not created, break it
                                            if (phenomeLot == null)
                                            {
                                                //LogError($"GID: {varmasLot.PhenomeGID} => It was supposed to create inventory automatically for GID: {gid} but couldn't find it. Please enable this feature in Phenome if not already enabled.");
                                                //success = false;
                                                errorMessage.Add(new ExecutableError
                                                {
                                                    Success = false,
                                                    CropCode = log.CropCode,
                                                    SyncCode = log.SyncCode,
                                                    ErrorType = "data",
                                                    ErrorMessage = $"GID: {varmasLot.PhenomeGID} => It was supposed to create inventory automatically for GID: {gid} but couldn't find it. Please enable this feature in Phenome if not already enabled."

                                                });
                                                LogInfo($"GID: {varmasLot.PhenomeGID} => It was supposed to create inventory automatically for GID: {gid} but couldn't find it. Please enable this feature in Phenome if not already enabled.");
                                                getData = false;
                                                break;
                                            }

                                            //now update additional informaiton on inventory
                                            //skip and columns to be updated 
                                            var mappedCols2 = mappedCols.ToList();

                                            var notMappedValues = new Dictionary<string, string>
                                            {
                                                {"Lotnr", varmasLot.LotReference.ToString() }
                                            };
                                            await _vtoPRepository.UpdateInventoryLotAsync(phenomeClient, phenomeLot.LotID, objectType,
                                                mappedCols2, inventoryColumns, varmasLot, notMappedValues);

                                            //maintain log for succeeded calls
                                            syncLogs.Add(new ExternalLotInfo
                                            {
                                                LotNr = varmasLot.LotNr,
                                                VarietyNr = varmasLot.VarietyNr,
                                                PhenomeGID = phenomeLot.GID,
                                                PhenomeLotNr = phenomeLot.LotID,
                                                EZID = germplasmName
                                            });
                                        }

                                        //We need to update this lastsync lotnr one by one
                                        //update information to Varmas sync code wise
                                        if (syncLogs.Any())
                                        {
                                            if (UpdateToVarmas)
                                            {
                                                var requestArgs = new UpdateExternalLotsToVarmasArgs
                                                {
                                                    UserName = userName,
                                                    SyncCode = log.SyncCode,
                                                    Lots = syncLogs
                                                };
                                                await _vtoPRepository.UpdateExtenalLotsToVarmasAsync(requestArgs);
                                            }

                                            //create or update relationship in PtoV database
                                            var relationData = syncLogs.Select(o => new
                                            {
                                                GID = o.PhenomeGID,
                                                o.VarietyNr,
                                                PLotNr = o.PhenomeLotNr,
                                                VLotNr = o.LotNr,
                                                o.EZID,
                                                o.NewGID
                                            });
                                            var dataAsJson = relationData.Serialize();
                                            await _vtoPRepository.UpdatePtoVRelationshipAsync(dataAsJson);

                                            //update last synchronized lotnr into config table
                                            var lastLotNr = varmasLot.LotNr; // syncLogs.Max(o => o.LotNr);
                                            log.LotNr = lastLotNr;
                                            LogInfo($"Update last lot synced to value {lastLotNr}.");
                                            await _vtoPRepository.UpdateLastLotNrToSyncConfigTableAsync(log.SyncConfigID, lastLotNr);
                                        }
                                        else
                                        {
                                            getData = false;
                                        }
                                    }
                                    if (getData)
                                    {

                                        LogInfo($"Get data again from Varmas for CropCode {log.CropCode} and Sync Code: {log.SyncCode} with LotNr {log.LotNr}");
                                        varmasLots = await _vtoPRepository.GetVarmasLotsAndVarietiesAsync(new VarmasLotsAndVarietiesArgs
                                        {
                                            UserName = userName,
                                            CropCode = log.CropCode,
                                            SyncCode = log.SyncCode,
                                            LotNr = log.LotNr,
                                            RequestedData = "GB,TH,ABS"
                                        });
                                        if (!varmasLots.Any())
                                            LogInfo($"Syncrnization completed for : {log.CropCode}, Sync Code: {log.SyncCode}.");
                                    }
                                    else
                                    {
                                        varmasLots = Enumerable.Empty<VtoPSyncClient.Lot>();
                                        LogError($"Process halted for CropCode {log.CropCode} and Sync Code: {log.SyncCode}.");
                                    }
                                }

                                //now lock variables
                                var variables = new List<string>()
                                {
                                    "MasterNr",
                                    "E-number",
                                    "Gen",
                                    "Variety",
                                    "Pedigree",
                                    //"PedigrAbbr",
                                    "GenebankNr",
                                    "Stem"
                                };
                                var settingsData = await _phenomeRepository.GetSettingsAsync(phenomeClient, researchGroupID);                               
                                await _phenomeRepository.ApplylockVariablesAsync(phenomeClient, researchGroupID, settingsData, variables, "Lock");
                               
                            }
                            catch (Exception ex)
                            {
                                LogError(ex);
                                //success = false;
                                errorMessage.Add(new ExecutableError
                                {
                                    Success = false,
                                    CropCode = log.CropCode,
                                    SyncCode = log.SyncCode,
                                    ErrorType = "Exception",
                                    Exception = ex
                                });
                                
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                LogError(ex);
                errorMessage.Add(new ExecutableError
                {
                    Success = false,                   
                    ErrorType = "Exception",
                    Exception = ex
                });
            }
            return errorMessage;
        }

        private async Task<Tuple<string, string>> CreateSelfing(int selfingFieldSetID, int baseGID,RestClient client,string selfingMethodCode, int researchGroupID, List<Column> columnsToLoad, string gridID)
        {
            //var gid = Tuple.Create("Steve", "Jobs");

            var gid = "";
            var lotID = "";
            //check if selfing is already created earlier
            LogInfo($"Check if selfing is already created for the {baseGID} in field {selfingFieldSetID}");            
            var filterString = "{\"name\":\"=" + baseGID.ToText() + "\"}";
            //var setGridURL = "/api/v1/simplegrid/grid/get/FieldSelections";
            var setGridURL = "/api/v1/simplegrid/grid/create_rows/FieldSelections";
            if (string.IsNullOrWhiteSpace(gridID))
            {
                gridID = new Random().Next(10000000, 99999999).ToText();
            }            
            var jsonresp = await PrepareFilterGrid(client, setGridURL, selfingFieldSetID.ToText(), gridID, filterString, "28");
            if (jsonresp.Status.ToText().EqualsIgnoreCase("1"))
            {
                //get created selfing gid
                var getDataURL = "/api/v1/simplegrid/grid/get/FieldSelections";
                var requiredColumns = new List<string>();
                requiredColumns.Add("gid");
                requiredColumns.Add("name");
                gid = await FetchCreatedSelectionData(client, getDataURL, gridID, selfingFieldSetID.ToText(), "28", requiredColumns, baseGID.ToText());
                if(string.IsNullOrWhiteSpace(gid))
                {
                    //create selfing
                    //first move gid to selfingFieldSet
                    LogInfo($"Move GID to Field {selfingFieldSetID}");
                    var dragDropURL = "/api/v2/fieldentity/nurseries/set";
                    var selectionIDS = $"[\"{ baseGID }\"]";
                    var moveToTargetField = await MoveGIDToTargetField(client, dragDropURL, selfingFieldSetID, selectionIDS, 1, researchGroupID.ToText());

                    //get FEID from response
                    var moveToTargetResp = JsonConvert.DeserializeObject<MoveGIDResponse>(moveToTargetField);
                    if (moveToTargetResp.Success)
                    {
                        
                        var FEID = moveToTargetResp.rows_ids.FirstOrDefault();
                        LogInfo($"Create selfing for FEID {FEID}");
                        var URL = "/api/v2/fieldentity/selection/set";
                        var createSelfing = await client.PostAsync(URL, values =>
                        {
                            values.Add("method", selfingMethodCode);
                            values.Add("selectedRowsIds", "[" + FEID + "]");
                            values.Add("objectId", selfingFieldSetID.ToText());
                            values.Add("number", baseGID.ToText());
                            values.Add("groupToSingle", "0");
                            values.Add("fieldEntityType", "1"); //this field entiry type will be 1 for list level and 2 for plant level.
                        });
                        await createSelfing.EnsureSuccessStatusCodeAsync();
                        var createSelfingResp =  JsonConvert.DeserializeObject<MoveGIDResponse>(await createSelfing.Content.ReadAsStringAsync());
                        if(!createSelfingResp.Success)
                        {
                            LogInfo("Unable to create selfing record");
                            throw new Exception($"Unable to create selfing record for {baseGID} to field {selfingFieldSetID}");
                        }
                        //get created GID and also find lot ID of created GID
                        else
                        {
                            //filterString = "{\"name\":\"=" + baseGID.ToText() + "\"}";
                            FEID = createSelfingResp.rows_ids.FirstOrDefault();
                            LogInfo($"New selfing created with FEID {FEID}");
                            //filterString = "{\"name\":\"=" + baseGID.ToText() + "\"}";
                            filterString = "{\"id\":\"=" + FEID + "\"}";
                            jsonresp = await PrepareFilterGrid(client, setGridURL, selfingFieldSetID.ToText(), gridID, filterString, "28");
                            if (jsonresp.Status.ToText().EqualsIgnoreCase("1"))
                            {
                                //get created selection from base GID
                                gid = await FetchCreatedSelectionData(client, getDataURL, gridID, selfingFieldSetID.ToText(), "28", requiredColumns, baseGID.ToText());
                                if (!string.IsNullOrWhiteSpace(gid))
                                {
                                    //get created lot information
                                    LogInfo("Get inventory record");
                                    var phenomeLot = await _vtoPRepository.GetInventoryLotAsync(client, gid.ToInt32(), "", researchGroupID, columnsToLoad,"5");
                                    lotID = phenomeLot.LotID;
                                    LogInfo($"LotID {lotID}");
                                }
                                else
                                {
                                    LogInfo("unable to get gid of created selection record to search inventory for update.");
                                    throw new Exception($"Unable to get GID of created selection record to search inventory for update.");
                                }
                            }
                            else
                            {
                                LogInfo("Unable to get apply filter");
                                throw new Exception($"Unable to get apply filter to get created selection in field {selfingFieldSetID} for FEID {FEID}");
                            }
 
                        }
                    }
                    else
                    {
                        //unable to move gid
                        LogInfo($"Unable to move GID.");
                        throw new Exception($"Unable to move GID {baseGID} to field {selfingFieldSetID}");
                    }
                }
                else
                {
                    //get lot information   
                    LogInfo("Selfing record found. Searching inventory record.");
                    var phenomeLot = await _vtoPRepository.GetInventoryLotAsync(client, gid.ToInt32(), "", researchGroupID, columnsToLoad,"5");
                    lotID = phenomeLot?.LotID;
                    LogInfo($"Found LotID {lotID}");
                }
            }
            else
            {
                LogInfo($"Unable to get selection record in field {selfingFieldSetID} for GID {baseGID}");
                throw new Exception($"Unable to get selection record in field {selfingFieldSetID} for GID {baseGID}");
            }
            var tuple = Tuple.Create(gid, lotID);
            return tuple;
        }
        private async Task<string> MoveGIDToTargetField(RestClient client, string URL, int targetObjectID, string selectionIDS, int count, string sourceObjectID)
        {
            LogInfo("API: "+ URL);
            LogInfo($"parameters variables : objectId:{targetObjectID}~24, fieldId: {targetObjectID.ToText()}, selectedIds: {selectionIDS}, selectedIdsCount: {count.ToText()}, sourceObjectId: {sourceObjectID}");
            var resp = await client.PostAsync(URL, values =>
            {
                values.Add("objectId", $"{targetObjectID}~24");
                values.Add("fieldId", targetObjectID.ToText());
                values.Add("selectedIds", $"{selectionIDS}");
                values.Add("selectedIdsCount", $"{count.ToText()}");
                values.Add("sourceGridType", "Germplasms");
                values.Add("sourceObjectId", $"{sourceObjectID}");
                values.Add("targetDropType", "24");
                values.Add("targetObjectId", $"{targetObjectID}");
                values.Add("fieldEntityType", "1");
                values.Add("drag_lots_action", "1");
                values.Add("onlyNonExist", "1");
            });
            await resp.EnsureSuccessStatusCodeAsync();
            return await resp.Content.ReadAsStringAsync();
        }
        private async Task<GermplasmsColumnsResponse> PrepareFilterGrid(RestClient client, string setGridURL, string objectID, string gridID, string filterString, string objectType)
        {
            var resp123 = await client.PostAsync(setGridURL, values =>
            {
                values.Add("object_type", objectType);
                values.Add("object_id", objectID);
                values.Add("grid_id", gridID);
                values.Add("simple_filter", $"{filterString}");
            });
            await resp123.EnsureSuccessStatusCodeAsync();
            return JsonConvert.DeserializeObject<GermplasmsColumnsResponse>(await resp123.Content.ReadAsStringAsync());
        }

        private async Task<bool> AddColumns(RestClient client, string setOrderURL, List<Tuple<string, string>> keyvalues, List<string> requiredColumns, GermplasmsColumnsResponse columnsResp, string fieldID, string fieldType)
        {
            foreach (var _requiredColumn in requiredColumns)
            {
                var col = columnsResp.Columns.FirstOrDefault(x => x.id.EqualsIgnoreCase(_requiredColumn));
                if (col == null)
                {
                    keyvalues.Add(Tuple.Create("columnIds", _requiredColumn));
                }
            }
            if (keyvalues.Any())
            {
                keyvalues.Add(Tuple.Create("fieldId", fieldID));
                keyvalues.Add(Tuple.Create("fieldEntityType", fieldType));
                foreach (var _columns in columnsResp.Columns)
                {
                    keyvalues.Add(Tuple.Create("columnIds", _columns.id));
                }

                //call set grid to set new column
                return await SetColumnOnGrid(client, setOrderURL, keyvalues);
            }
            return true;
        }

        private async Task<bool> SetColumnOnGrid(RestClient client, string url, List<Tuple<string, string>> formData)
        {
            var resp = await client.PostAsync(url, values =>
            {
                foreach (var _formdata in formData)
                {
                    values.Add(_formdata.Item1, _formdata.Item2);
                }
            });
            var respContent = await resp.Content.DeserializeAsync<GermplasmResult>();
            return respContent.Success;
        }

        private async Task<string> FetchCreatedSelectionData(RestClient client, string URL, string gridID, string objectID, string objectType, List<string> requiredColumns,string baseGID)
        {
            var selfingGID = "";
            XDocument doc;
            var dictiKeyIndex = new Dictionary<string, int>();

            var dataResp = await client.PostAsync(URL, values =>
            {
                values.Add("object_type", objectType);
                values.Add("object_id", objectID);
                values.Add("grid_id", gridID);
                values.Add("gems_map_id", "0");
                values.Add("add_header", "1");
                values.Add("rows_per_page", "999999");
                values.Add("display_column", "0");
                values.Add("count", "999999");
                values.Add("posStart", "0");
            });
            await dataResp.EnsureSuccessStatusCodeAsync();
            var data = await dataResp.Content.ReadAsStreamAsync();
            doc = XDocument.Load(data);

            var columnsList = doc.Descendants("column").Select((x, idx) => new
            {

                ID = x.Attribute("id")?.Value,
                Index = idx
            }).ToList();


            foreach (var _requiredColumn in requiredColumns)
            {
                var col = columnsList.FirstOrDefault(x => x.ID.EqualsIgnoreCase(_requiredColumn));
                if (col == null)
                {
                    LogError($"Column: {_requiredColumn} not found on field { objectID}");
                    throw new Exception($"Column: {_requiredColumn} not found on field { objectID}");
                }
                //dictiKeyIndex[_requiredColumn] = col.Index;
                dictiKeyIndex.Add(col.ID, col.Index);
            }            
            var rows = doc.Descendants("row");
            foreach (var dr in rows)
            {
                var ID = dr.Attribute("id").Value;
                var celldata = dr.Descendants("cell").ToList();
                var baseGIDofSelfing = dictiKeyIndex.ContainsKey("name") ? celldata[dictiKeyIndex["name"]].Value : string.Empty;
                if(string.IsNullOrWhiteSpace(baseGIDofSelfing) == string.IsNullOrWhiteSpace(baseGID))
                {
                    var rowID = ID;
                    selfingGID = celldata[dictiKeyIndex["gid"]].Value;
                    return selfingGID;
                }
            }
            return selfingGID;
        }


        private async Task<string> GetGermplasmNameFromGIDAsync(RestClient phenomeClient, int objectType,int folderID, VtoPSyncClient.Lot varmasLot, List<Entities.Results.Column> germplasmColumns)
        {
            var germplasmName = string.Empty;
            Random rnd = new Random();
            var myRandomNo = rnd.Next(10000000, 99999999);
            var grid_ID = myRandomNo.ToText();

            //set grid
            var url = "/api/v1/simplegrid/grid/set_display/Germplasms";
            var setDisplayresponse = await phenomeClient.PostAsync(url, values =>
            {
                //var nameAndIDColumn = germplasmColumns.Where(x => x.id.EqualsIgnoreCase("GER~ID") || x.id.EqualsIgnoreCase("GER~name"));
                var nameCol = germplasmColumns.Where(x => x.id.EqualsIgnoreCase("GER~name"));
                values.Add("grid_id", grid_ID);
                values.Add("columns", nameCol.Serialize());
            });
            await setDisplayresponse.EnsureSuccessStatusCodeAsync();


            //filter grid
            url = "/api/v1/simplegrid/grid/filter_grid/Germplasms";
            var filterGridResp = await phenomeClient.PostAsync(url, values =>
            {
                values.Add("object_type", objectType.ToText());
                values.Add("object_id", folderID.ToText());
                values.Add("grid_id", grid_ID);
                values.Add("gems_map_id", "0");
                values.Add("admin_mode", "0");
                values.Add("simple_filter", $"{{\"GER~id\": \"={varmasLot.PhenomeGID}\"}}");
            });
            await filterGridResp.EnsureSuccessStatusCodeAsync();

            //get value
            url = "/api/v1/simplegrid/grid/show_grid/Germplasms?" +
                     $"object_type={objectType}&" +
                     $"object_id={folderID}&" +
                     $"grid_id={grid_ID}&" +
                     "gems_map_id=0&" +
                     "add_header=1&" +
                     "rows_per_page=100&" +
                     "use_name=name&" +
                     "posStart=0&" +
                     $"count={1}";
            var getDataResponse = await phenomeClient.GetAsync(url);
            await getDataResponse.EnsureSuccessStatusCodeAsync();
            var dataResponse = await getDataResponse.Content.ReadAsStreamAsync();
            //now parse value to get germplasm name from GID
            var doc = XDocument.Load(dataResponse);
            var index = doc.Descendants("column").Select((x, i) => new
            {
                ID = x.Attribute("id")?.Value,
                Index = i
            }).ToList().FirstOrDefault(x => x.ID.EqualsIgnoreCase("GER~name"));
            var rows = doc.Descendants("row");
            
            foreach (var dr in rows)
            {
                germplasmName = dr.Descendants("cell").ToList()[index.Index].Value.ToText();

            }
            return germplasmName;
        }

        private void LogError(Exception msg)
        {
            Console.WriteLine(msg.Message);
            _logger.Error(msg);
        }
        private void LogError(string msg)
        {
            Console.WriteLine(msg);
            _logger.Error(msg);
        }

        private void LogInfo(string msg)
        {
            Console.WriteLine(msg);
            _logger.Info(msg);
        }

        private async Task ExecuteAndWaitFor(int delayInMilliseconds, int noOfRetry, Func<Task<bool>> callback)
        {
            for (var i = 0; i < noOfRetry; i++)
            {
                if (await callback())
                {
                    break;
                }
                await Task.Delay(delayInMilliseconds);
            }
        }
    }
}
