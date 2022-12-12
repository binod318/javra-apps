using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.Web.Http;
using Enza.UTM.BusinessAccess.Interfaces;
using Enza.UTM.Entities;
using Enza.UTM.Entities.Args;
using Enza.UTM.Web.Services.Core.Controllers;

namespace Enza.UTM.Web.Services.Controllers
{
    [RoutePrefix("api/v1/seedhealth")]
    [Authorize(Roles = AppRoles.PUBLIC)]
    public class SeedHealthController : BaseApiController
    {
        private readonly ISeedHealthService _seedHealthservice;
        private readonly IFileService _fileService;
        private readonly IMasterService _masterService;
        private readonly ITestService _testService;

        public SeedHealthController(ISeedHealthService seedHealthService, IFileService fileService, IMasterService masterService, ITestService testService)
        {
            _seedHealthservice = seedHealthService;
            _fileService = fileService;
            _masterService = masterService;
            _testService = testService;
        }

        [HttpPost]
        [Route("import")]
        public async Task<IHttpActionResult> Import([FromBody]SeedHealthRequestArgs args)
        {
            if (string.IsNullOrWhiteSpace(args.TestName))
                return InvalidRequest("Please provide test name.");
            if (string.IsNullOrWhiteSpace(args.CropID))
                return InvalidRequest("Please provide research group ID.");
            if (string.IsNullOrWhiteSpace(args.FolderID))
                return InvalidRequest("Please provide folder ID.");

            var data = await _seedHealthservice.ImportDataAsync(Request, args);
            var success = !data.Errors.Any() && !data.Warnings.Any();
            var fileInfo = await _fileService.GetFileAsync(args.TestID);
            var result = new
            {
                Success = success,
                data.Errors,
                data.Warnings,               
                args.TestID,
                File = fileInfo,
                data.Total,
                data.TotalCount,
                data.DataResult
            };
            return Ok(result);
        }

        //first tab
        [Route("getdata")]
        [HttpPost]
        public async Task<IHttpActionResult> GetData([FromBody] SeedHealthGetDataRequestArgs args)
        {
            var result = await _seedHealthservice.GetDataAsync(args);
            return Ok(result);
        }

        [Route("savesample")]
        [HttpPost]
        public async Task<IHttpActionResult> SaveSample([FromBody] SaveSampleRequestArgs args)
        {
            var result = await _seedHealthservice.SaveSampleAsync(args);
            return Ok(result);
        }

        [Route("savesamplematerial")]
        [HttpPost]
        public async Task<IHttpActionResult> SaveSamplematerial([FromBody] SaveSampleLotRequestArgs args)
        {
            var result = await _seedHealthservice.SaveSampleMaterialAsync(args);
            return Ok(result);
        }

        [HttpPost]
        [Route("manageInfo")]
        public async Task<IHttpActionResult> ManageInfo([FromBody]LeafDiskManageMarkersRequestArgs args)
        {
            if (args == null)
                return InvalidRequest("Invlid paremeter.");

            await _seedHealthservice.ManageInfoAsync(args);

            var resp = await _seedHealthservice.getDataWithDeterminationsAsync(new MaterialsWithMarkerRequestArgs
            {
                TestID = args.TestID,
                PageNumber = args.PageNumber,
                PageSize = args.PageSize,
                Filter = args.Filter
            });
            return Ok(resp);
        }

        [HttpPost]
        [Route("getDataWithDeterminations")]
        public async Task<IHttpActionResult> getDataWithDeterminations([FromBody] MaterialsWithMarkerRequestArgs args)
        {
            if (args == null)
                return InvalidRequest("Please provide required parameters.");

            var resp = await _seedHealthservice.getDataWithDeterminationsAsync(args);
            return Ok(resp);
        }

        //second tab
        [Route("getsamplematerial")]
        [HttpPost]
        public async Task<IHttpActionResult> GetSampleMaterial([FromBody] LeafDiskGetDataRequestArgs args)
        {
            var result = await _seedHealthservice.GetSampleMaterialAsync(args);
            return Ok(result);
        }

        [Route("getsample")]
        [HttpGet]
        public async Task<IHttpActionResult> GetSample([FromUri] int testID)
        {
            var result = await _seedHealthservice.GetSampleAsync(testID);
            return Ok(result);
        }

        [Route("getSHoverview")]
        [HttpPost]
        public async Task<IHttpActionResult> GetSHOverview([FromBody] LeafDiskOverviewRequestArgs args)
        {
            var cropCodes = await _masterService.GetUserCropCodesAsync(User);
            args.Crops = string.Join(",", cropCodes);
            var result = await _seedHealthservice.GetSHOverviewAsync(args);
            result.Success = true;
            return Ok(result);
        }


        [Route("SHoverviewtoExcel")]
        [HttpGet]

        public async Task<IHttpActionResult> SHOverviewToExcel(int testID)
        {
            var data = await _seedHealthservice.SHOverviewToExcelAsync(testID);

            var result = new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new ByteArrayContent(data)
            };
            result.Content.Headers.ContentDisposition = new ContentDispositionHeaderValue("attachment")
            {
                FileName = $"Result_{testID}.xlsx"
            };
            result.Content.Headers.ContentType = new MediaTypeHeaderValue("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
            return ResponseMessage(result);
        }

        [Route("ExcelForABS")]
        [HttpGet]

        public async Task<IHttpActionResult> ExcelForABS(int testID)
        {
            var data = await _seedHealthservice.ExcelForABSAsync(testID);

            var result = new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new ByteArrayContent(data)
            };
            result.Content.Headers.ContentDisposition = new ContentDispositionHeaderValue("attachment")
            {
                FileName = $"Result_{testID}.xlsx"
            };
            result.Content.Headers.ContentType = new MediaTypeHeaderValue("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
            return ResponseMessage(result);
        }


        [Route("SendToABS")]
        [HttpPost]
        public async Task<IHttpActionResult> SendToABS(int testID)
        {
            //here logic of sending data to abs need to implemented
            //for now only checking required data is implemented
            await _seedHealthservice.SendToABSAsync(testID);

            //update test status
            await _testService.UpdateTestStatusAsync(new UpdateTestStatusRequestArgs { StatusCode = 500, TestId = testID });
            var testStatus = await _testService.GetTestDetailAsync(new GetTestDetailRequestArgs { TestID = testID });
            return Ok(testStatus);

        }

        [HttpPost]
        [Route("printSticker")]
        public async Task<IHttpActionResult> PrintSticker([FromBody] SHPrintStickerRequestArgs args)
        {
            var data = await _seedHealthservice.PrintStickerAsync(args);
            return Ok(data);
        }

        ///Web service exposed for LIMS
        [HttpPost]
        [Route("ReceiveSHResults")]
        public async Task<IHttpActionResult> ReceiveSHResults([FromBody] ReceiveSHResultsRequestArgs requestArgs)
        {
            if (requestArgs == null)
                return InvalidRequest("Please provide required parameters.");

            var result = await _seedHealthservice.ReceiveSHResultsAsync(requestArgs);

            return Ok(result);
        }
    }
}