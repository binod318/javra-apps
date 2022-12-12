using Enza.PAC.BusinessAccess.Interfaces;
using Enza.PAC.Entities;
using Enza.PAC.Entities.Args;
using Enza.PAC.Web.Services.Core.Controllers;
using System.Threading.Tasks;
using System.Web.Http;

namespace Enza.PAC.Web.Services.Controllers
{
    [RoutePrefix("api/v1/criteriapercrop")]
    [Authorize(Roles = AppRoles.PAC_APPROVE_CALC_RESULTS)]
    public class CriteriaPerCropController : BaseApiController
    {
        private readonly ICriteriaPerCropService _criteriaPerCropService;
        public CriteriaPerCropController(ICriteriaPerCropService criteriaPerCropService)
        {
            _criteriaPerCropService = criteriaPerCropService;
        }

        [HttpPost]
        [Route("getdata")]        
        public async Task<IHttpActionResult> GetAllCriteriaPerCrop([FromBody] GetCriteriaPerCropRequestArgs args)
        {
            if (args == null)
                return InvalidRequest("Please provide required parameters.");

            var result = await _criteriaPerCropService.GetAllCriteriaPerCropAsync(args);
            return Ok(result);
        }

        [HttpPost]
        [Route("")]
        public async Task<IHttpActionResult> PostCriteriaPerCrop([FromBody] CriteriaPerCropRequestArgs args)
        {
            if (args == null)
                return InvalidRequest("Please provide required parameters.");

            var result = await _criteriaPerCropService.PostAsync(args);

            return Ok(result);
        }
    }
}
