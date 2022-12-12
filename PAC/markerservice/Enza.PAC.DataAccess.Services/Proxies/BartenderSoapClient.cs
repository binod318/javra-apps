using System;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;
using Enza.PAC.Common;
using Enza.PAC.Common.Extensions;
using Enza.PAC.DataAccess.Services.Abstract;
using Microsoft.ApplicationInsights;

namespace Enza.PAC.DataAccess.Services.Proxies
{
    public class BartenderSoapClient : SoapClient
    {
        public async Task<SoapExecutionResult> PrintToBarTenderAsync()
        {
            // Log Dependency telemetry
            var actionName = "http://contract.enzazaden.com/BarTender/v1/printToBarTender";
            var response = "";
            var isSuccess = false;
            var startTime = DateTime.UtcNow;
            var timer = System.Diagnostics.Stopwatch.StartNew();

            try
            {
                response = await ExecuteAsync(actionName);

                XNamespace ns = "http://contract.enzazaden.com/BarTender";
                var result = GetResult(ns, response);

                isSuccess = result.Success;
                response = string.IsNullOrEmpty(result.Error) ? "Success" : result.Error;
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

                var data = Model.ToJson() + "|||" + response;
                var telemetryClient = new TelemetryClient();
                telemetryClient.TrackDependency("HTTP", Url, actionName, data, startTime, timer.Elapsed, StatusCode.ToString(), isSuccess);
            }
        }

        public object Model { get; set; }

        protected override string PrepareBody()
        {
            var body = typeof(BartenderSoapClient).Assembly.GetString(
                "Enza.PAC.DataAccess.Services.Requests.PrintToBarTenderRequest.st");
            var tpl = Template.Render(body, Model);
            return tpl;
        }

        
    }
}
