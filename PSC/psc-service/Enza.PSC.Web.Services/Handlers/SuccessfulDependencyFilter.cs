using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights.Extensibility;

namespace Enza.PSC.Web.Services.Handlers
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
                if (request.Type == "Http" && (request.Name == "POST /" || request.Name == "POST /PscServices/"))
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
            }

            this.Next.Process(item);
        }
    }
}