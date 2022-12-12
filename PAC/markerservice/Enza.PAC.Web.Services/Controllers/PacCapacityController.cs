using Enza.PAC.BusinessAccess.Interfaces;
using Enza.PAC.Entities;
using Enza.PAC.Entities.Args;
using Enza.PAC.Web.Services.Core.Controllers;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Web.Http;

namespace Enza.PAC.Web.Services.Controllers
{
    [RoutePrefix("api/v1/PacCapacity")]    
    public class PacCapacityController : BaseApiController
    {
        private readonly IPacCapacityService _pacCapacityService;
        public PacCapacityController(IPacCapacityService pacCapacityService)
        {
            _pacCapacityService = pacCapacityService;
        }
        /// <summary>
        /// Get capacity planning for requested year
        /// </summary>
        /// <param name="year">4 digit year</param>
        /// <returns></returns>

        [Route("GetPACLabCapacity")]
        [HttpGet]
        [Authorize(Roles = AppRoles.PAC_HANDLE_LAB_CAPACITY)]
        public async Task<IHttpActionResult> GetLabCapacity(int year)
        {
            var result = await _pacCapacityService.GetPlanningCapacityAsync(year);
            return Ok(result);
        }
        /// <summary>
        /// Save capacity planning
        /// </summary>
        /// <param name="args">
        /// request parameter accept list of array of capacity 
        /// </param>
        /// <returns></returns>

        [Route("SavePACLabCapacity")]
        [HttpPost]
        [Authorize(Roles = AppRoles.PAC_HANDLE_LAB_CAPACITY)]
        public async Task<IHttpActionResult> SaveLabCapacity(List<SaveCapacityRequestArgs> args)
        {
            var result = await _pacCapacityService.SaveLabCapacityAsync(args);
            return Ok(result);
        }

        /// <summary>
        /// Service will fetch planning capacity so per crop per method per week.
        /// </summary>
        /// <param name="periodID">Period id is ID of week defined period table</param>
        /// <returns></returns>

        [Route("GetPACPlanningCapacitySO")]
        [HttpGet]
        [Authorize(Roles = AppRoles.PAC_SO_HANDLE_CROP_CAPACITY)]
        public async Task<IHttpActionResult> GetPACPlanningCapacitySO(int periodID)
        {
            var result = await _pacCapacityService.GetPACPlanningCapacitySOAsync(periodID);
            return Ok(result);
        }

        /// <summary>
        /// save change of capacity planning SO per week per crop per method, 
        /// </summary>
        /// <param name="args">
        /// args accept parameter in list.
        /// </param>
        /// <returns></returns>
        [Route("SavePACPlanningCapacitySO")]
        [HttpPost]
        [Authorize(Roles = AppRoles.PAC_SO_HANDLE_CROP_CAPACITY)]
        public async Task<IHttpActionResult> SavePACPlanningCapacitySO(List<SavePlanningCapacitySOArgs> args)
        {
            var result = await _pacCapacityService.SavePACPlanningCapacitySOAsync(args);
            return Ok(result);
        }
    }
}
