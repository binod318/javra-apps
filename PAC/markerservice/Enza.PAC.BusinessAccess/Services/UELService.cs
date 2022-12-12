using Enza.PAC.Common;
using Enza.PAC.Common.Exceptions;
using Enza.PAC.DataAccess.Services.Proxies;
using System;
using System.Configuration;
using System.Net;
using System.Security;
using System.Web;

namespace Enza.PAC.BusinessAccess.Services
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
            var processDesc = ex.StackTrace;
            if (ex is SoapException)
            {
                processDesc = (ex as SoapException).Detail;
            }

            var model = new CreateUELRecord
            {
                Application = ConfigurationManager.AppSettings["UEL:ApplicationID"],
                Environment = environment,
                Location = "PAC",
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
