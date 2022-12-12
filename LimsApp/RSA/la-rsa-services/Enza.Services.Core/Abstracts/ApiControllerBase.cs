using System.IO;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Web.Http;
using Enza.Services.Core.Serialization;
using Newtonsoft.Json;

namespace Enza.Services.Core.Abstracts
{
    //[Authorize]
    public abstract class ApiControllerBase : ApiController
    {
        protected IHttpActionResult JsonResult<T>(T entity)
        {
            var sb = new StringBuilder();
            using (var sw = new StringWriter(sb))
            {
                using (var writer = new NullJsonWriter(sw))
                {
                    var serializer = new JsonSerializer
                    {
                        NullValueHandling = NullValueHandling.Include,
                        Formatting = Formatting.Indented,
                        DateFormatString = "dd-MM-yyyy"
                    };
                    serializer.Serialize(writer, entity);
                }
            }
            var content = new StringContent(sb.ToString());
            sb.Clear();

            content.Headers.ContentType = new MediaTypeHeaderValue("application/json");
            var response = new HttpResponseMessage { Content = content };
            return ResponseMessage(response);
        }
    }
}
