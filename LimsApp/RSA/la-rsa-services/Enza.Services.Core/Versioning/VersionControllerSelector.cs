using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using System.Web.Http.Controllers;
using System.Web.Http.Dispatcher;

namespace Enza.Services.Core.Versioning
{
    public class VersionControllerSelector : DefaultHttpControllerSelector
    {
        public VersionControllerSelector(HttpConfiguration configuration) : base(configuration)
        {
        }

        public override string GetControllerName(HttpRequestMessage request)
        {
            var controllerName = base.GetControllerName(request);
            if (request.Headers.Contains("X-Version"))
            {
                string headerValue = request.Headers.GetValues("X-Version").FirstOrDefault();
                //If the X-Version is 1 or 2 and if the ControllerName contains 'V or v' the return the controller
                if (!string.IsNullOrWhiteSpace(headerValue))
                {
                    var version = headerValue.Replace(".", string.Empty).Replace("-", string.Empty);
                    controllerName = $"{controllerName}V{version}";

                    HttpControllerDescriptor controllerDesc;
                    if (!GetControllerMapping().TryGetValue(controllerName, out controllerDesc))
                    {
                        var message =
                            "No HTTP resource was found for specified request URI {0} and version {1}";
                        throw new HttpResponseException(request.CreateErrorResponse(HttpStatusCode.NotFound,
                            string.Format(message, request.RequestUri, version)));
                    }
                }
            }
            return controllerName;
        }
    }
}
