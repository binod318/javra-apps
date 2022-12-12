using Enza.PAC.Common.Extensions;
using System.Configuration;

namespace Enza.PAC.Common
{
    public class Credentials
    {
        public static (string UserName, string Password) GetCredentials()
        {
            var credentials = ConfigurationManager.AppSettings["SVC:Credentials"].Decrypt();
            var credential = credentials.GetCredentials();
            return credential;
        }

        public static (string UserName, string Password) GetCredentials(string settingName)
        {
            var credential = ConfigurationManager.AppSettings[settingName];
            if (string.IsNullOrWhiteSpace(credential))
                throw new System.Exception(
                    $"Please provide credentials in AppSettings section with the key: {settingName}");
            var credentials = credential.Decrypt();
            return credentials.GetCredentials();
        }
    }
}
