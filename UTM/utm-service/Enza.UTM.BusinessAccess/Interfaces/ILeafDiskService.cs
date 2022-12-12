using System.Collections.Generic;
using System.Data;
using System.Net.Http;
using System.Threading.Tasks;
using Enza.UTM.Entities.Args;
using Enza.UTM.Entities.Args.Abstract;
using Enza.UTM.Entities.Results;

namespace Enza.UTM.BusinessAccess.Interfaces
{
    public interface ILeafDiskService
    {
        Task<DataTable> GetConfigurationListAsync(string crops);
        Task<bool> SaveConfigurationNameAsync(SaveSampleConfigurationRequestArgs args);
        Task<PhenoneImportDataResult> ImportDataAsync(HttpRequestMessage request, LeafDiskRequestArgs args);                
        Task<PhenoneImportDataResult> ImportDataFromConfigurationAsync(LDImportFromConfigRequestArgs args);                
        Task<ExcelDataResult> GetDataAsync(LeafDiskGetDataRequestArgs requestArgs);
        Task<bool> UpdateMaterialAsync(UpdateMaterialRequestArgs requestArgs);
        Task AssignMarkersAsync(LFDiskAssignMarkersRequestArgs requestArgs);
        Task ManageInfoAsync(LeafDiskManageMarkersRequestArgs requestArgs);
        Task<ExcelDataResult> getDataWithDeterminationsAsync(MaterialsWithMarkerRequestArgs args);
        Task<ExcelDataResult> GetSampleMaterialAsync(LeafDiskGetDataRequestArgs args);
        Task<bool> SaveSampleAsync(SaveSampleRequestArgs args);
        Task<bool> SaveSampleMaterialAsync(SaveSamplePlotRequestArgs args);
        Task<IEnumerable<GetSampleResult>> GetSampleAsync(int testID);
        Task<LeafDiskPunchlist> GetPunchlistAsync(int testID);
        Task<PrintLabelResult> GetPrintLabelsAsync(int testID);
        Task<ExcelDataResult> GetLeafDiskOverviewAsync(LeafDiskOverviewRequestArgs args);
        Task<byte[]> LeafDiskOverviewToExcelAsync(int testID);
        Task<LDRequestSampleTestResult> LDRequestSampleTestAsync(TestRequestArgs requestArgs); 
        Task<ReceiveLDResultsReceiveResult> ReceiveLDResultsAsync(ReceiveLDResultsRequestArgs args);
        Task<DataSet> ProcessSummaryCalcuationAsync();
    }
}
