using Enza.PtoV.Entities.Args;
using Enza.PtoV.Entities.Results;
using System.Threading.Tasks;

namespace Enza.PtoV.BusinessAccess.Interfaces
{
    public interface IPedigreeService
    {
        Task<string> GetPedigreeAsync(GetPedigreeRequestArgs requestArgs);
    }
}
