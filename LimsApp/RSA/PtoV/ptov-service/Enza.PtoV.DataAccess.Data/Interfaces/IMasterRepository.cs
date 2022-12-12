using Enza.PtoV.DataAccess.Interfaces;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using Enza.PtoV.Entities.Results;
using System.Security.Principal;

namespace Enza.PtoV.DataAccess.Data.Interfaces
{
    public interface IMasterRepository : IRepository<object>
    {
        Task<DataTable> GetCropAsync();
        Task<DataTable> GetNewCropsAsync(string cropCode);
        Task<DataTable> GetProductSegmentsAsync(string cropCode);
        Task<IEnumerable<ColumnResult>> GetColumnsAsync(string cropCode);
        Task<TransferTypeForCropResult> GetTransferTypePerCropAsync(string cropCode);
        Task<DataTable> GetCountryOfOriginAsync();
        Task<DataTable> GetUserCropsAsync(IPrincipal user);
    }
}
