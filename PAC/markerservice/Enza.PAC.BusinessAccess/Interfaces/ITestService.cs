using Enza.PAC.DataAccess.Services;
using Enza.PAC.Entities.Args;
using Enza.PAC.Entities.Results;
using System.Data;
using System.Threading.Tasks;

namespace Enza.PAC.BusinessAccess.Interfaces
{
    public interface ITestService
    {
        Task<JsonResponse> GetFolderDetailsAsync(int periodID);
        Task<JsonResponse> GetDeclusterResultAsync(int periodID, int detAssignmentID);
        Task GenerateFolderDetailsAsync(GenerateFolderDetailsRequestArgs requestArgs);
        Task<bool> ReservePlatesInLIMSAsync(int periodID);
        Task<int?> GetMinimumTestStatusPerPeriodAsync (int periodID);
        Task<bool> SendToLIMSAsync(int periodID, int delay);
        Task<DataSet> ProcessAllTestResultSummaryAsync();
        Task<PrintLabelResult> PrintPlateLabelsAsync(PrintPlateLabelRequestArgs args);
        Task<byte[]> GetPlatePlanOverviewAsync(int periodID);
        Task<DataSet> GetBatchOverviewAsync(BatchOverviewRequestArgs args);
        Task<byte[]> GetDataForExcelAsync(BatchOverviewRequestArgs args);
        Task<bool> AutomateReservePlatesAsync();
    }
}
