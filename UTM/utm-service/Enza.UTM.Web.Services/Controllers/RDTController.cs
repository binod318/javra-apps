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
using Enza.UTM.Web.Services.Core.Controllers;

namespace Enza.UTM.Web.Services.Controllers
{
    [RoutePrefix("api/v1/rdt")]    
    public class RDTController : BaseApiController
    {
        private readonly IRDTService _rdtService;
        private readonly IFileService _fileService;        
        private readonly IMasterService _masterService;

        public RDTController(IRDTService rdtService, IFileService fileService, 
            ITestService testService, IMasterService masterService)
        {
            this._rdtService = rdtService;
            _fileService = fileService;
            _masterService = masterService;
        }
       
        [HttpPost]
        [Route("import")]
        [Authorize(Roles = AppRoles.PUBLIC)]
        public async Task<IHttpActionResult> Import([FromBody]PhenomeImportRequestArgs args)
        {
            if (string.IsNullOrWhiteSpace(args.TestName))
                return InvalidRequest("Please provide test name.");
            if (string.IsNullOrWhiteSpace(args.CropID))
                return InvalidRequest("Please provide research group ID.");
            if (string.IsNullOrWhiteSpace(args.FolderID))
                return InvalidRequest("Please provide folder ID.");

            //var data = await _phenomeServices.GetPhenomeDataAsync(Request, args);
            var data = await _rdtService.ImportDataFromPhenomeAsync(Request, args);

            var fileInfo = new ExcelFile();
            if(!(data.Errors.Any() || data.Warnings.Any()))
            {
                fileInfo = await _fileService.GetFileAsync(args.TestID);
            }
            var result = new
            {
                data.Success,
                data.Errors,
                data.Warnings,
                data.Total,
                data.DataResult,
                args.TestID,
                data.TotalCount,
                File = fileInfo
            };
            return Ok(result);
        }

        [Route("getData")]
        [HttpPost]
        [Authorize(Roles = AppRoles.PUBLIC)]
        public async Task<IHttpActionResult> GetData([FromBody] ExcelDataRequestArgs args)
        {
            var result = await _rdtService.GetDataAsync(args);
            return Ok(result);
        }

        [Route("getmaterialwithtests")]
        [HttpPost]
        //[Authorize(Roles = AppRoles.PUBLIC)]
        public async Task<IHttpActionResult> Getmaterialwithtests([FromBody] MaterialsWithMarkerRequestArgs args)
        {
            var ds = await _rdtService.GetMaterialWithTestsAsync(args);            
            return Ok(ds);
        }


        [Route("assignTests")]
        [HttpPost]
        [Authorize(Roles = AppRoles.PUBLIC)]
        public async Task<IHttpActionResult> AssignTest([FromBody] AssignDeterminationForRDTRequestArgs args)
        {
            var ds = await _rdtService.AssignTestAsync(args);
            var rs = new
            {
                Data = ds,
                args.TotalRows
            };
            return Ok(rs);
        }

        [Route("requestSampleTest")]
        [HttpPost]
        [Authorize(Roles = AppRoles.PUBLIC)]
        public async Task<IHttpActionResult> RequestSampleTest([FromBody] TestRequestArgs args)
        {
            var rs = await _rdtService.RequestSampleTestAsync(args);

            await _rdtService.UpdateRDTTestStatusAsync(new UpdateTestStatusRequestArgs
            {
                StatusCode = 200,
                TestId = args.TestID
            });

            return Ok(rs);
        }

        
        [Route("getmaterialstatus")]
        [HttpGet]
        [Authorize(Roles = AppRoles.PUBLIC)]
        public async Task<IHttpActionResult> getmaterialSatus()
        {            
            var rs = await _rdtService.GetmaterialStatusAsync();
            return Ok(rs);
        }
        
        [Authorize(Roles = AppRoles.HANDLE_LAB_CAPACITY + "," + AppRoles.REQUEST_TEST)]
        [HttpPost]
        [Route("getRDTtestOverview")]
        public async Task<IHttpActionResult> GetRDTtestsOverview([FromBody] PlatePlanRequestArgs args)
        {
            var cropCodes = await _masterService.GetUserCropCodesAsync(User);
            args.Crops = string.Join(",", cropCodes);
            var rs = await _rdtService.GetRDTtestsOverviewAsync(args);
            return Ok(rs);
        }

        //[HttpPost]
        //[Route("RequestSampleTestCallBack")]
        ////[Authorize(Roles = AppRoles.HANDLE_LAB_CAPACITY + "," + AppRoles.REQUEST_TEST)]
        //public async Task<IHttpActionResult> RequestSampleTestCallBack([FromBody]RequestSampleTestCallBackRequestArgs requestArgs)
        //{
        //    if (requestArgs == null)
        //        return InvalidRequest("Please provide required parameters.");

        //    var result = await _rdtService.RequestSampleTestCallbackAsync(requestArgs);
        //    return Ok(result);
        //}

        //[HttpPost]
        //[Route("ReceiveRDTResults")]
        ////[Authorize(Roles = AppRoles.HANDLE_LAB_CAPACITY + "," + AppRoles.REQUEST_TEST)]
        //public async Task<IHttpActionResult> ReceiveRDTResults([FromBody]ReceiveRDTResultsRequestArgs requestArgs)
        //{
        //    if (requestArgs == null)
        //        return InvalidRequest("Please provide required parameters.");

        //    var result = await _rdtService.ReceiveRDTResultsAsync(requestArgs);
        //    return Ok(result);
        //}

        [Route("print")]
        [HttpPost]
        [Authorize(Roles = AppRoles.PUBLIC)]
        public async Task<IHttpActionResult> PrintLabel([FromBody]PrintLabelForRDTRequestArgs reqArgs)
        {
            if (reqArgs == null)
                return InvalidRequest("Please provide required parameters.");
           
            var history = await _rdtService.PrintLabelAsync(reqArgs);
            return Ok(history);
        }

        [Route("getmappingcolumns")]
        [HttpGet]
        [Authorize(Roles = AppRoles.PUBLIC)]
        public async Task<IHttpActionResult> GetMappingColumns()
        {
            var rs = await _rdtService.GetMappingColumnsAsync();
            return Ok(rs);
        }
       
        [HttpPost]
        [Route("RequestSampleTestCallBack")]
        public async Task<IHttpActionResult> RequestSampleTestCallBack([FromBody] RequestSampleTestCallBackRequestArgs requestArgs)
        {
            if (requestArgs == null)
                return InvalidRequest("Please provide required parameters.");

            var result = await _rdtService.RequestSampleTestCallbackAsync(requestArgs);
            return Ok(result);
        }

       
        [HttpPost]
        [Route("ReceiveRDTResults")]
        //[Authorize(Roles = AppRoles.HANDLE_LAB_CAPACITY + "," + AppRoles.REQUEST_TEST)]
        public async Task<IHttpActionResult> ReceiveRDTResults([FromBody] ReceiveRDTResultsRequestArgs requestArgs)
        {
            if (requestArgs == null)
                return InvalidRequest("Please provide required parameters.");

            var result = await _rdtService.ReceiveRDTResultsAsync(requestArgs);
            return Ok(result);
        }

        [HttpGet]
        [Route("RDTResultToExcel")]
        [Authorize(Roles = AppRoles.PUBLIC)]
        public async Task<IHttpActionResult> RDTResultToExcel(int testID, bool? markerScore = false, bool? traitScore = false)
        {
            var isMarkerScore = !traitScore.ToBoolean();

            var data = await _rdtService.RDTResultToExcelAsync(testID, isMarkerScore);
            var result = new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new ByteArrayContent(data)
            };
            result.Content.Headers.ContentDisposition = new ContentDispositionHeaderValue("attachment")
            {
                FileName = $"{testID}.xlsx"
            };
            result.Content.Headers.ContentType = new MediaTypeHeaderValue("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
            return ResponseMessage(result);
        }

        [Route("RDTUpdatesampletestinfo")]
        [HttpPost]
        [Authorize(Roles = AppRoles.PUBLIC)]

        public async Task<IHttpActionResult> RDTUpdatesampletestinfo([FromBody] TestRequestArgs args)
        {
            var rs = await _rdtService.RDTUpdatesampletestinfoAsync(args);

            if(rs.Success.EqualsIgnoreCase("true"))
            {
                //this update is done just after getting success response from LIMS service.
                ////update testMaterialDeterminatinStatus
                //await _rdtService.UpdateRDTTestStatusAsync(new UpdateTestStatusRequestArgs
                //{
                //    StatusCode = 500,
                //    TestId = args.TestID
                //});

                var resp1 = new
                {
                    rs.ErrorMsg,
                    rs.Success,
                    StatusCode = 500

                };
                return Ok(resp1);
            }
            var resp = new
            {
                rs.ErrorMsg,
                rs.Success,
                StatusCode = 450

            };
            return Ok(resp);
        }
    }
}