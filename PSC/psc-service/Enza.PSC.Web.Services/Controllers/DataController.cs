using System.Threading.Tasks;
using System.Web.Http;
using Enza.PSC.BusinessAccess.Interfaces;

namespace Enza.PSC.Web.Services.Controllers
{
    [RoutePrefix("api/data")]
    public class DataController : BaseApiController
    {
        private readonly IPlateApiService plateApiService;

        public DataController(IPlateApiService plateApiService)
        {
            this.plateApiService = plateApiService;
        }

        [HttpGet]
        [Route("getplateinfo")]
        public async Task<IHttpActionResult> GetPlateInfo([FromUri] int plateId)
        {
            if (plateId == 0)
                return BadRequest("Please provide PlateId.");

            var token = Request.Headers.Authorization.ToString();

            var data = await plateApiService.GetPlateInfoAsync(plateId, token);
            return Ok(data);
        }
    }
}
