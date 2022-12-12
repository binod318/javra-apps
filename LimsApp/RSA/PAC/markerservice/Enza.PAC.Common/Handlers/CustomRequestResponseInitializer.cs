using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights.Extensibility;
using System.IO;
using System.Web;

namespace Enza.PAC.Common.Handlers
{
    public class CustomRequestResponseInitializer : ITelemetryInitializer
    {
        private const string RequestBodyProperty = "RequestBody";

        public void Initialize(ITelemetry telemetry)
        {
            if (string.IsNullOrEmpty(telemetry.Context.Cloud.RoleName))
            {
                //set custom role name here
                telemetry.Context.Cloud.RoleName = "PAC-API";
            }

            var requestTelemetry = telemetry as RequestTelemetry;

            if (requestTelemetry == null || HttpContext.Current == null)
            {
                return;
            }

            if (requestTelemetry.Name == "POST /" || requestTelemetry.Name == "GET /" ||
                requestTelemetry.Name == "POST /PacServices/" || requestTelemetry.Name == "GET /PacServices/")
            {
                return;
            }

            var request = HttpContext.Current.Request;
            //var response = HttpContext.Current.Response;

            //var user = request.RequestContext?.HttpContext?.User?.Identity?.Name;

            //if (string.IsNullOrEmpty(user))
            //{
            //    //set Auth user id
            //    requestTelemetry.Context.User.AuthenticatedUserId = user;
            //}

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

            //if (responseCode < 400) // non-success status code
            //{
            //    return;
            //}

            //var stream1 = request.GetBufferedInputStream();
            //var stream = request.GetBufferlessInputStream();

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
