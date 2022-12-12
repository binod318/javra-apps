using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using Enza.UTM.DataAccess.Interfaces;
using Enza.UTM.Entities;
using Enza.UTM.Entities.Args;
using Enza.UTM.Entities.Results;

namespace Enza.UTM.DataAccess.Data.Planning.Interfaces
{
    public interface ILeafDiskSlotRepository : IRepository<object>
    {
        Task<GetAvailSample> GetAvailSampleAsync(GetAvailSampleRequestArgs request);
        Task<SlotLookUp> GetSlotDataAsync(int id);
        Task<EmailDataArgs> UpdateSlotPeriodAsync(UpdateSlotPeriodRequestArgs request);
        //Task<ApproveSlotResult> ApproveSlotAsync(ApproveSlotRequestArgs requestArgs);
        //Task<EmailDataArgs> DenySlotAsync(int SlotID);
        Task<DataSet> GetPlannedOverviewAsync(LabOverviewRequestArgs args);
        Task<BreedingOverviewResult> GetBreedingOverviewAsync(BreedingOverviewRequestArgs requestArgs);
        Task<EditSlotResult> EditSlotAsync(EditSlotRequestArgs args);
        Task<DataTable> GetApprovedSlotsAsync(string userName, string slotName, string crops);
        Task<DataSet> ReserveCapacityLookupAsync(IEnumerable<string> cropCodes);
        Task<ReserveCapacityResult> ReserveCapacityAsync(ReserveCapacityLFDiskRequestArgs args);
    }
}
