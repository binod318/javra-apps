using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using Enza.UTM.Entities;
using Enza.UTM.Entities.Args;
using Enza.UTM.Entities.Results;

namespace Enza.UTM.BusinessAccess.Planning.Interfaces
{
    public interface ILeafDiskSlotService
    {
        Task<GetAvailSample> GetAvailSampleAsync(GetAvailSampleRequestArgs request);
        Task<SlotLookUp> GetSlotDataAsync(int id);
        Task<SlotApprovalResult> UpdateSlotPeriodAsync(UpdateSlotPeriodRequestArgs request);
        //Task<SlotApprovalResult> ApproveSlotAsync(ApproveSlotRequestArgs requestArgs);
        //Task<SlotApprovalResult> DenySlotAsync(int SlotID);
        Task<DataSet> GetPlannedOverviewAsync(LabOverviewRequestArgs args);
        Task<BreedingOverviewResult> GetBreedingOverviewAsync(BreedingOverviewRequestArgs requestArgs);
        Task<SlotApprovalResult> EditSlotAsync(EditSlotRequestArgs args);
        Task<DataTable> GetApprovedSlotsAsync(string userName, string slotName, string crops);
        Task<byte[]> ExportCapacityPlanningToExcel(BreedingOverviewRequestArgs args);
        Task<byte[]> ExportLabOverviewToExcel(LabOverviewRequestArgs args);
        Task<DataSet> ReserveCapacityLookupAsync(IEnumerable<string> cropCodes);
        Task<ReserveCapacityResult> ReserveCapacityAsync(ReserveCapacityLFDiskRequestArgs args);
    }
}
