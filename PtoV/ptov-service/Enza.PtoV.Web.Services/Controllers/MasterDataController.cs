using System.Threading.Tasks;
using System.Web.Http;
using Enza.PtoV.BusinessAccess.Interfaces;
using Enza.PtoV.Common.Extensions;

namespace Enza.PtoV.Web.Services.Controllers
{
    [RoutePrefix("api/v1/Master")]
    public class MasterDataController : BaseApiController
    {
        readonly IMasterService masterService;
        public MasterDataController(IMasterService masterService)
        {
            this.masterService = masterService;
        }

        [Route("getCrops")]
        [HttpGet]
        public async Task<IHttpActionResult> Get()
        {
            return Ok(await masterService.GetCropAsync());
        }

        [Route("getNewCrops")]
        [HttpGet]
        public async Task<IHttpActionResult> GetNewCrops(string cropCode)
        {
            var crops = await masterService.GetNewCropsAsync(cropCode);
            return Ok(crops);
        }

        [Route("getProductSegments")]
        [HttpGet]
        public async Task<IHttpActionResult> GetProductSegments(string cropCode)
        {
            var crops = await masterService.GetProductSegmentsAsync(cropCode);
            return Ok(crops);
        }

        [Route("getNewCropsAndProductSegments")]
        [HttpGet]
        public async Task<IHttpActionResult> GetNewCropsAndProductSegments(string cropCode)
        {
            var newCrops = await masterService.GetNewCropsAsync(cropCode);
            var prodSegments = await masterService.GetProductSegmentsAsync(cropCode);
            return Ok(new
            {
                NewCrops = newCrops,
                ProdSegments = prodSegments
            });
        }
        [Route("getCountryOfOrigin")]
        [HttpGet]
        public async Task<IHttpActionResult> GetCountryOfOrigin()
        {
            return Ok(await masterService.GetCountryOfOriginAsync());
            
        }

        [Route("getUserCrops")]
        [HttpGet]
        public async Task<IHttpActionResult> GetUserGrops()
        {
            var crops = await masterService.GetUserCropsAsync(User);
            return Ok(crops);
        }
    }
}
