using System.Net;
using System.Net.Http;
using System.Text;
using System.Web.Http;
using System.Web.Http.Results;

namespace Enza.PtoV.Web.Services.Controllers
{
    [Authorize]
    public class BaseApiController : ApiController
    {
        protected ResponseMessageResult InvalidRequest(string message)
        {
            return InvalidRequest(message, false);
        }

        protected ResponseMessageResult InvalidRequest(string message, bool showGenericError)
        {
            var error = new HttpError
            {
                {"errorType", showGenericError ? 1 : 2},
                {"code", string.Empty},
                {"message", message}
            };
            var response = Request.CreateErrorResponse(System.Net.HttpStatusCode.BadRequest, error);
            response.ReasonPhrase = "Bad Request";
            return new ResponseMessageResult(response);
        }

        protected ResponseMessageResult UnAuthorized(string message)
        {
            var error = new HttpError
            {
                {"errorType", 2},
                {"code", string.Empty},
                {"message", message}
            };
            var response = Request.CreateErrorResponse(System.Net.HttpStatusCode.Unauthorized, error);
            return new ResponseMessageResult(response);
        }
        
        protected IHttpActionResult Json(string dataAsJson)
        {
            var response = Request.CreateResponse(HttpStatusCode.OK);
            response.Content = new StringContent(dataAsJson, Encoding.UTF8, "application/json");
            return ResponseMessage(response);
        }
    }
}
