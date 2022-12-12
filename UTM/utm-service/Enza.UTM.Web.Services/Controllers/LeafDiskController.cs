using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.Web.Http;
using Enza.UTM.BusinessAccess.Interfaces;
using Enza.UTM.Common.Extensions;
using Enza.UTM.Entities;
using Enza.UTM.Entities.Args;
using Enza.UTM.Entities.Args.Abstract;
using Enza.UTM.Web.Services.Core.Controllers;

namespace Enza.UTM.Web.Services.Controllers
{
    [RoutePrefix("api/v1/leafdisk")]
    //[Authorize(Roles = AppRoles.PUBLIC)]
    public class LeafDiskController : BaseApiController
    {
        private readonly ILeafDiskService _leafdiskService;
        private readonly IFileService _fileService;
        private readonly IMasterService _masterService;
        private readonly ITestService _testService;
        Scheduling.QuartzJobScheduler _scheduler;

        public LeafDiskController(ILeafDiskService leafDiskService, IFileService fileService, IMasterService masterService, ITestService testService, Scheduling.QuartzJobScheduler scheduler)
        {
            _leafdiskService = leafDiskService;
            _fileService = fileService;
            _masterService = masterService;
            _testService = testService;
            _scheduler = scheduler;
        }

        [Route("getconfiglist")]
        [HttpGet]
        public async Task<IHttpActionResult> GetSample()
        {
            var cropCodes = await _masterService.GetUserCropCodesAsync(User);
            var crops = string.Join(",", cropCodes);
            var result = await _leafdiskService.GetConfigurationListAsync(crops);
            return Ok(result);
        }

        [Route("saveconfigname")]
        [HttpPost]
        public async Task<IHttpActionResult> SaveConfigurationName([FromBody] SaveSampleConfigurationRequestArgs args)
        {
            if(args == null)
                return InvalidRequest("Invalid request.");
            if (args.TestID == 0)
                return InvalidRequest("Please provide test id.");
            if (string.IsNullOrWhiteSpace(args.SampleConfigName))
                return InvalidRequest("Please provide configuration name.");

            var result = await _leafdiskService.SaveConfigurationNameAsync(args);
            return Ok(result);
        }

        [HttpPost]
        [Route("import")]
        public async Task<IHttpActionResult> Import([FromBody]LeafDiskRequestArgs args)
        {
            if (string.IsNullOrWhiteSpace(args.TestName))
                return InvalidRequest("Please provide test name.");
            if (string.IsNullOrWhiteSpace(args.CropID))
                return InvalidRequest("Please provide research group ID.");
            if (string.IsNullOrWhiteSpace(args.FolderID))
                return InvalidRequest("Please provide folder ID.");

            var data = await _leafdiskService.ImportDataAsync(Request, args);
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

        [HttpPost]
        [Route("importfromconfiguration")]
        public async Task<IHttpActionResult> ImportFromConfiguration([FromBody] LDImportFromConfigRequestArgs args)
        {
            if (args.SourceID == 0)
                return InvalidRequest("Please provide configuration id.");
            if (string.IsNullOrWhiteSpace(args.TestName))
                return InvalidRequest("Please provide test name.");
            if (args.TestProtocolID == 0)
                return InvalidRequest("Please provide method id.");
            if (args.MaterialTypeID == 0)
                return InvalidRequest("Please provide material type id.");
            if (args.SiteID == 0)
                return InvalidRequest("Please provide site id.");

            var data = await _leafdiskService.ImportDataFromConfigurationAsync(args);
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

        [HttpPost]
        [Route("manageInfo")]
        public async Task<IHttpActionResult> ManageInfo([FromBody]LeafDiskManageMarkersRequestArgs args)
        {
            if (args == null)
                return InvalidRequest("Invlid paremeter.");

            await _leafdiskService.ManageInfoAsync(args);

            var resp = await _leafdiskService.getDataWithDeterminationsAsync(new MaterialsWithMarkerRequestArgs
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

            var resp = await _leafdiskService.getDataWithDeterminationsAsync(args);
            return Ok(resp);
        }

        //first tab
        [Route("getdata")]
        [HttpPost]
        public async Task<IHttpActionResult> GetData([FromBody] LeafDiskGetDataRequestArgs args)
        {
            var result = await _leafdiskService.GetDataAsync(args);
            return Ok(result);
        }

        [HttpPost]
        [Route("updatematerial")]
        public async Task<IHttpActionResult> UpdateMaterial([FromBody] UpdateMaterialRequestArgs args)
        {
            if (args == null)
                return InvalidRequest("Invlid paremeter.");

            var result = await _leafdiskService.UpdateMaterialAsync(args);

            return Ok(result);
        }

        //second tab
        [Route("getsamplematerial")]
        [HttpPost]
        public async Task<IHttpActionResult> GetSampleMaterial([FromBody] LeafDiskGetDataRequestArgs args)
        {
            var result = await _leafdiskService.GetSampleMaterialAsync(args);
            return Ok(result);
        }

        //second tab
        [Route("savesample")]
        [HttpPost]
        public async Task<IHttpActionResult> SaveSample([FromBody] SaveSampleRequestArgs args)
        {
            var result = await _leafdiskService.SaveSampleAsync(args);
            return Ok(result);
        }

        //second tab
        [Route("savesamplematerial")]
        [HttpPost]
        public async Task<IHttpActionResult> SaveSamplematerial([FromBody] SaveSamplePlotRequestArgs args)
        {
            var result = await _leafdiskService.SaveSampleMaterialAsync(args);
            return Ok(result);
        }

        [Route("getsample")]
        [HttpGet]
        public async Task<IHttpActionResult> GetSample([FromUri] int testID)
        {
            var result = await _leafdiskService.GetSampleAsync(testID);
            return Ok(result);
        }

        [Route("getpunchlist")]
        [HttpGet]

        public async Task<IHttpActionResult> GetPunchlist([FromUri] int testID)
        {
            var result = await _leafdiskService.GetPunchlistAsync(testID);
            return Ok(result);
        }

        [Route("printLabels")]
        [HttpPost]
        public async Task<IHttpActionResult> PrintLabels([FromBody] PrintLabelForLeafDiskRequestArgs args)
        {
            if (args == null)
                return InvalidRequest("Please specify required parameters.");

            var result = await _leafdiskService.GetPrintLabelsAsync(args.TestID);
            return Ok(result);
        }

        [Route("getleafdiskoverview")]
        [HttpPost]

        public async Task<IHttpActionResult> GetLeafDiskOverview([FromBody] LeafDiskOverviewRequestArgs args)
        {
            var cropCodes = await _masterService.GetUserCropCodesAsync(User);
            args.Crops = string.Join(",", cropCodes);
            var result = await _leafdiskService.GetLeafDiskOverviewAsync(args);
            return Ok(result);
        }

        [Route("leafdiskoverviewtoExcel")]
        [HttpGet]

        public async Task<IHttpActionResult> LeafDiskOverviewToExcel(int testID)
        {
            var data = await _leafdiskService.LeafDiskOverviewToExcelAsync(testID);

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

        [Route("requestsampletest")]
        [HttpPost]
        public async Task<IHttpActionResult> RequestSampleTest([FromBody] TestRequestArgs args)
        {
            var rs = await _leafdiskService.LDRequestSampleTestAsync(args);

            //Update test status to 500(SendToLIMS)
            await _testService.UpdateTestStatusAsync(new UpdateTestStatusRequestArgs
            {
                TestId = args.TestID,
                StatusCode = 500
            });

            return Ok(rs);
        }

        ///Web service exposed for LIMS
        [HttpPost]
        [Route("ReceiveLDResults")]
        //[Authorize(Roles = AppRoles.HANDLE_LAB_CAPACITY + "," + AppRoles.REQUEST_TEST)]
        public async Task<IHttpActionResult> ReceiveLDResults([FromBody] ReceiveLDResultsRequestArgs requestArgs)
        {
            if (requestArgs == null)
                return InvalidRequest("Please provide required parameters.");

            var result = await _leafdiskService.ReceiveLDResultsAsync(requestArgs);

            //Trigger summary calculation
            await _scheduler.TriggerJobAsync<Scheduling.Jobs.LeafDiskSummaryCalculationJob>();

            return Ok(result);
        }
    }
}