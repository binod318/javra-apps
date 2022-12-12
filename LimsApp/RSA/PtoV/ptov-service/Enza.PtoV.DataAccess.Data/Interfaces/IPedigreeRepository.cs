using Enza.PtoV.Entities.Args;
using System.Threading.Tasks;

namespace Enza.PtoV.DataAccess.Data.Interfaces
{
    public interface IPedigreeRepository
    {
        Task<string> GetPedigreeAsync(GetPedigreeRequestArgs requestArgs);
    }
}
