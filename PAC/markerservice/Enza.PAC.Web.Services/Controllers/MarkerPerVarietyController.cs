using Enza.PAC.BusinessAccess.Interfaces;
using Enza.PAC.Entities;
using Enza.PAC.Entities.Args;
using Enza.PAC.Web.Services.Core.Controllers;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Web.Http;

namespace Enza.PAC.Web.Services.Controllers
{
    [RoutePrefix("api/v1/MarkerPerVariety")]    
    public class MarkerPerVarietyController : BaseApiController
    {
        private readonly IVarietyService _varietyService;
        public MarkerPerVarietyController(IVarietyService varietyService)
        {
            _varietyService = varietyService;
        }

        [Route("GetMarkerPerVarieties")]
        [HttpPost]
        [Authorize(Roles = AppRoles.PAC_PUBLIC)]
        public async Task<IHttpActionResult> GetMarkerPerVarieties(GetMarkerPerVarietyRequestArgs args)
        {
            var result = await _varietyService.GetMarkerPerVarietiesAsync(args);
            return Ok(result);
        }

        [Route("SaveMarkerPerVarieties")]
        [HttpPost]
        [Authorize(Roles = AppRoles.PAC_HANDLE_LAB_CAPACITY)]
        public async Task<IHttpActionResult> SaveMarkerPerVarieties(IEnumerable<SaveMarkerPerVarietyRequestArgs> args)
        {
            var result = await _varietyService.SaveMarkerPerVarietiesAsync(args);
            return Ok(result);
        }
    }
}
