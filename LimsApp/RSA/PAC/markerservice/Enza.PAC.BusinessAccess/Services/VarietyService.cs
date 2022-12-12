using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using Enza.PAC.BusinessAccess.Interfaces;
using Enza.PAC.DataAccess.Data.Interfaces;
using Enza.PAC.Entities.Args;
using Enza.PAC.Entities.Results;

namespace Enza.PAC.BusinessAccess.Services
{
    public class VarietyService : IVarietyService
    {
        private readonly IVarietyRepository _varietyRepository;
        public VarietyService(IVarietyRepository varietyRepository)
        {
            _varietyRepository = varietyRepository;
        }

        public async Task<JsonResponse> GetMarkerPerVarietiesAsync(GetMarkerPerVarietyRequestArgs requestArgs)
        {
            var data = await _varietyRepository.GetMarkerPerVarietiesAsync(requestArgs);
            return new JsonResponse
            {
                Data = new
                {
                    Data = data.Tables[0],
                    Columns = data.Tables[1]
                },
                Total = requestArgs.TotalRows
            };
        }

        public async Task<JsonResponse> SaveMarkerPerVarietiesAsync(IEnumerable<SaveMarkerPerVarietyRequestArgs> requestArgs)
        {
            await _varietyRepository.SaveMarkerPerVarietiesAsync(requestArgs);
            return new JsonResponse
            {
                Message = "Marker and Varieties are mapped successfully."
            };
        }
    }
}
