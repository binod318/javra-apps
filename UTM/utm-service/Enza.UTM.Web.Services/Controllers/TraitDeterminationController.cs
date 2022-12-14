using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Enza.UTM.BusinessAccess.Interfaces;
using Enza.UTM.Common.Extensions;
using Enza.UTM.Entities;
using Enza.UTM.Entities.Args;
using Enza.UTM.Web.Services.Core.Controllers;

namespace Enza.UTM.Web.Services.Controllers
{
    [RoutePrefix("api/v1/traitdetermination")]
    [Authorize(Roles = AppRoles.PUBLIC)]
    public class TraitDeterminationController : BaseApiController
    {
        readonly ITraitDeterminationService service;
        private readonly IMasterService _masterService;
        public TraitDeterminationController(ITraitDeterminationService service, IMasterService masterService)
        {
            this.service = service;
            _masterService = masterService;
        }
        [HttpGet]
        //[Route("getTraits")]
        [Route("getTraitsAndDetermination")]
        public async Task<IHttpActionResult> GetTraitsAndDetermination(string traitName, string cropCode, string source)
        {
            return Ok(await service.GetTraitsAndDeterminationAsync(traitName,cropCode, source));
        }

        [HttpGet]
        [Route("getTraitLOV")]
        public async Task<IHttpActionResult> GetTraitListOfValues(int cropTraitID)
        {
            return Ok(await service.GetTraitListOfValuesAsync(cropTraitID));
        }

        [HttpGet]
        [Route("getDeterminations")]
        public async Task<IHttpActionResult> GetDeterminations(string determinationName, string cropCode)
        {            
            return Ok(await service.GetDeterminationsAsync(determinationName,cropCode));
        }
        [HttpPost]
        [Route("getRelationTraitDetermination")]        
        public async Task<IHttpActionResult> GetRelationTraitDeterminationAsync([FromBody] RelationTraitDeterminationRequestArgs args)
        {
            //args.Crops = string.Join(",", User.GetClaims("enzauth.crops"));
            var cropCodes = await _masterService.GetUserCropCodesAsync(User);
            args.Crops = string.Join(",", cropCodes);
            var items = await service.GetRelationTraitDeterminationAsync(args);
            return Ok(new
            {
                args.TotalRows,
                Data = items
            });
        }

        [HttpPost]
        [Route("getTraitDeterminationResult")]
                
        public async Task<IHttpActionResult> GetTraitDeterminationResult([FromBody] TraitDeterminationResultRequestArgs args)
        {
            //args.Crops = string.Join(",", User.GetClaims("enzauth.crops"));
            var cropCodes = await _masterService.GetUserCropCodesAsync(User);
            args.Crops = string.Join(",", cropCodes);
            var items = await service.GetTraitDeterminationResultAsync(args);
            return Ok(new
            {
                args.TotalRows,
                Data = items
            });
        }

        [Route("getCrops")]
        [HttpGet]
        public async Task<IHttpActionResult> Get()
        {
            //var crops = User.GetClaims("enzauth.crops").ToList();
            var cropCodes = await _masterService.GetUserCropCodesAsync(User);
            return Ok(await service.GetCropAsync(cropCodes.ToList()));
        }


        [HttpPost]
        [Route("saveRelationTraitDetermination")]
        [OverrideAuthorization]
        [Authorize(Roles = AppRoles.MANAGE_MASTER_DATA_UTM)]
        public async Task<IHttpActionResult> SaveRelationTraitMaterialDetermination([FromBody] SaveTraitDeterminationRelationRequestArgs args)
        {
            //args.Crops = string.Join(",", User.GetClaims("enzauth.crops"));
            var cropCodes = await _masterService.GetUserCropCodesAsync(User);
            args.Crops = string.Join(",", cropCodes);
            var items = await service.SaveRelationTraitMaterialDetermination(args);
            return Ok(new
            {
                args.TotalRows,
                Data = items
            });
        }

        [HttpPost]
        [Route("saveTraitDeterminationResult")]
        [OverrideAuthorization]
        [Authorize(Roles = AppRoles.MANAGE_MASTER_DATA_UTM)]
        public async Task<IHttpActionResult> SaveTraitDeterminationResult([FromBody] SaveTraitDeterminationResultRequestArgs args)
        {
            //args.Crops = string.Join(",", User.GetClaims("enzauth.crops"));
            var cropCodes = await _masterService.GetUserCropCodesAsync(User);
            args.Crops = string.Join(",", cropCodes);
            var items = await service.SaveTraitDeterminationResultAsync(args);
            return Ok(new
            {
                args.TotalRows,
                Data = items
            });
        }

        [HttpPost]
        [Route("saveTraitDeterminationResultRDT")]
        [OverrideAuthorization]
        [Authorize(Roles = AppRoles.MANAGE_MASTER_DATA_UTM)]
        public async Task<IHttpActionResult> SaveTraitDeterminationResultRDT([FromBody] RDTSaveTraitDeterminationResultRequestArgs args)
        {
            var cropCodes = await _masterService.GetUserCropCodesAsync(User);
            args.Crops = string.Join(",", cropCodes);
            var items = await service.SaveTraitDeterminationResultRDTAsync(args);
            return Ok(new
            {
                args.TotalRows,
                Data = items
            });
        }

        [HttpPost]
        [Route("getTraitDeterminationResultRDT")]

        public async Task<IHttpActionResult> GetTraitDeterminationResultRDT([FromBody] TraitDeterminationResultRequestArgs args)
        {
            var cropCodes = await _masterService.GetUserCropCodesAsync(User);
            args.Crops = string.Join(",", cropCodes);
            var items = await service.GetTraitDeterminationResultRDTAsync(args);
            return Ok(new
            {
                args.TotalRows,
                Data = items
            });
        }

        [HttpPost]
        [Route("getTraitDeterminationResultSeedHealth")]

        public async Task<IHttpActionResult> GetTraitDeterminationResultSeedHealth([FromBody] TraitDeterminationResultRequestArgs args)
        {
            var cropCodes = await _masterService.GetUserCropCodesAsync(User);
            args.Crops = string.Join(",", cropCodes);
            var items = await service.GetTraitDeterminationResultSeedHealthAsync(args);
            return Ok(new
            {
                args.TotalRows,
                Data = items
            });
        }

        [HttpPost]
        [Route("saveTraitDeterminationResultSeedHealth")]
        [OverrideAuthorization]
        [Authorize(Roles = AppRoles.MANAGE_MASTER_DATA_UTM)]
        public async Task<IHttpActionResult> SaveTraitDeterminationResultSeedHealth([FromBody] SeedHealthSaveTraitDeterminationResultRequestArgs args)
        {
            var cropCodes = await _masterService.GetUserCropCodesAsync(User);
            args.Crops = string.Join(",", cropCodes);
            var items = await service.SaveTraitDeterminationResultSeedHealthAsync(args);
            return Ok(new
            {
                args.TotalRows,
                Data = items
            });
        }
    }
}
