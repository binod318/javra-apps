using Enza.PAC.Entities.Args;
using Enza.PAC.Entities.Results;
using System.Threading.Tasks;

namespace Enza.PAC.BusinessAccess.Interfaces
{
    public interface IExternalApiService
    {
        Task<JsonResponse> GetPlateSampleInfoAsync(GetPlateSampleInfoRequestArgs requestArgs);
    }
}
