using Enza.PAC.DataAccess.Interfaces;
using System.Collections.Generic;
using System.Threading.Tasks;
using Enza.PAC.Entities.Results;
using System.Data;

namespace Enza.PAC.DataAccess.Data.Interfaces
{
    public interface IMasterRepository : IRepository<object>
    {
        Task<List<YearResult>> GetYearAsync();
        Task<DataTable> GetperiodAsync(int year);
        Task<DataTable> GetCropAsync();
        Task<DataTable> GetMarkersAsync(string cropCode, string markerName, bool? showPacMarkers);
        Task<DataTable> GetVarietiesAsync(string cropCode, string varietyName);

    }
}
