using Azure.Storage.Blobs;
using System;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;
using TrialApp.ServiceClient;
using Xamarin.Essentials;
using Xamarin.Forms;

namespace TrialApp.Services
{
    public class WebserviceTasks
    {
        public static string UsernameWS { get; set; }
        public static string PasswordWS { get; set; }
        public static string ServiceUsername{ get; set; }
        public static string ServicePassword { get; set; }
        public static string dbVersion = "1.0";

        public static string SyncCode { get; set; }
        public static string appVersion = "0.1.0.0";
        public static string domain = "INTRA";

        public static string Endpoint { get; set; }
        public static int FldNrPerRqst { get; set; }
        public static string Token { get; set; }
        public static string AdToken { get; set; }
        public static string AdAccessToken { get; set; }
        public static DateTime TokenExpiryDate { get; set; }

        public static void SetDefaults(string name)
        {
            var service = new SettingParametersService();

            var settingparams = service.GetParamsList();

            if (settingparams == null) return;
            if (string.IsNullOrEmpty(settingparams.Single().Endpoint))
                Endpoint = "https://bpmdev.enzazaden.com/cordys/com.eibus.web.soap.Gateway.wcp?";
            else
            {
                var endpoints = settingparams.Single().Endpoint.Split('|');
                if (endpoints.Length > 1)
                {
                    if (string.IsNullOrEmpty(name)) return;

                    if (name.Contains("Test"))
                        settingparams.Single().Endpoint = endpoints[0];
                    else if (name.Contains("Acc"))
                        settingparams.Single().Endpoint = endpoints[1];
                    else
                        settingparams.Single().Endpoint = endpoints[2];

                    Endpoint = settingparams.Single().Endpoint;

                    service.UpdateParams("endpoint", settingparams.Single().Endpoint);
                }
                else
                    Endpoint = settingparams.Single().Endpoint;

            }

        }

        public static SoapClient GetSoapClient()
        {
            return new SoapClient
            {
                EndPointAddress = Endpoint,
                Credentail = domain + "\\" + ServiceUsername + ":" + ServicePassword
            };
        }

        public static async Task<BlobContainerClient> GetBlobClient()
        {
            string containerName = "trialappphotos";
            string oauthToken = "";
            BlobContainerClient containerClient;
            BlobServiceClient client;

            try
            {
                oauthToken = await SecureStorage.GetAsync("BlobConnectionKey");
            }
            catch
            {
                // Possible that device doesn't support secure storage on device.
            }

            //if (Device.RuntimePlatform == Device.iOS)
            //{
            //    var serviceuri = new Uri(oauthToken);
            //    client = new BlobServiceClient(serviceuri);
            //}
            
            client = new BlobServiceClient(oauthToken);
            
            try
            {
                containerClient = client.GetBlobContainerClient(containerName);
                //container already exists.
            }
            catch (Exception)
            {
                containerClient = await client.CreateBlobContainerAsync(containerName);
            }
            return containerClient;
        }
        public static bool CheckTokenValidDate()
        {
            var timeDifference = TokenExpiryDate - DateTime.Now;
            if (!string.IsNullOrWhiteSpace(UsernameWS) && timeDifference >= new TimeSpan(0, 3, 0))
                return true;
            else { UsernameWS = ""; return false; }
        }

        /// <summary>
        /// Indicator whether to go to Download screen after sign in when notification is received
        /// </summary>
        public static bool GoDownload { get; set; }

        /// <summary>
        /// Indicator whether to naviagte to next cell or not for VarietyPageTablet screen
        /// </summary>
        public static bool KeyboardNextClicked { get; set; }

        /// <summary>
        /// Indicator whether last cell is validated
        /// </summary>
        public static bool CellNotValidated { get; set; }

        /// <summary>
        /// Avoid duplicate display alert display
        /// </summary>
        public static bool DisplayAlertActive { get; set; }
    }
}
