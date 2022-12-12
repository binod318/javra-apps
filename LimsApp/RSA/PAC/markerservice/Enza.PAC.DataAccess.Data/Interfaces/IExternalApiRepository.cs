using Enza.PAC.DataAccess.Interfaces;
using Enza.PAC.Entities.Args;
using System.Data;
using System.Threading.Tasks;

namespace Enza.PAC.DataAccess.Data.Interfaces
{
    public interface IExternalApiRepository : IRepository<object>
    {
        Task<DataSet> GetPlateSampleInfoAsync(GetPlateSampleInfoRequestArgs requestArgs);
    }
}
