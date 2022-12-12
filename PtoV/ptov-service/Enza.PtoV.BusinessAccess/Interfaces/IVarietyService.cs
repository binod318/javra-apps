using System.Data;
using System.Net.Http;
using System.Threading.Tasks;
using Enza.PtoV.Entities.Args;

namespace Enza.PtoV.BusinessAccess.Interfaces
{
    public interface IVarietyService
    {
        Task UpdateProductSegmentsAsync(UpdateProductSegmentsRequestArgs requestArgs);
        Task<bool> ReplaceLOTAsync(int gID, int lotGID);
        Task<bool> ReplaceLOTAsync(HttpRequestMessage request, ReplaceLotRequestArgs args);
        Task<bool> UndoReplaceLOTAsync(UndoReplaceLotRequestArgs args);
        Task<DataTable> ReplaceLOTLookupAsync(int gID);
    }
}
