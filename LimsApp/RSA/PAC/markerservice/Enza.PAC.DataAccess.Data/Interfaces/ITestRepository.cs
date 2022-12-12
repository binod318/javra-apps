using Enza.PAC.DataAccess.Interfaces;
using Enza.PAC.DataAccess.Services;
using Enza.PAC.Entities;
using Enza.PAC.Entities.Args;
using Enza.PAC.Entities.Results;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;

namespace Enza.PAC.DataAccess.Data.Interfaces
{
    public interface ITestRepository : IRepository<object>
    {
        Task<DataSet> GetFolderDetailsAsync(int periodID);
        Task<DataSet> GetDeclusterResultAsync(int periodID, int detAssignmentID);
        Task GenerateFolderDetailsAsync(GenerateFolderDetailsRequestArgs requestArgs);
        Task<IEnumerable<TestForLIMS>> ReservePlatesInLIMSAsync(int periodID);
        Task<bool> UpdateTestStatusAsync(string testids, int statuscode, int daStatusCode);
        Task<int?> GetMinimumTestStatusPerPeriodAsync(int periodID);
        Task<IEnumerable<FillPlatesInLIMS>> GetInfoForSendToLIMSAsync(int periodID);
        Task<DataSet> ProcessAllTestResultSummaryAsync();
        Task<PrintLabelResult> PrintPlateLabelsAsync(PrintPlateLabelRequestArgs args);
        Task<DataSet> GetPlatePlanOverviewAsync(int periodID);
        Task<DataSet> GetBatchOverviewAsync(BatchOverviewRequestArgs args);
        Task<byte[]> GetDataForExcelAsync(BatchOverviewRequestArgs args);
        Task<IEnumerable<TestInfo>> GetTestsForReservePlates();
    }
}
