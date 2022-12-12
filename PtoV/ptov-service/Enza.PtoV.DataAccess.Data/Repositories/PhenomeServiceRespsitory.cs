using System;
using System.Collections.Generic;
using System.Configuration;
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
    public class PhenomeServiceRespsitory : IPhenomeServiceRespsitory
    {
        private static readonly ILog _logger =
            LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);

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
        public async Task<GetSettingsResponse> GetSettingsAsync(RestClient client, int rgid)
        {
            /*
                keys: ColorBySource
                keys: DefaultFileFormat
                keys: DownloadPreviousObsToPhenomApp
                keys: FieldInfo
                keys: FieldObservations
                keys: FieldPlants
                keys: PlantNaming
                keys: HybridAndParentsName
                keys: InventoryExtractForm
                keys: InventorySiteForm
                keys: LockColumnsFromEditing
                keys: Upload
                keys: VariablesRoles
                keys: Encoding
                keys: InventorySourceColumns
                rg_id: 2997
                subkeys: {"FieldObservations":"CopyFromGermplasm"}
             */
            LogInfo($"Getting settings for Research group {rgid}");
            var response = await client.PostAsync("/api/v2/settings/get_multi_keys", values =>
                 {
                     values.Add("keys", "LockColumnsFromEditing");
                     values.Add("rg_id", rgid.ToText());
                 });
            await response.EnsureSuccessStatusCodeAsync();
            //var result = await response.Content.ReadAsStringAsync();
            var result = await response.Content.DeserializeAsync<GetSettingsResponse>();
            if(!result.Status.EqualsIgnoreCase("1"))
            {
                throw new Exception($"Unable to get settings to get locked variables for research group {rgid}");
            }
            return result;
        }
        public async Task ApplylockVariablesAsync(RestClient client, int rgid, GetSettingsResponse settings,List<string> variables, string action)
        {
            //unlock variables
            if (action.EqualsIgnoreCase("Unlock"))
            {
                LogInfo($"Applying Unlock on variables for RGID: {rgid.ToText()}");
                var data = (from t1 in variables
                            join t2 in settings.rg_columns_vid_names on t1.ToText().ToLower() equals t2.Name.ToText().ToLower()
                            select t2.Value).ToList();
                settings.Settings.LockColumnsFromEditing.variable_ids = settings.Settings.LockColumnsFromEditing.variable_ids.Where(x => !data.Any(y => y.ToText() == x.ToText())).ToList();
            }
            else
            {
                LogInfo($"Applying lock on variables for RGID: {rgid.ToText()}");
                var data = (from t1 in variables
                            join t2 in settings.rg_columns_vid_names on t1.ToText().ToLower() equals t2.Name.ToText().ToLower()
                        select t2.Value).ToList();
                foreach (var _lockeVariables in data)
                {
                    if(settings.Settings.LockColumnsFromEditing.variable_ids.FirstOrDefault(x=>x.ToText() == _lockeVariables.ToText()) == null)
                        settings.Settings.LockColumnsFromEditing.variable_ids.Add(_lockeVariables);
                }
            }

            var response = await client.PostAsync("/api/v2/settings/set_multi_keys", values =>
             {
                 values.Add("config_type", "3");
                 values.Add("type_id", rgid.ToText());
                 values.Add("settings", settings.Settings.Serialize());
             });
            await response.EnsureSuccessStatusCodeAsync();
            var result = await response.Content.DeserializeAsync<PhenomeResponse>();
            if (!result.Status.EqualsIgnoreCase("1"))
            {
                throw new Exception($"Unable to {action} variable for research group: {rgid}");
            }
        }
        private void LogInfo(string msg)
        {
            Console.WriteLine(msg);
            _logger.Info(msg);
        }
    }
}
