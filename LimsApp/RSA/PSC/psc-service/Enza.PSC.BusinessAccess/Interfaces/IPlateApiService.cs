using System.Threading.Tasks;

namespace Enza.PSC.BusinessAccess.Interfaces
{
    public interface IPlateApiService
    {
        Task<dynamic> GetPlateInfoAsync(int plateId, string token);
    }
}
