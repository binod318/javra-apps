using System.Threading.Tasks;
using System.Web.Http;
using Enza.PSC.BusinessAccess.Interfaces;
using Enza.PSC.Entities;
using Enza.PSC.Entities.Bdtos;

namespace Enza.PSC.Web.Services.Controllers
{
    [RoutePrefix("api/history")]
    public class HistoryController : BaseApiController
    {
        private readonly IHistoryService historyService;
        public HistoryController(IHistoryService historyService)
        {
            this.historyService = historyService;
        }

        [HttpGet]
        public async Task<IHttpActionResult> GetHistory([FromUri] HistoryRequestArgs args)
        {
            var items = await historyService.GetAllAsync(args);
            return Ok(items);
        }

        [HttpPost]
        public async Task<IHttpActionResult> SaveHistory([FromBody]History args)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest("Please provide all required values.");
            }
            var id = await historyService.SaveAsync(args);
            return Ok(id);
        }
    }
}
