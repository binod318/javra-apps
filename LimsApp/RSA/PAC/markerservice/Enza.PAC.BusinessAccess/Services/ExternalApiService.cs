using Enza.PAC.BusinessAccess.Interfaces;
using Enza.PAC.DataAccess.Data.Interfaces;
using Enza.PAC.Entities.Args;
using Enza.PAC.Entities.Results;
using System.Threading.Tasks;

namespace Enza.PAC.BusinessAccess.Services
{
    public class ExternalApiService : IExternalApiService
    {
        private readonly IExternalApiRepository _externalApiRepository;

        public ExternalApiService(IExternalApiRepository externalApiRepository)
        {
            _externalApiRepository = externalApiRepository;
        }

        public async Task<JsonResponse> GetPlateSampleInfoAsync(GetPlateSampleInfoRequestArgs requestArgs)
        {
            var data = await _externalApiRepository.GetPlateSampleInfoAsync(requestArgs);
            return new JsonResponse
            {
                Data = data.Tables[0]
            };
        }
    }
}
