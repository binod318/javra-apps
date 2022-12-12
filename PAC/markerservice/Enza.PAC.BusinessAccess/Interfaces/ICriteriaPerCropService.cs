using Enza.PAC.Entities.Args;
using Enza.PAC.Entities.Results;
using System.Threading.Tasks;

namespace Enza.PAC.BusinessAccess.Interfaces
{
    public interface ICriteriaPerCropService
    {
        Task<JsonResponse> GetAllCriteriaPerCropAsync(GetCriteriaPerCropRequestArgs requestArgs);
        Task<JsonResponse> PostAsync(CriteriaPerCropRequestArgs requestArgs);
    }
}
