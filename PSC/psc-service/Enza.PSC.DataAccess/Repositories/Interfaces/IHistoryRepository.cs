using System.Collections.Generic;
using System.Threading.Tasks;
using Enza.PSC.DataAccess.Interfaces;
using Enza.PSC.Entities;
using Enza.PSC.Entities.Bdtos;

namespace Enza.PSC.DataAccess.Repositories.Interfaces
{
    public interface IHistoryRepository : IRepository<History>
    {
        Task<IEnumerable<History>> GetAllAsync(HistoryRequestArgs args);
        Task<int> SaveAsync(History history);
    }
}
