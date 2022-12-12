using Enza.PtoV.BusinessAccess.Interfaces;
using Enza.PtoV.Entities.Args;
using Enza.PtoV.Web.Services.Models;
using System.Threading.Tasks;
using System.Web.Http;

namespace Enza.PtoV.Web.Services.Controllers
{
    [Authorize(Roles = AppRoles.PTOV_USER)]
    [RoutePrefix("api/v1/pedigree")]
    public class PedigreeController : BaseApiController
    {
        private readonly IPedigreeService _service;
        public PedigreeController(IPedigreeService service)
        {
            _service = service;
        }
        [HttpPost]
        [Route("getPedigree")]
        public async Task<IHttpActionResult> GetPedigree([FromBody]GetPedigreeRequestArgs requestArgs)
        {
            requestArgs.Request = Request;
            var data = await _service.GetPedigreeAsync(requestArgs);
            return Json(data);
        }
    }    
}
