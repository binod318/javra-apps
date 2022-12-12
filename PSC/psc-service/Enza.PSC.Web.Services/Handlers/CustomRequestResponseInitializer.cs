using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights.Extensibility;
using System.IO;
using System.Web;

namespace Enza.PSC.Web.Services.Handlers
{
    public class CustomRequestResponseInitializer : ITelemetryInitializer
    {
        private const string RequestBodyProperty = "RequestBody";

        public void Initialize(ITelemetry telemetry)
        {
            if (string.IsNullOrEmpty(telemetry.Context.Cloud.RoleName))
            {
                //set custom role name here
                telemetry.Context.Cloud.RoleName = "PSC-API";
            }

            var requestTelemetry = telemetry as RequestTelemetry;

            if (requestTelemetry == null || HttpContext.Current == null)
            {
                return;
            }

            if (requestTelemetry.Name == "POST /" || requestTelemetry.Name == "GET /" ||
                requestTelemetry.Name == "POST /PscServices/" || requestTelemetry.Name == "GET /PscServices/")
            {
                return;
            }

            var request = HttpContext.Current.Request;
          
            if (request == null)
            {
                return;
            }

            if (request.HttpMethod == "OPTIONS" || request.HttpMethod == "GET")
            {
                return;
            }

            if (!int.TryParse(requestTelemetry.ResponseCode, out var responseCode))
            {
                return;
            }

            if (!request.InputStream.CanSeek)
            {
                //Trace.WriteLine("Failed request body was not added to the Application Insights telemetry due to non-buffered input stream.");
                return;
            }

            //Log RequestBody
            using (var streamReader = new StreamReader(request.InputStream, request.ContentEncoding, true, 1024, true))
            {
                request.InputStream.Position = 0;
                string requestContent = streamReader.ReadToEnd();
                request.InputStream.Position = 0;

                if (string.IsNullOrEmpty(requestContent))
                {
                    return;
                }

                if (requestTelemetry.Properties.ContainsKey(RequestBodyProperty))
                {
                    requestTelemetry.Properties[RequestBodyProperty] = requestContent;
                }
                else
                {
                    requestTelemetry.Properties.Add(RequestBodyProperty, requestContent);
                }
            }
        }
    }
}