using Enza.PAC.DataAccess.Interfaces;
using Enza.PAC.Entities.Args;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;

namespace Enza.PAC.DataAccess.Data.Interfaces
{
    public interface IVarietyRepository : IRepository<object>
    {
        Task<DataSet> GetMarkerPerVarietiesAsync(GetMarkerPerVarietyRequestArgs requestArgs);
        Task SaveMarkerPerVarietiesAsync(IEnumerable<SaveMarkerPerVarietyRequestArgs> requestArgs);
    }
}
