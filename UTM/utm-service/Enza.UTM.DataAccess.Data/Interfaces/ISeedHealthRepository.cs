using System.Collections.Generic;
using System.Data;
using System.Net.Http;
using System.Threading.Tasks;
using Enza.UTM.DataAccess.Interfaces;
using Enza.UTM.Entities;
using Enza.UTM.Entities.Args;
using Enza.UTM.Entities.Args.Abstract;
using Enza.UTM.Entities.Results;
using Enza.UTM.Services.Abstract;

namespace Enza.UTM.DataAccess.Data.Interfaces
{
    public interface ISeedHealthRepository : IRepository<object>
    {
        Task<PhenoneImportDataResult> ImportDataFromPhenomeAsync(HttpRequestMessage request, SeedHealthRequestArgs args);
        Task<ExcelDataResult> GetDataAsync(SeedHealthGetDataRequestArgs requestArgs); 
        Task AssignMarkersAsync(LFDiskAssignMarkersRequestArgs requestArgs);
        Task ManageInfoAsync(LeafDiskManageMarkersRequestArgs requestArgs);
        Task<ExcelDataResult> getDataWithDeterminationsAsync(MaterialsWithMarkerRequestArgs args);
        Task<ExcelDataResult> GetSampleMaterialAsync(LeafDiskGetDataRequestArgs args);
        Task<bool> SaveSampleAsync(SaveSampleRequestArgs args);
        Task<bool> SaveSampleMaterialAsync(SaveSampleLotRequestArgs args);
        Task<IEnumerable<GetSampleResult>> GetSampleAsync(int testID);
        //Task<LeafDiskPunchlist> GetPunchlistAsync(int testID);
        Task<ExcelDataResult> GetSHOverviewAsync(LeafDiskOverviewRequestArgs args);
        Task<DataTable> SHOverviewToExcelAsync(int testID);
        Task<DataTable> ExcelForABSAsync(int testID);
        Task<SHSendToABSResponse> SendToABSAsync(int testID);
        Task<DataTable> ProcessSummaryCalcuationAsync();
        Task<IEnumerable<TestLookup>> GetTests();
        Task<IEnumerable<SHResult>> SHResult(int testID);
        Task<List<Column>> GetInventoryLotColumnsAsync(RestClient client, string objectType, string objectID);
        Task<UpdateInventoryLotResult> UpdateInventoryLotAsync(RestClient client, string objectType, string objectID, List<SHResult> resultData);

        Task UpdateTestResultStatusAsync(int testID, string testResultIDs, int statusCode);
        Task<IEnumerable<SHDataToPrint>> GetDataToPrintAsync(SHPrintStickerRequestArgs args);
        Task<ReceiveSHResultsReceiveResult> ReceiveSHResultsAsync(ReceiveSHResultsRequestArgs args);
    }
}
