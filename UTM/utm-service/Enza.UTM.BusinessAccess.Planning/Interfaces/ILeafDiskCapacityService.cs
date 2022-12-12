using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using Enza.UTM.Entities.Args;
using Enza.UTM.Entities.Results;

namespace Enza.UTM.BusinessAccess.Planning.Interfaces
{
    public interface ILeafDiskCapacityService
    {
        Task<DataSet> GetCapacityAsync(int year, int siteLocation);
        Task<bool> SaveCapacityAsync(SaveCapacityRequestArgs request);
        //Task<ReserveCapacityResult> ReserveCapacityAsync(ReserveCapacityRequestArgs args);
        Task<DataSet> GetPlanApprovalListForLabAsync(int periodID, int siteID);
        Task<bool> MoveSlotAsync(MoveSlotRequestArgs args);
        Task<bool> DeleteSlotAsync(DeleteSlotRequestArgs args);
        //Task<DataSet> ReserveCapacityLookupAsync(IEnumerable<string> cropCodes);
        //Task<BreedingOverviewResult> GetBreedingOverviewAsync(BreedingOverviewRequestArgs args);
    }
}
