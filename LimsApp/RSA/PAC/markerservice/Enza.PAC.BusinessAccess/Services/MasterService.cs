using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using Enza.PAC.BusinessAccess.Interfaces;
using Enza.PAC.DataAccess.Data.Interfaces;
using Enza.PAC.Entities.Args;
using Enza.PAC.Entities.Results;

namespace Enza.PAC.BusinessAccess.Services
{
    public class MasterService : IMasterService
    {
        private readonly IMasterRepository _masterRepo;
        public MasterService(IMasterRepository masterRepo)
        {
            _masterRepo = masterRepo;
        }
        public async Task<JsonResponse> GetYearAsync()
        {
            var data = await _masterRepo.GetYearAsync();
            var result = new JsonResponse
            {
                Data = data
            };
            return result;
        }

        public async Task<JsonResponse> GetperiodAsync(int year)
        {
            var data = await _masterRepo.GetperiodAsync(year);
            var result = new JsonResponse
            {
                Data = data
            };
            return result;
        }

        public async Task<JsonResponse> GetCropAsync()
        {
            var data = await _masterRepo.GetCropAsync();
            var result = new JsonResponse
            {
                Data = data
            };
            return result;
        }

        public async Task<JsonResponse> GetMarkersAsync(string cropCode, string markerName, bool? showPacMarkers)
        {
            var data = await _masterRepo.GetMarkersAsync(cropCode, markerName, showPacMarkers);
            var result = new JsonResponse
            {
                Data = data
            };
            return result;
        }

        public async Task<JsonResponse> GetVarietiesAsync(string cropCode, string varietyName)
        {
            var data = await _masterRepo.GetVarietiesAsync(cropCode, varietyName);
            var result = new JsonResponse
            {
                Data = data
            };
            return result;
        }
    }
}
