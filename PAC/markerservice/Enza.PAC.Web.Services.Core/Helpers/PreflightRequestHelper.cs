using System.Net;
using System.Web;

namespace Enza.PAC.Web.Services.Core.Helpers
{
    public class PreflightRequestHelper
    {
        public static void HandlePreflightRequest(HttpApplication app)
        {
            var request = app.Request;
            var response = app.Response;
            if (request.HttpMethod == "OPTIONS")
            {
                var origin = request.Headers.Get("Origin");
                if (!string.IsNullOrWhiteSpace(origin))
                {
                    response.AddHeader("Cache-Control", "no-cache");
                    response.AddHeader("Access-Control-Allow-Origin", origin);
                    response.AddHeader("Access-Control-Allow-Credentials", "true");
                    response.AddHeader("Access-Control-Allow-Methods", "GET,HEAD,POST,PUT,DELETE,CONNECT,OPTIONS,TRACE,PATCH");
                    response.AddHeader("Access-Control-Allow-Headers", "Authorization,enzauth,X-Version,origin,Content-Type,Accept,Traceparent,Request-Id, Request-Context");
                    response.AddHeader("Access-Control-Max-Age", int.MaxValue.ToString());
                    response.StatusCode = (int)HttpStatusCode.OK;
                    app.CompleteRequest();
                }
            }
        }
    }
}
