using System.Configuration;
using Enza.PtoV.Common.Extensions;

namespace Enza.PtoV.Common
{
    public class Credentials
    {
        public static (string UserName, string Password) GetCredentials()
        {
            return GetCredentials("SVC:Credentials");
        }

        public static (string UserName, string Password) GetCredentials(string settingName)
        {
            var credential = ConfigurationManager.AppSettings[settingName];
            if (string.IsNullOrWhiteSpace(credential))
                throw new System.Exception(
                    $"Please provide credentials in AppSettings section with the key {settingName}");
            var credentials = credential.Decrypt();
            return credentials.GetCredentials();
        }
    }
}
