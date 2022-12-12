using Enza.PAC.Entities.Args;
using Enza.PAC.Entities.Results;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Enza.PAC.BusinessAccess.Interfaces
{
    public interface IPacCapacityService
    {
        Task<JsonResponse> GetPlanningCapacityAsync(int year);
        Task<JsonResponse> SaveLabCapacityAsync(List<SaveCapacityRequestArgs> args);
        Task<JsonResponse> GetPACPlanningCapacitySOAsync(int periodID);
        Task<JsonResponse> SavePACPlanningCapacitySOAsync(List<SavePlanningCapacitySOArgs> args);
    }
}
