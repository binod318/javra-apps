using Enza.PAC.BusinessAccess.Interfaces;
using Enza.PAC.Entities;
using Enza.PAC.Entities.Args;
using Enza.PAC.Web.Services.Core.Controllers;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Web.Http;

namespace Enza.PAC.Web.Services.Controllers
{
    [RoutePrefix("api/v1/DeterminationAssignments")]    
    public class DeterminationAssignmentsController : BaseApiController
    {
        private readonly IDeterminationAssignmentService _determinationAssignmentService;
        public DeterminationAssignmentsController(IDeterminationAssignmentService determinationAssignmentService)
        {
            _determinationAssignmentService = determinationAssignmentService;
        }

        [HttpGet]
        [Route("")]
        [Authorize(Roles = AppRoles.PAC_SO_HANDLE_CROP_CAPACITY + "," + AppRoles.PAC_SO_PLAN_BATCHES)]
        public async Task<IHttpActionResult> GetDeterminationAssignments([FromUri]GetDeterminationAssignmentsRequestArgs requestArgs)
        {
            if (requestArgs == null)
                return InvalidRequest("Please provide required parameters.");

            var result = await _determinationAssignmentService.GetDeterminationAssignmentsAsync(requestArgs);
            return Ok(result);
        }

        [HttpPost]
        [Route("AutomaticalPlan")]
        [Authorize(Roles = AppRoles.PAC_SO_HANDLE_CROP_CAPACITY + "," + AppRoles.PAC_SO_PLAN_BATCHES)]
        public async Task<IHttpActionResult> AutomaticalPlan([FromBody]AutomaticalPlanRequestArgs requestArgs)
        {
            if (requestArgs == null)
                return InvalidRequest("Please provide required parameters.");

            await _determinationAssignmentService.PlanDeterminationAssignmentsAsync(requestArgs);            
            return Ok();
        }

        [HttpPost]
        [Route("Confirmplanning")]
        [Authorize(Roles = AppRoles.PAC_SO_HANDLE_CROP_CAPACITY + "," + AppRoles.PAC_SO_PLAN_BATCHES)]
        public async Task<IHttpActionResult> ConfirmPlanning([FromBody]ConfirmPlanningRequestArgs requestArgs)
        {
            if (requestArgs == null)
                return InvalidRequest("Please provide required parameters.");

            var result = await _determinationAssignmentService.ConfirmPlanningAsync(requestArgs);
            return Ok(result);
        }

        [HttpPost]
        [Route("Overview")]
        [Authorize(Roles = AppRoles.PAC_LAB_EMPLOYEE + "," + AppRoles.PAC_APPROVE_CALC_RESULTS + "," + AppRoles.PAC_SO_VIEWER)]
        public async Task<IHttpActionResult> GetDAOverview(BatchOverviewRequestArgs requestArgs)
        {
            if (requestArgs == null || requestArgs.PageSize <= 0 || requestArgs.PageNr <=0)
                return InvalidRequest("Please provide valid parameters.");

            var data = await _determinationAssignmentService.GetDAOverviewAsync(requestArgs);
            return Ok(new
            {
                Data = new
                {
                    Data = data.Tables[1],
                    Columns = data.Tables[0]
                },
                Total = requestArgs.TotalRows
            }
            );
        }

        [HttpPost]
        [Route("SetDeterminationAssignment")]
        [Authorize(Roles = AppRoles.PAC_SO_HANDLE_CROP_CAPACITY + "," + AppRoles.PAC_SO_PLAN_BATCHES)]
        public async Task<IHttpActionResult> SetDeterminationAssignments([FromUri]GetDAOverviewRequestArgs requestArgs)
        {
            if (requestArgs == null)
                return InvalidRequest("Please provide required parameters.");

            var result = await _determinationAssignmentService.SetDeterminationAssignmentsAsync(requestArgs);
            return Ok(result);
        }

        [HttpGet]
        [Route("decision")]
        [Authorize(Roles = AppRoles.PAC_LAB_EMPLOYEE + "," + AppRoles.PAC_APPROVE_CALC_RESULTS + "," + AppRoles.PAC_SO_VIEWER)]
        public async Task<IHttpActionResult> GetDataForDecisionScreen(int id)
        {
            if (id == 0)
                return InvalidRequest("Please provide required parameters.");

            var result = await _determinationAssignmentService.GetDataForDecisionScreenAsync(id);
            return Ok(result);
        }

        [HttpPost]
        [Route("decisiondetail")]
        [Authorize(Roles = AppRoles.PAC_LAB_EMPLOYEE + "," + AppRoles.PAC_APPROVE_CALC_RESULTS + "," + AppRoles.PAC_SO_VIEWER)]
        public async Task<IHttpActionResult> GetDataForDecisionDetailScreen([FromBody]GetDataForDecisionDetailRequestArgs requestArgs)
        {
            if (requestArgs == null)
                return InvalidRequest("Please provide required parameters.");

            var result = await _determinationAssignmentService.GetDataForDecisionDetailScreenAsync(requestArgs);
            return Ok(result);
        }

        [HttpGet]
        [Route("platespositions")]
        [Authorize(Roles = AppRoles.PAC_LAB_EMPLOYEE + "," + AppRoles.PAC_APPROVE_CALC_RESULTS + "," + AppRoles.PAC_SO_VIEWER)]
        public async Task<IHttpActionResult> GetPlatesAndPositionsForPattern (int patternID)
        {
            if (patternID == 0)
                return InvalidRequest("Please provide required parameters.");

            var result = await _determinationAssignmentService.GetPlatesAndPositionsForPatternAsync(patternID);
            return Ok(result);
        }

        [HttpPost]
        [Route("savepatternremarks")]
        [Authorize(Roles = AppRoles.PAC_LAB_EMPLOYEE + "," + AppRoles.PAC_APPROVE_CALC_RESULTS + "," + AppRoles.PAC_SO_VIEWER)]
        public async Task<IHttpActionResult> SavePatternRemarks([FromBody] List<UpdatePatternRemarksRequestArgs> requestArgs)
        {
            if (requestArgs == null)
                return InvalidRequest("Please provide required parameters.");

            var result = await _determinationAssignmentService.SavePatternRemarksAsync(requestArgs);
            return Ok(result);
        }

        [HttpPost]
        [Route("sendresulttoabs")]
        [Authorize(Roles = AppRoles.PAC_APPROVE_CALC_RESULTS)]
        public async Task<IHttpActionResult> SendResultToABS([FromUri]SendResultToABSRequestArgs requestArgs)
        {
            if (requestArgs == null)
                return InvalidRequest("Please provide required parameters.");

            var result = await _determinationAssignmentService.SendResultToABSAsync(requestArgs);
            return Ok(result);
        }

        [HttpPost]
        [Route("ApproveDetAssignment")]
        [Authorize(Roles = AppRoles.PAC_APPROVE_CALC_RESULTS)]
        public async Task<IHttpActionResult> ApproveDetAssignment([FromBody] UpdateDeterminationID args)
        {
            if (args == null)
                return InvalidRequest("Please provide required parameters.");

            return Ok(await _determinationAssignmentService.ApproveDeterminationAsync(args.detAssignmentID));
        }

        [HttpPost]
        [Route("ReTestDetAssignment")]
        [Authorize(Roles = AppRoles.PAC_LAB_EMPLOYEE + "," + AppRoles.PAC_APPROVE_CALC_RESULTS)]
        public async Task<IHttpActionResult> RetestDetAssignment([FromBody] UpdateDeterminationID args)
        {
            return Ok(await _determinationAssignmentService.RetestDetAssignmentAsync(args.detAssignmentID));

        }

        [HttpPost]
        [Route("UpdateRemarks")]
        [Authorize(Roles = AppRoles.PAC_LAB_EMPLOYEE + "," + AppRoles.PAC_APPROVE_CALC_RESULTS)]
        public async Task<IHttpActionResult> UpdateRemarks([FromBody] UpdateRemarksRequestArgs args)
        {
            if (args == null)
                return InvalidRequest("Please provide required parameters.");

            return Ok(await _determinationAssignmentService.UpdateRemarksAsync(args));
        }
    }
}
