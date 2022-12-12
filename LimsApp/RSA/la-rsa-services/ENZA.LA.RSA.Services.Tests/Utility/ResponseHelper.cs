using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using System.Web.Http.Results;

namespace ENZA.LA.RSA.Services.Tests.Utility
{
    public static class ResponseHelper
    {
        public static async Task<ResponseMessageResult> CreateResponse(string message)
        {
            await Task.Delay(0);
            var sb = new StringBuilder();
            sb.Append(message);
            var content = new StringContent(sb.ToString());
            
            content.Headers.ContentType = new MediaTypeHeaderValue("application/json");
            var response = new HttpResponseMessage { Content = content };
            return new ResponseMessageResult(response);
        }

        public static ResponseMessageResult CreateResponseSync(string message)
        {
            var sb = new StringBuilder();
            sb.Append(message);
            var content = new StringContent(sb.ToString());

            content.Headers.ContentType = new MediaTypeHeaderValue("application/json");
            var response = new HttpResponseMessage { Content = content };
            return new ResponseMessageResult(response);
        }
    }
}
