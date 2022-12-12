using Enza.PtoV.Entities.Args;
using System.Data;
using System.Threading.Tasks;

namespace Enza.PtoV.DataAccess.Data.Interfaces
{
    public interface ITraitScreeningRepository
    {
        Task<DataTable> GetTraitScreeningAsync(TraitScreeningRequestArgs args);
        Task<DataTable> GetTraitScreeningResultAsync(TraitScreeningRequestArgs args);
        Task<DataTable> GetTraitsAsync(string traitName, string cropCode);
        Task<DataTable> GetScreeningAsync(string ScreeningName, string cropCode);
        Task<DataTable> SaveTraitScreeningAsync(SaveTraitScreeningRequestArgs args);
        Task<DataTable> GetTraitLOVAsync(int traitID);
        Task<DataTable> GetScreeningLOVAsync(int screeningFieldID);
        Task<DataTable> GetTraitsWithScreeningAsync(string traitName, string cropCode);
        Task<DataTable> SaveTraitScreeningResultAsync(SaveTraitScreeningResultArgs args);
        Task<bool> RemoveUnmappedColumns(RemoveColumnsRequestArgs args);
    }
}
