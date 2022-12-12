using Enza.PAC.BusinessAccess.Interfaces;
using Enza.PAC.Entities.Args;
using Enza.PAC.Web.Services.Core.Controllers;
using System.Threading.Tasks;
using System.Web.Http;

namespace Enza.PAC.Web.Services.Controllers
{
    [Authorize]
    [RoutePrefix("api/v1/externalapi")]
    public class ExternalApiController : BaseApiController
    {
        private readonly IExternalApiService _externalApiService;
        public ExternalApiController(IExternalApiService externalApiService)
        {
            _externalApiService = externalApiService;
        }

        [HttpPost]
        [Route("getplatesampleinfo")]
        public async Task<IHttpActionResult> GetPlateSampleInfo([FromBody] GetPlateSampleInfoRequestArgs requestArgs)
        {
            if (requestArgs == null)
                return InvalidRequest("Please provide required parameters.");

            var result = await _externalApiService.GetPlateSampleInfoAsync(requestArgs);
            return Ok(result);
        }
    }
}
