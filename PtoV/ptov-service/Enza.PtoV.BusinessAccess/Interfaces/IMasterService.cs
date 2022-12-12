using System.Data;
using System.Security.Principal;
using System.Threading.Tasks;

namespace Enza.PtoV.BusinessAccess.Interfaces
{
    public interface IMasterService
    {
        Task<DataTable> GetCropAsync();
        Task<DataTable> GetNewCropsAsync(string cropCode);
        Task<DataTable> GetProductSegmentsAsync(string cropCode);
        Task<DataTable> GetCountryOfOriginAsync();
        Task<DataTable> GetUserCropsAsync(IPrincipal user);
    }
}
