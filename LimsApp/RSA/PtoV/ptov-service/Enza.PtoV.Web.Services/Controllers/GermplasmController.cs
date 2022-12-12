using Enza.PtoV.BusinessAccess.Interfaces;
using Enza.PtoV.Entities.Args;
using System.Threading.Tasks;
using System.Web.Http;
using System.Collections.Generic;
using Enza.PtoV.Web.Services.Models;

namespace Enza.PtoV.Web.Services.Controllers
{
    [Authorize(Roles = AppRoles.PTOV_USER)]
    [RoutePrefix("api/v1/germplasm")]
    public class GermplasmController : BaseApiController
    {
        private readonly IGermplasmService _service;
        public GermplasmController(IGermplasmService service)
        {
            _service = service;
        }
        [HttpPost]
        [Route("getgermplasm")]
        public async Task<IHttpActionResult> GetGermplasm([FromBody] GetGermplasmRequestArgs args)
        {
            var data = await _service.GetGermplasmAsync(args);
            return Ok(data);
        }

        [HttpPost]
        [Route("getmappedgermplasm")]
        public async Task<IHttpActionResult> GetMappedGermplasm([FromBody] GetGermplasmRequestArgs args)
        {
            var data = await _service.GetMappedGermplasmAsync(args);
            return Ok(data);
        }

        [HttpPost]
        [Route("deletegermplasm")]
        public async Task<IHttpActionResult> DeleteGermplasm([FromBody] DeleteGermplasmRequestArgs args)
        {
            var data = await _service.DeleteGermplasmAsync(args);
            return Ok(data);
        }

        [HttpPost]
        [Route("raciprocate")]
        public async Task<IHttpActionResult> Raciprocate([FromBody] List<int> varietyIDs)
        {
            await _service.Raciprocate(varietyIDs);
            return Ok();
        }
    }
}
