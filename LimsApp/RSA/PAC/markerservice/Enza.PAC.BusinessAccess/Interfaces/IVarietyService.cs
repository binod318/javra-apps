using Enza.PAC.Entities.Args;
using Enza.PAC.Entities.Results;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Enza.PAC.BusinessAccess.Interfaces
{
    public interface IVarietyService
    {
        Task<JsonResponse> GetMarkerPerVarietiesAsync(GetMarkerPerVarietyRequestArgs requestArgs);
        Task<JsonResponse> SaveMarkerPerVarietiesAsync(IEnumerable<SaveMarkerPerVarietyRequestArgs> requestArgs);
    }
}
