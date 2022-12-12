using System.Threading.Tasks;
using System.Web.Http;
using Enza.PtoV.BusinessAccess.Interfaces;
using Enza.PtoV.Entities.Args;

namespace Enza.PtoV.Web.Services.Controllers
{
    [RoutePrefix("api/v2/Varieties")]
    public class VarietiesV2Controller : BaseApiController
    {
        private readonly IVarietyService _varietyService;
        public VarietiesV2Controller(IVarietyService varietyService)
        {
            _varietyService = varietyService;
        }

        [Route("replaceLOT")]
        [HttpPost]
        public async Task<IHttpActionResult> ReplaceLOTV2([FromBody] ReplaceLotRequestArgs args)
        {
            var res = await _varietyService.ReplaceLOTAsync(Request, args);
            return Ok(res);
        }

        [Route("undoReplaceLOT")]
        [HttpPost]
        public async Task<IHttpActionResult> UndoReplaceLOTV2([FromBody] UndoReplaceLotRequestArgs args)
        {
            var res = await _varietyService.UndoReplaceLOTAsync(args);
            return Ok(res);
        }
    }
}
