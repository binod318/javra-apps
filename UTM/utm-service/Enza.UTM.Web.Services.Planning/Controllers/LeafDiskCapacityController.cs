using Enza.UTM.BusinessAccess.Interfaces;
using Enza.UTM.BusinessAccess.Planning.Interfaces;
using Enza.UTM.Entities.Args;
using Enza.UTM.Web.Services.Core.Controllers;
using System.Threading.Tasks;
using System.Web.Http;

namespace Enza.UTM.Web.Services.Planning.Controllers
{
    [RoutePrefix("api/v1/leafdisk/Capacity")]
    public class LeafDiskCapacityController : BaseApiController
    {
        private readonly ILeafDiskCapacityService capacityService;
        private readonly IMasterService _masterService;
        public LeafDiskCapacityController(ILeafDiskCapacityService capacityService, IMasterService masterService)
        {
            this.capacityService = capacityService;
            _masterService = masterService;
        }

        //[Authorize(Roles = AppRoles.HANDLE_LAB_CAPACITY_LEAFDISK)]
        [Route("get")]
        [HttpGet]
        public async Task<IHttpActionResult> Get(int year, int siteLocation)
        {
            var data = await capacityService.GetCapacityAsync(year,siteLocation);
            return Ok(data);
        }

        [Route("save")]
        [HttpPost]
        //[Authorize(Roles = AppRoles.HANDLE_LAB_CAPACITY_LEAFDISK)]
        public async Task<IHttpActionResult> SaveCapacity([FromBody] SaveCapacityRequestArgs args)
        {
            var data = await capacityService.SaveCapacityAsync(args);
            return Ok(data);
        }

        [HttpGet]
        [Route("getApprovalListForLab")]
        //[Authorize(Roles = AppRoles.HANDLE_LAB_CAPACITY)]
        public async Task<IHttpActionResult> GetApprovalListForLab(int periodID, int siteID)
        {
            var data = await capacityService.GetPlanApprovalListForLabAsync(periodID, siteID);
            return Ok(data);
        }
    }
}
