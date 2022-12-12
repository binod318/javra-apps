using Enza.PtoV.BusinessAccess.Interfaces;
using Enza.PtoV.Entities.Args;
using System.Threading.Tasks;
using System.Web.Http;
using Enza.PtoV.Web.Services.Models;

namespace Enza.PtoV.Web.Services.Controllers
{
    [Authorize(Roles = AppRoles.PTOV_USER)]
    [RoutePrefix("api/v1/traitScreening")]
    public class TraitScreeningController : BaseApiController
    {
        private readonly ITraitScreeningService _service;
        public TraitScreeningController(ITraitScreeningService service)
        {
            _service = service;
        }
        [HttpPost]
        [Route("gettraitScreening")]
        public async Task<IHttpActionResult> GetTraitScreening([FromBody] TraitScreeningRequestArgs args)
        {
            var data = await _service.GetTraitScreeningAsync(args);
            return Ok(new
            {
                data,
                TotalRows = args.TotalRows
            });
        }        
        [HttpPost]
        [Route("gettraitScreeningResult")]
        public async Task<IHttpActionResult> GetTraitScreeningResult([FromBody] TraitScreeningRequestArgs args)
        {
            var data = await _service.GetTraitScreeningResultAsync(args);
            return Ok(new
            {
                data,
                TotalRows = args.TotalRows
            });
        }
        [HttpGet]
        [Route("getScreening")]
        public async Task<IHttpActionResult> GetScreening(string screeningFieldLabel, string cropCode)
        {
            var data = await _service.GetScreeningAsync(screeningFieldLabel, cropCode);
            return Ok(data);
        }
        [HttpGet]
        [Route("getTraits")]
        public async Task<IHttpActionResult> GetTraits(string traitName, string cropCode)
        {
            var data = await _service.GetTraitsAsync(traitName, cropCode);
            return Ok(data);
        }
        [HttpGet]
        [Route("getTraitLOV")]
        public async Task<IHttpActionResult> GetTraitLOV(int traitID)
        {
            var data = await _service.GetTraitLOVAsync(traitID);
            return Ok(data);
        }

        [HttpGet]
        [Route("getScreeningLOV")]
        public async Task<IHttpActionResult> GetScreeningLOV(int screeningFieldID)
        {
            var data = await _service.GetScreeningLOVAsync(screeningFieldID);
            return Ok(data);
        }

        [HttpGet]
        [Route("getTraitsWithScreening")]
        public async Task<IHttpActionResult> GetTraitsWithScreening(string traitName, string cropCode)
        {
            var data = await _service.GetTraitsWithScreeningAsync(traitName, cropCode);
            return Ok(data);
        }
        [HttpPost]
        [Route("saveTraitScreening")]
        public async Task<IHttpActionResult> SaveTraitScreening([FromBody] SaveTraitScreeningRequestArgs args)
        {
            var data = await _service.SaveTraitScreeningAsync(args);
            return Ok(data);
        }
        [HttpPost]
        [Route("saveTraitScreeningResult")]
        public async Task<IHttpActionResult> SaveTraitScreeningResult([FromBody] SaveTraitScreeningResultArgs args)
        {
            var data = await _service.SaveTraitScreeningResultAsync(args);
            return Ok(new
            {
                data,
                TotalRows = args.TotalRows
            });
        }

        [HttpPost]
        [Route("removeUnmappedColumns")]
        public async Task<IHttpActionResult> RemoveUnmappedColumns([FromBody] RemoveColumnsRequestArgs args)
        {
            var data = await _service.RemoveUnmappedColumns(args);
            return Ok(data);
            
        }
    }
}
