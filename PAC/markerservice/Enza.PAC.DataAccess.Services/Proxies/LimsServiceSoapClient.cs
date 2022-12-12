using Enza.PAC.Common;
using Enza.PAC.Common.Exceptions;
using Enza.PAC.Common.Extensions;
using Enza.PAC.DataAccess.Services.Abstract;
using Microsoft.ApplicationInsights;
using System;
using System.Threading.Tasks;
using System.Xml.Linq;

namespace Enza.PAC.DataAccess.Services.Proxies
{
    public class LimsServiceSoapClient : SoapClient
    {
        public object Model { get; set; }

        protected override string PrepareBody()
        {
            var tpl = typeof(LimsServiceSoapClient).Assembly.GetString("Enza.PAC.DataAccess.Services.Requests.ReservePlatesInLIMSRequest.st");
            var body = Template.Render(tpl, Model);
            return body;
        }

        public async Task<SoapExecutionResult> ReservePlatesInLIMSAsync()
        {
            // Log Dependency telemetry
            var actionName = "http://contract.enzazaden.com/LIMS/v1/ReservePlatesInLIMS";
            var response = "";
            var isSuccess = false;
            var startTime = DateTime.UtcNow;
            var timer = System.Diagnostics.Stopwatch.StartNew();

            try
            {
                response = await ExecuteAsync(actionName);
                XNamespace ns = "http://contract.enzazaden.com/LIMS/v1";
                var result = GetResult(ns, response);
                if (!result.Success)
                {
                    response = result.Error;
                    throw new SoapException(result.Error);
                }

                return result;
            }
            finally
            {
                timer.Stop();

                if (string.IsNullOrEmpty(response))
                    response = (StatusCode == 401) ? "Unauthorized" : "Failed";

                if (StatusCode == 200)
                    isSuccess = true;

                if (StatusCode == 0)
                    StatusCode = 500;

                var data = Model.ToJson() + "|||" + response;
                var telemetryClient = new TelemetryClient();
                telemetryClient.TrackDependency("HTTP", Url, actionName, data, startTime, timer.Elapsed, StatusCode.ToString(), isSuccess);
            }
        }

        public async Task<SoapExecutionResult> FillPlatesInLimsAsync()
        {
            // Log Dependency telemetry
            var actionName = "http://contract.enzazaden.com/LIMS/v1/LimsBinding_v1/FillPlatesWrapperRequest";
            var response = "";
            var isSuccess = false;
            var startTime = DateTime.UtcNow;
            var timer = System.Diagnostics.Stopwatch.StartNew();

            try
            {
                var tpl = typeof(LimsServiceSoapClient).Assembly.GetString(
                "Enza.PAC.DataAccess.Services.Requests.FillPlatesInLIMSRequest.st");
                var body = Template.Render(tpl, Model);
                response = await ExecuteAsync(actionName, body);

                XNamespace ns = "http://contract.enzazaden.com/LIMS/v1";
                var result = GetResult(ns, response);
                if (!result.Success)
                {
                    response = result.Error;
                    throw new SoapException(result.Error);
                }

                return result;
            }
            finally
            {
                timer.Stop();

                response = !string.IsNullOrEmpty(response) ? response
                           : (StatusCode == 0) ? "Unable to get response from server." //This is the case of request timeout
                           : (StatusCode == 401) ? "Unauthorized" //Unauthorized exception
                           : "Failed"; // Other exceptions
                StatusCode = (StatusCode == 0) ? 500 : StatusCode; // If no statuscode then fill 500

                if (StatusCode == 200)
                    isSuccess = true;

                var data = Model.ToJson() + "|||" + response;
                var telemetryClient = new TelemetryClient();
                telemetryClient.TrackDependency("HTTP", Url, actionName, data, startTime, timer.Elapsed, StatusCode.ToString(), isSuccess);
            }            
        }
    }
}
