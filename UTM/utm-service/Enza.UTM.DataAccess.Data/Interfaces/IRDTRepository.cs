using System.Collections.Generic;
using System.Data;
using System.Net.Http;
using System.Threading.Tasks;
using Enza.UTM.DataAccess.Interfaces;
using Enza.UTM.Entities;
using Enza.UTM.Entities.Args;
using Enza.UTM.Entities.Results;
namespace Enza.UTM.DataAccess.Data.Interfaces
{
    public interface IRDTRepository : IRepository<object>
    {
        Task<PhenoneImportDataResult> ImportDataFromPhenomeAsync(HttpRequestMessage request, PhenomeImportRequestArgs args);
        Task<MaterialsWithMarkerResult> GetMaterialWithtTestsAsync(MaterialsWithMarkerRequestArgs args);
        Task<Test> AssignTestAsync(AssignDeterminationForRDTRequestArgs args);
        Task<RequestSampleTestResult> RequestSampleTestAsync(TestRequestArgs args);
        Task<List<MaterialState>> GetmaterialStatusAsync();
        Task<PlatePlanResult> GetRDTtestsOverviewAsync(PlatePlanRequestArgs args);
        Task<RequestSampleTestCallbackResult> RequestSampleTestCallbackAsync(RequestSampleTestCallBackRequestArgs args, string JsonString);
        //Task<RequestSampleTestCallbackResult> RequestSampleTestCallbackAsync1(RequestSampleTestCallBackRequestArgs args, string JsonString);
        Task<ReceiveRDTResultsReceiveResult> ReceiveRDTResultsAsync(ReceiveRDTResultsRequestArgs args);
        Task<PrintLabelResult> PrintLabelAsync(PrintLabelForRDTRequestArgs reqArgs);
        Task<IEnumerable<RDTScore>> GetRDTScores(int testID);
        Task<IEnumerable<TestLookup>> GetTests();
        Task UpdateObsrvationIDAsync(int testID, DataTable dt);
        Task<int> MarkSentResultAsync(int testID, string testResultIDs);
        Task ErrorSentResultAsync(int testID, string testResultIDs);
        Task<List<string>> GetMappingColumnsAsync();
        Task<DataSet> RDTResultToExcelAsync(int testID, bool isMarkerScore);
        Task<RequestSampleTestResult> RDTUpdatesampletestinfoAsync(TestRequestArgs args);
        Task UpdateRDTTestStatusAsync(UpdateTestStatusRequestArgs args);
        Task<IEnumerable<RDTMissingConversion>> GetMissingConversionData(int testID);
        Task MarkMissingConversionResultAsync(int testID, string testResultIDs);
    }
}
