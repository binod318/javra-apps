using Enza.PAC.Common.Extensions;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;

namespace Enza.PAC.Web.Services.Core.Handlers
{
    public class LogRequestAndResponseHandler : DelegatingHandler
    {
        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            // log request body
            string requestBody = await request.Content.ReadAsStringAsync();
            Log4NetExtensions.LogDebug(this, new System.Exception(requestBody));
            //Trace.WriteLine(requestBody);

            // let other handlers process the request
            var result = await base.SendAsync(request, cancellationToken);

            if (result.Content != null)
            {
                // once response body is ready, log it
                var responseBody = await result.Content.ReadAsStringAsync();
                Log4NetExtensions.LogDebug(this, new System.Exception(responseBody));
                //Trace.WriteLine(responseBody);
            }
            return result;
        }
    }
}