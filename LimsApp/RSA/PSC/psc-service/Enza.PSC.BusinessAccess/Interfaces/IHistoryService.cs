using System.Collections.Generic;
using System.Threading.Tasks;
using Enza.PSC.Entities;
using Enza.PSC.Entities.Bdtos;

namespace Enza.PSC.BusinessAccess.Interfaces
{
    public interface IHistoryService
    {
        Task<IEnumerable<History>> GetAllAsync(HistoryRequestArgs args);
        Task<long> SaveAsync(History history);
    }
}
