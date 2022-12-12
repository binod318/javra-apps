using System.Collections.Generic;
using System.Data;
using System.Net.Http;
using System.Threading.Tasks;
using Enza.UTM.Entities.Args;
using Enza.UTM.Entities.Args.Abstract;
using Enza.UTM.Entities.Results;

namespace Enza.UTM.BusinessAccess.Interfaces
{
    public interface ISeedHealthService
    {
        Task<PhenoneImportDataResult> ImportDataAsync(HttpRequestMessage request, SeedHealthRequestArgs args);                 
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
        Task<byte[]> SHOverviewToExcelAsync(int testID);
        Task<byte[]> ExcelForABSAsync(int testID);
        Task<SHSendToABSResponse> SendToABSAsync(int testID);
        Task<bool> SendResult();
        Task<PrintLabelResult> PrintStickerAsync(SHPrintStickerRequestArgs args);
        Task<ReceiveSHResultsReceiveResult> ReceiveSHResultsAsync(ReceiveSHResultsRequestArgs args);
    }
}
