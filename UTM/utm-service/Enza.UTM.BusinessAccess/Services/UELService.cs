using System;
using System.Configuration;
using System.IO;
using System.Net;
using System.Security;
using System.Web;
using Enza.UTM.Common;
using Enza.UTM.Common.Exceptions;
using Enza.UTM.Services.Proxies;

namespace Enza.UTM.BusinessAccess.Services
{
    public class UELService
    {
        CreateUELRecord GetErrorModel(Exception ex)
        {
            var environment = ConfigurationManager.AppSettings["App:Environment"];
            if (string.IsNullOrEmpty(environment))
            {
                environment = "N/A";
            }
            var error = ex.Message;

            //Add Detail error in case of Bad Request
            if (ex is WebException)
            {
                var response = (ex as WebException).Response;
                HttpWebResponse httpResponse = (HttpWebResponse)response;
                using (Stream dt = response.GetResponseStream())
                using (var reader = new StreamReader(dt))
                {
                    string text = reader.ReadToEnd();
                    if(!string.IsNullOrWhiteSpace(text))
                        error = string.Concat(error, "--", text);
                }
            }

            var processDesc = ex.StackTrace;
            if (ex is SoapException)
            {
                processDesc = (ex as SoapException).Detail;
            }

            var model = new CreateUELRecord
            {
                Application = ConfigurationManager.AppSettings["UEL:ApplicationID"],
                Environment = environment,
                Location = "UTM",
                ErrorDetailText = SecurityElement.Escape(error),
                InstanceProperties = new CreateUelRecordInstanceProperties
                {
                    Organization = "EnzaZaden",
                    ProcessDescription = SecurityElement.Escape(processDesc)
                }
            };
            return model;
        }

        public bool LogError(Exception ex, out string logID)
        {
            var serviceUrl = ConfigurationManager.AppSettings["UEL:ServiceUrl"];
            var credentials = Credentials.GetCredentials();
            using (var svc = new UELSoapClient
            {
                Url = serviceUrl,
                Credentials = new NetworkCredential(credentials.UserName, credentials.Password)
            })
            {
                //prepare data
                var userName = "Anonymous";
                var context = HttpContext.Current;
                if (context?.User?.Identity != null)
                {
                    userName = context.User.Identity.Name;
                }
                var model = GetErrorModel(ex);
                model.UserID = userName;
                svc.Model = model;
                var resp = AsyncHelper.RunSync(svc.CreateUELRecordProcessAsync);
                logID = resp.LogID;
                return resp.Result == "0";
            }
        }
    }
}
