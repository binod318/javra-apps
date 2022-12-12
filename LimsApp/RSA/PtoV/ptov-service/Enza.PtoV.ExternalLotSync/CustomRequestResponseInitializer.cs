using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights.Extensibility;
using System.IO;
using System.Web;

namespace Enza.PtoV.ExternalLotSync
{ 
    public class CustomRequestResponseInitializer : ITelemetryInitializer
    {
        private const string RequestBodyProperty = "RequestBody";

        public void Initialize(ITelemetry telemetry)
        {
            var requestTelemetry = telemetry as RequestTelemetry;

            if (requestTelemetry == null || HttpContext.Current == null)
            {
                return;
            }

            var request = HttpContext.Current.Request;
            var response = HttpContext.Current.Response;

            if (request == null || response == null)
            {
                return;
            }

            if (!int.TryParse(requestTelemetry.ResponseCode, out var responseCode))
            {
                return;
            }
                
            //if (responseCode < 400) // non-success status code
            //{
            //    return;
            //}

            if (!request.InputStream.CanSeek)
            {
                //Trace.WriteLine("Failed request body was not added to the Application Insights telemetry due to non-buffered input stream.");
                return;
            }

            //Log RequestBody
            using (var streamReader = new StreamReader(request.InputStream, request.ContentEncoding, true, 1024, true))
            {
                request.InputStream.Position = 0;

                var requestContent = streamReader.ReadToEnd();

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