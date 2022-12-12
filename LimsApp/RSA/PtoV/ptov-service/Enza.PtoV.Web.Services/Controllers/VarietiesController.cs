using System.Threading.Tasks;
using System.Web.Http;
using Enza.PtoV.BusinessAccess.Interfaces;
using Enza.PtoV.Entities.Args;

namespace Enza.PtoV.Web.Services.Controllers
{
    [RoutePrefix("api/v1/Varieties")]
    public class VarietiesController : BaseApiController
    {
        private readonly IVarietyService _varietyService;
        public VarietiesController(IVarietyService varietyService)
        {
            _varietyService = varietyService;
        }

        [Route("updateProductSegments")]
        [HttpPost]
        public async Task<IHttpActionResult> UpdateProductSegments(
            UpdateProductSegmentsRequestArgs requestArgs)
        {
            await _varietyService.UpdateProductSegmentsAsync(requestArgs);
            return Ok(true);
        }

        [Route("replaceLOT")]
        [HttpPost]
        public async Task<IHttpActionResult> ReplaceLOT([FromBody] ReplaceLotRequestArgs args)
        {
            var res = await _varietyService.ReplaceLOTAsync(args.GID,args.LotGID);
            return Ok(res);
        }

        [Route("replaceLOTLookup")]
        [HttpGet]
        public async Task<IHttpActionResult> ReplaceLOTLookup(int GID)
        {
            var res = await _varietyService.ReplaceLOTLookupAsync(GID);
            return Ok(res);
        }
    }
}
