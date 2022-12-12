using Enza.PAC.Entities.Results;
using System.Data;
using System.Threading.Tasks;

namespace Enza.PAC.BusinessAccess.Interfaces
{
    public interface IMasterService
    {
        Task<JsonResponse> GetYearAsync();
        Task<JsonResponse> GetperiodAsync(int year);
        Task<JsonResponse> GetCropAsync();
        Task<JsonResponse> GetMarkersAsync(string cropCode, string markerName, bool? showPacMarkers);
        Task<JsonResponse> GetVarietiesAsync(string cropCode, string varietyName);
    }
}
