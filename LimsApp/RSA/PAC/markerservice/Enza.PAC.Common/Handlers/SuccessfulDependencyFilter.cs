using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights.Extensibility;
using System.Web;

namespace Enza.PAC.Common.Handlers
{
    public class SuccessfulDependencyFilter : ITelemetryProcessor
    {
        private ITelemetryProcessor Next { get; set; }

        // next will point to the next TelemetryProcessor in the chain.
        public SuccessfulDependencyFilter(ITelemetryProcessor next)
        {
            this.Next = next;
        }

        public void Process(ITelemetry item)
        {
            if (item is DependencyTelemetry request && request.ResultCode != null)
            {
                //skip duplicate dependency for API
                if (request.Type == "Http" && ( request.Name == "POST /" || request.Name == "POST /PacServices/"))
                    return;

                if (request.Type == "SQL")
                {
                    //skip duplicate dependency for SQL that doesn't have procedure name or query
                    if (string.IsNullOrEmpty(request.Data))
                        return;

                    var procedureProperty = "Query";

                    if (request.Properties.ContainsKey(procedureProperty))
                    {
                        request.Properties[procedureProperty] = request.Data;
                    }
                    else
                    {
                        request.Properties.Add(procedureProperty, request.Data);
                    }
                }

                // filter out automatic dependency call of cordys because we've added manual code for dependency tracking
                if (request.Name.Contains("cordys") || (!string.IsNullOrWhiteSpace(request.Target) && request.Target.Contains("cordys")))
                {
                    if (string.IsNullOrEmpty(request.ResultCode) || request.ResultCode == "401")
                        return;

                    //if (request.ResultCode == "200")
                    //    request.Success = true;

                    var data = request.Data;
                    string[] payload = data.Split(new[] { "|||" }, System.StringSplitOptions.None);

                    //Add custom properties 
                    var urlProperty = "Url";
                    var requestProperty = "Request";
                    var responseProperty = "Response";

                    if (request.Properties.ContainsKey(requestProperty))
                    {
                        request.Properties[requestProperty] = payload[0];
                    }
                    else
                    {
                        request.Properties.Add(requestProperty, payload[0]);
                    }

                    if (request.Properties.ContainsKey(urlProperty))
                    {
                        request.Properties[urlProperty] = request.Target;
                    }
                    else
                    {
                        request.Properties.Add(urlProperty, request.Target);
                    }

                    if (request.Properties.ContainsKey(responseProperty))
                    {
                        request.Properties[responseProperty] = payload[1];
                    }
                    else
                    {
                        request.Properties.Add(responseProperty, payload[1]);
                    }
                }
                //ABS
                else if (request.Name.Contains("ABSConnectService") || request.Name.Contains("IABSQualityConnect"))
                {
                    if (request.ResultCode == "200")
                        request.Success = true;

                    var data = request.Data;
                    string[] payload = data.Split(new[] { "|||" }, System.StringSplitOptions.None);

                    //Add custom properties 
                    var urlProperty = "Url";
                    var requestProperty = "Request";
                    var responseProperty = "Response";

                    if (request.Properties.ContainsKey(requestProperty))
                    {
                        request.Properties[requestProperty] = payload[0];
                    }
                    else
                    {
                        request.Properties.Add(requestProperty, payload[0]);
                    }

                    if (request.Properties.ContainsKey(urlProperty))
                    {
                        request.Properties[urlProperty] = request.Target;
                    }
                    else
                    {
                        request.Properties.Add(urlProperty, request.Target);
                    }

                    if (request.Properties.ContainsKey(responseProperty))
                    {
                        request.Properties[responseProperty] = payload[1];
                    }
                    else
                    {
                        request.Properties.Add(responseProperty, payload[1]);
                    }
                }
            }

            if (item is RequestTelemetry requestTelemetry)
            {

                //var request1 = HttpContext.Current.Request;
                //var response = HttpContext.Current.Response;

                if (requestTelemetry.Name == "POST /" || requestTelemetry.Name == "GET /" || 
                    requestTelemetry.Name == "POST /PacServices/" || requestTelemetry.Name == "GET /PacServices/")
                {
                    return;
                }
            }

            this.Next.Process(item);
        }
    }
}
