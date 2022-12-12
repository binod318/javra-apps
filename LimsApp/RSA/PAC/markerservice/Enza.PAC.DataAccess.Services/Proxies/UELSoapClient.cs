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
    public class UELSoapClient : SoapClient
    {
        public async Task<(string Result, string LogID)> CreateUELRecordProcessAsync()
        {
            //Log Dependency telemetry
            var actionName = "http://contract.enzazaden.com/uel/logging/v1";
            var response = "";
            var isSuccess = false;
            var startTime = DateTime.UtcNow;
            var timer = System.Diagnostics.Stopwatch.StartNew();

            try
            {
                response = await ExecuteAsync(actionName);
                XNamespace ns = "http://contract.enzazaden.com/uel/logging/v1";
                var rs = GetResult(response, ns);

                return rs;

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
        public object Model { get; set; }

        protected override string PrepareBody()
        {
            var body = typeof(UELSoapClient).Assembly.GetString("Enza.PAC.DataAccess.Services.Requests.CreateUELRecordProcess.st");
            return Template.Render(body, Model);
        }

        public (string Result, string LogID) GetResult(string response, XNamespace ns)
        {
            var doc = XDocument.Parse(response);
            var result = doc.Descendants(ns + "result")?.FirstOrDefault()?.Value;
            var logID = doc.Descendants(ns + "logID")?.FirstOrDefault()?.Value;
            return (result, logID);
        }
    }
    public class CreateUELRecord
    {
        public string Environment { get; set; }
        public string Location { get; set; }
        public string ErrorDetailText { get; set; }
        public string UserID { get; set; }
        public string Application { get; set; }
        public CreateUelRecordInstanceProperties InstanceProperties { get; set; }
    }

    public class CreateUelRecordInstanceProperties
    {
        public string ProcessDescription { get; set; }
        public string Organization { get; set; }
    }
}
