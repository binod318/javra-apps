using Enza.PAC.BusinessAccess.Interfaces;
using Enza.PAC.Entities;
using Enza.PAC.Web.Services.Core.Controllers;
using System.Threading.Tasks;
using System.Web.Http;

namespace Enza.PAC.Web.Services.Controllers
{
    [RoutePrefix("api/v1/Master")]    
    public class MasterController : BaseApiController
    {
        private readonly IMasterService _masterService;
        public MasterController(IMasterService masterService)
        {
            _masterService = masterService;
        }

        [Route("GetYear")]
        [HttpGet]
        [Authorize(Roles = AppRoles.PAC_PUBLIC)]
        public async Task<IHttpActionResult> GetYear()
        {
            var result = await _masterService.GetYearAsync();
            return Ok(result);
        }

        [Route("Getperiod")]
        [HttpGet]
        [Authorize(Roles = AppRoles.PAC_PUBLIC)]
        public async Task<IHttpActionResult> Getperiod(int year)
        {
            var result = await _masterService.GetperiodAsync(year);
            return Ok(result);
        }

        [Route("getCrops")]
        [HttpGet]
        [Authorize(Roles = AppRoles.PAC_PUBLIC)]
        public async Task<IHttpActionResult> GetCrops()
        {
            var result = await _masterService.GetCropAsync();
            return Ok(result);
        }

        [Route("GetMarkers")]
        [HttpGet]
        [Authorize(Roles = AppRoles.PAC_PUBLIC)]
        public async Task<IHttpActionResult> GetMarkers(string cropCode, string markerName, bool? showPacMarkers = null)
        {
            var result = await _masterService.GetMarkersAsync(cropCode, markerName, showPacMarkers);
            return Ok(result);
        }

        [Route("GetVarieties")]
        [HttpGet]
        [Authorize(Roles = AppRoles.PAC_PUBLIC)]
        public async Task<IHttpActionResult> GetVarieties(string cropCode, string varietyName)
        {
            var result = await _masterService.GetVarietiesAsync(cropCode, varietyName);
            return Ok(result);
        }
    }
}
