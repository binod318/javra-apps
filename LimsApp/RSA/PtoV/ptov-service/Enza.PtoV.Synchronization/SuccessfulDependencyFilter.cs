using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights.Extensibility;

namespace Enza.PtoV.Synchronization
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
                // filter out automatic dependency call of cordys because we've added manual code for dependency tracking
                if (request.Name.Contains("cordys") || request.Target.Contains("cordys"))
                {
                    if (string.IsNullOrEmpty(request.ResultCode) || request.ResultCode == "401")
                        return;

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

            this.Next.Process(item);
        }
    }
   


    //public class SuccessfulDependencyFilter : ITelemetryProcessor
    //{
    //    private ITelemetryProcessor Next { get; set; }

    //    // next will point to the next TelemetryProcessor in the chain.
    //    public SuccessfulDependencyFilter(ITelemetryProcessor next)
    //    {
    //        this.Next = next;
    //    }

    //    public void Process(ITelemetry item)
    //    {
    //        // To filter out an item, return without calling the next processor.
    //        if (!OKtoSend(item)) { return; }

    //        this.Next.Process(item);
    //    }

    //    // Example: replace with your own criteria.
    //    private bool OKtoSend(ITelemetry item)
    //    {
    //        var dependency = item as DependencyTelemetry;
    //        if (dependency == null) return true;

    //        return dependency.Success != true;
    //    }
    //}
}