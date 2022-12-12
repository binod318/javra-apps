using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
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

namespace Enza.PtoV.DataAccess.Data.Repositories
{
    public class ENumberSyncRepository : Repository<object>, IENumberSyncRepository
    {
        private readonly IUserContext userContext;
        private readonly IPhenomeServiceRespsitory _phenomeRepo;
        private readonly string _baseServiceUrl = ConfigurationManager.AppSettings["BasePhenomeServiceUrl"];
        private static readonly ILog _logger =
            LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);
        public ENumberSyncRepository(IDatabase dbContext, IUserContext userContext,IPhenomeServiceRespsitory pheomeRepo) : base(dbContext)
        {
            this.userContext = userContext;
            _phenomeRepo = pheomeRepo;
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
        public async Task UpdateGermplasmDataAsync(RestClient client, UpdateGermplasmDataArgs args)
        {
            var colIDs = JsonConvert.SerializeObject(args.Values.Keys);
            var colValues = JsonConvert.SerializeObject(args.Values.Values);
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
                if(resp.Message.ToLower().Contains("column locked for editing"))
                {  
                    //apply unlock                    
                    var variables = new List<string>()
                                                    {
                                                        "E-number",
                                                        "Variety",
                                                        "VrStagVc",
                                                        "Gen",
                                                        "Pedigree",
                                                        "GenebankNr"
                                                    };
                    await ApplyLockVariablesAsync(client, args.ObjectID, variables, "Unlock");

                    //call service again to update data
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
                        _logger.Error(resp.Message);
                        throw new Exception($"Unable to update germplasm fields. Objeect ID: {args.ObjectID}, GID: {args.GID}. Error {resp.Message}");
                    }
                }
                else
                {
                    _logger.Error(resp.Message);
                    throw new Exception($"Unable to update germplasm data. Objeect ID: {args.ObjectID}, GID: {args.GID} . Error: {resp.Message}" );
                }
            }
            
        }
        public async Task ApplyLockVariablesAsync(RestClient client,int rgID, List<string> variables,string action)
        {
            var settingsData = await _phenomeRepo.GetSettingsAsync(client, rgID);
            await _phenomeRepo.ApplylockVariablesAsync(client, rgID, settingsData, variables, action);
        }

        public async Task<IEnumerable<VarietyLogResult>> GetVarietyLogsAsync(string syncCode, string cropCode)
        {
            //var data = await DbContext.ExecuteReaderAsync(DataConstants.PR_VTOPSYNC_GET_VARIETY_LOGS, System.Data.CommandType.StoredProcedure,
            //    args =>
            //    {
            //        args.Add("@SyncCode", syncCode);
            //        args.Add("@CropCode", cropCode);
            //    }, reader => new 
            //    {
            //        VarietyID = reader.Get<int>(0),
            //        CropCode = reader.Get<string>(1),
            //        GID = reader.Get<int>(2),
            //        ENumber = reader.Get<string>(3),
            //        VarietyName = reader.Get<string>(4),
            //        ObjectID = reader.Get<int>(5),
            //        ObjectType = reader.Get<int>(6),
            //        VarmasVarietyStatus = reader.Get<string>(7),
            //        Gen = reader.Get<string>(8)
            //    });
            //var varietyandGen = data.Select(x => new ProgramField
            //{
            //    ProgramFieldCode = x.VarietyID.ToText(),
            //    ProgramFieldValue = x.Gen
            //}).ToList();


            //var data1 = data.Select(x => new VarietyLogResult
            //{
            //    VarietyID = x.VarietyID,
            //    CropCode = x.CropCode,
            //    GID = x.GID,
            //    ENumber = x.ENumber,
            //    VarietyName = x.VarietyName,
            //    ObjectID = x.ObjectID,
            //    ObjectType = x.ObjectType,
            //    VarmasVarietyStatus = x.VarmasVarietyStatus,
            //    ProgramFieldData = varietyandGen.Where(y => y.ProgramFieldCode == x.VarietyID.ToText()).Select(y => new ProgramField
            //    {
            //        ProgramFieldCode = "Gen",
            //        ProgramFieldValue = y.ProgramFieldValue
            //    }).ToList()
            //});
            //var b = data1.ToList();
            //return b;
            //response.Varieties.FirstOrDefault(x => x.VarietyNr == o.VarietyNr).ProgramFields.Select(x => new Entities.Results.ProgramField { ProgramFieldCode = x.ProgramFieldCode, ProgramFieldValue = x.ProgramFieldValue }).ToList()

            return await DbContext.ExecuteReaderAsync(DataConstants.PR_VTOPSYNC_GET_VARIETY_LOGS, System.Data.CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@SyncCode", syncCode);
                    args.Add("@CropCode", cropCode);
                }, reader => new VarietyLogResult
                {
                    VarietyID = reader.Get<int>(0),
                    CropCode = reader.Get<string>(1),
                    GID = reader.Get<int>(2),
                    ENumber = reader.Get<string>(3),
                    VarietyName = reader.Get<string>(4),
                    ObjectID = reader.Get<int>(5),
                    ObjectType = reader.Get<int>(6),
                    VarmasVarietyStatus = reader.Get<string>(7)
                });

        }

        public Task UpdateVarietyENumbersAsnyc(string dataAsJson)
        {
            return DbContext.ExecuteNonQueryAsync(DataConstants.PR_VTOPSYNC_UPDATE_VARMAS_ENUMBERS, System.Data.CommandType.StoredProcedure,
                args => args.Add("@DataAsJson", dataAsJson));
        }

        public Task UpdateVarietyStatusAsync(int varietyID)
        {

            var query = @"UPDATE V
                            SET V.StatusCode = CASE WHEN V.StatusCode = 250 THEN 200
                                                    WHEN V.StatusCode = 350 THEN 300 
                                                    ELSE V.StatusCode
                                                END
                        FROM Variety V
                        WHERE V.VarietyID = @VarietyID";
            return DbContext.ExecuteNonQueryAsync(query, System.Data.CommandType.Text,
                args => args.Add("@VarietyID", varietyID));
        }
        public Task UpdateSyncedTimestampAsync(string cropCode, string syncCode, string timestamp)
        {
            var query = "UPDATE VtoPSyncConfig SET " +
                "VarSychedTime = @VarSychedTime " +
                "WHERE SyncCode = @SyncCode AND CropCode = @CropCode";
            return DbContext.ExecuteNonQueryAsync(query, System.Data.CommandType.Text,
                args =>
                {
                    args.Add("@SyncCode", syncCode);
                    args.Add("@CropCode", cropCode);
                    args.Add("@VarSychedTime", timestamp);
                });
        }

        public Task<IEnumerable<VarietySyncLog>> GetVarmasVarietySyncLogsAsync()
        {
            return DbContext.ExecuteReaderAsync(DataConstants.PR_VTOPSYNC_GET_VARIETY_SYNC_LOGS,
                System.Data.CommandType.StoredProcedure,
                args => { },
                reader => new VarietySyncLog
                {
                    SyncConfigID = reader.Get<int>(0),
                    SyncCode = reader.Get<string>(1),
                    CropCode = reader.Get<string>(2),
                    VarSychedTime = reader.Get<string>(3)
                });
        }

        public async Task<VtoPSyncClient.GetVarietyInfoResponse> GetVarmasVarietiesAsync(VarmasVarietiesArgs requestArgs)
        {
            using (var client = new VtoPSyncClient())
            {
                var url = ConfigurationManager.AppSettings["VarmasServiceUrl"];
                return await client.GetVarietiesAsync(url, requestArgs);
            }
        }
        public Task<IEnumerable<VarietyLogRelation>> GetVarietyLogsForVarietyAsync(string varietyList, string syncCode, string cropCode)
        {           
            return DbContext.ExecuteReaderAsync(DataConstants.PR_VTOPSYNC_GET_VARIETY_LOGS_FOR_VARIETIES, System.Data.CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@VarietyList", varietyList);
                    args.Add("@SyncCode", syncCode);
                    args.Add("@CropCode", cropCode);
                }, reader => new VarietyLogRelation
                {
                    VarietyNr = reader.Get<int>(0),
                    GID = reader.Get<int>(1),
                    ObjectID = reader.Get<int>(2),
                    ObjectType = reader.Get<int>(3)
                });
        }
        public async Task<IEnumerable<VarietyLogResult>> GetResearchGroupObjectID(string cropCode)
        {
            var query = "SELECT ObjectID = CAST(ObjectID AS INT) FROM [File] WHERE CropCode = @CropCode";
            return await DbContext.ExecuteReaderAsync(query, System.Data.CommandType.Text, args =>
              {
                  args.Add("@CropCode", cropCode);

              }, reader => new VarietyLogResult
              {
                  ObjectID = reader.Get<int>(0)
              });

        }

        public async Task<IEnumerable<StatusDetail>> GetStatusDetailAsync()
        {
            var query = "SELECT [StatusID], [StatusTable], [StatusCode], [StatusName], [StatusDescription]  FROM [Status]";
            return await DbContext.ExecuteReaderAsync(query, System.Data.CommandType.Text,
                reader => new StatusDetail
                {
                    StatusID = reader.Get<int>(0),
                    StatusTable = reader.Get<string>(1),
                    StatusCode = reader.Get<int>(2),
                    StatusName = reader.Get<string>(3),
                    StatusDescription = reader.Get<string>(4)
                });
        }

        #region Private Methods

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
}
