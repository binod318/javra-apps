using Enza.PAC.BusinessAccess.Interfaces;
using Enza.PAC.Entities;
using Enza.PAC.Entities.Args;
using Enza.PAC.Web.Services.Core.Controllers;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.Web.Http;

namespace Enza.PAC.Web.Services.Controllers
{
    [RoutePrefix("api/v1/Test")]    
    public class TestController : BaseApiController
    {
        private readonly ITestService _testService;
        public TestController(ITestService testService)
        {
            _testService = testService;
        }

        [HttpGet]
        [Route("GetFolderDetails")]
        [Authorize(Roles = AppRoles.PAC_MANAGE_LAB_PREPARATION)]
        public async Task<IHttpActionResult> GetFolderDetails(int periodID)
        {
            if (periodID <= 0)
                return InvalidRequest("Please provide required parameters.");           

            var result = await _testService.GetFolderDetailsAsync(periodID);
            return Ok(result);
        }

        //[HttpPost]
        //[Route("GenerateFolderDetails")]
        //[Authorize(Roles = AppRoles.PAC_MANAGE_LAB_PREPARATION)]
        //public async Task<IHttpActionResult> GenerateFolderDetails([FromBody]GenerateFolderDetailsRequestArgs requestArgs)
        //{
        //    if (requestArgs == null)
        //        return InvalidRequest("Please provide required parameters.");

        //    await _testService.GenerateFolderDetailsAsync(requestArgs);
        //    return Ok();
        //}

        [HttpGet]
        [Route("GetDeclusterResult")]
        [Authorize(Roles = AppRoles.PAC_MANAGE_LAB_PREPARATION)]
        public async Task<IHttpActionResult> GetDeclusterResult(int periodID, int detAssignmentID)
        {
            if (periodID <= 0 || detAssignmentID <= 0)
                return InvalidRequest("Please provide required parameters.");

            var result = await _testService.GetDeclusterResultAsync(periodID, detAssignmentID);
            return Ok(result);
        }

        [HttpPost]
        [Route("ReservePlatesInLIMS")]
        [Authorize(Roles = AppRoles.PAC_REQUEST_LIMS)]
        public async Task<IHttpActionResult> ReservePlatesInLims(ReservePlatesInLIMSRequestArgs requestArgs)
        {
            if (requestArgs == null)
                return InvalidRequest("Please provide required parameters.");

            var result = await _testService.ReservePlatesInLIMSAsync(requestArgs.PeriodID);
            return Ok(result);
        }

        [HttpGet]
        [Route("GetMinimumTestStatus")]
        [Authorize(Roles = AppRoles.PAC_MANAGE_LAB_PREPARATION)]
        public async Task<IHttpActionResult> GetMinimumTestStatusPerPeriod(int periodID)
        {
            if (periodID <= 0)
                return InvalidRequest("Please provide required parameters.");

            var result = await _testService.GetMinimumTestStatusPerPeriodAsync(periodID);
            return Ok(result);
        }

        [HttpPost]
        [Route("SendToLIMS")]
        [Authorize(Roles = AppRoles.PAC_REQUEST_LIMS)]
        public async Task<IHttpActionResult> SendToLims(ReservePlatesInLIMSRequestArgs requestArgs)
        {
            if (requestArgs ==  null)
                return InvalidRequest("Please provide required parameters.");

            var result = await _testService.SendToLIMSAsync(requestArgs.PeriodID,0);
            return Ok(result);
        }

        [HttpPost]
        [Route("printPlateLabels")]
        public async Task<IHttpActionResult> PrintPlateLabels([FromBody]PrintPlateLabelRequestArgs args)
        {
            if (args == null)
                return InvalidRequest("Please specify required parameters.");

            var result = await _testService.PrintPlateLabelsAsync(args);
            return Ok(result);
        }

        [HttpGet]
        [Route("PlatePlanOverview")]
        public async Task<HttpResponseMessage> GetPlatePlanOverview(int periodID)
        {
            //if (periodID <= 0)
            //    return InvalidRequest("Please specify required parameters.");

            var byteArray = await _testService.GetPlatePlanOverviewAsync(periodID);
            //return Ok(result);
            var result = new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new ByteArrayContent(byteArray),
            };
            result.Content.Headers.ContentType = new MediaTypeHeaderValue("application/pdf");

            return result;
        }
        [HttpPost]
        [Route("BatchOverview")]
        [Authorize(Roles = AppRoles.PAC_SO_VIEWER + "," + AppRoles.PAC_LAB_EMPLOYEE)]
        public async Task<IHttpActionResult> GetBatchOverview(BatchOverviewRequestArgs args)
        {
            var data = await _testService.GetBatchOverviewAsync(args);
            return Ok(new
            {
                Data = new
                {
                    Data = data.Tables[0],
                    Columns = data.Tables[1]
                },
                Total = args.TotalRows
            }
            );
        }

        [HttpPost]
        [Route("GetExcel")]
        [Authorize(Roles = AppRoles.PAC_SO_VIEWER + "," + AppRoles.PAC_LAB_EMPLOYEE)]
        public async Task<IHttpActionResult> GetExcel(BatchOverviewRequestArgs args)
        {
            var data = await _testService.GetDataForExcelAsync(args);

            var result = new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new ByteArrayContent(data)
            };
            result.Content.Headers.ContentDisposition = new ContentDispositionHeaderValue("attachment")
            {
                FileName = "BatchOverview.xlsx"
            };
            result.Content.Headers.ContentType = new MediaTypeHeaderValue("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
            return ResponseMessage(result);
        }

    }    
}
