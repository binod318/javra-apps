using Enza.PtoV.Common;
using Enza.PtoV.Services.Proxies;
using System;
using System.Configuration;
using System.Net;
using System.Security;
using System.Security.Principal;
using System.Threading.Tasks;
using System.Web;
using Enza.PtoV.Services.Interfaces;
using Enza.PtoV.Common.Extensions;
using Enza.PtoV.Common.Exceptions;

namespace Enza.PtoV.BusinessAccess.Services
{
    public class UELService : IUELService
    {
        private CreateUELRecord GetErrorModel(Exception ex)
        {
            var environment = ConfigurationManager.AppSettings["App:Environment"];
            if (string.IsNullOrEmpty(environment))
            {
                environment = "N/A";
            }
            var error = ex.Message;
            var processDesc = ex.InnerException?.Message;
            if (string.IsNullOrWhiteSpace(processDesc))
                processDesc = ex.StackTrace;

            if (ex is SoapException)
            {
                processDesc = (ex as SoapException).Detail;
            }
            var model = new CreateUELRecord
            {
                Application = ConfigurationManager.AppSettings["UEL:ApplicationID"],
                Environment = environment,
                Location = "PtoV",
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
                userName = context?.User?.Identity != null ? context.User.Identity.Name : WindowsIdentity.GetCurrent().Name;
                var model = GetErrorModel(ex);
                model.UserID = userName;
                svc.Model = model;
                var resp = AsyncHelper.RunSync(svc.CreateUELRecordProcessAsync);
                logID = resp.LogID;
                return resp.Result == "0";
            }
        }

        public async Task<int> LogAsync(Exception ex)
        {
            var serviceUrl = ConfigurationManager.AppSettings["UEL:ServiceUrl"];
            var (UserName, Password) = Credentials.GetCredentials();
            using (var svc = new UELSoapClient
            {
                Url = serviceUrl,
                Credentials = new NetworkCredential(UserName, Password)
            })
            {
                //prepare data
                var userName = "Anonymous";
                var context = HttpContext.Current;
                userName = context?.User?.Identity != null ? context.User.Identity.Name : WindowsIdentity.GetCurrent().Name;

                var model = GetErrorModel(ex);
                model.UserID = userName;
                svc.Model = model;
                var (Result, LogID) = await svc.CreateUELRecordProcessAsync();
                var success = Result == "0";
                if (success)
                    return LogID.ToInt32();
                return -1;
            }
        }
    }
}
