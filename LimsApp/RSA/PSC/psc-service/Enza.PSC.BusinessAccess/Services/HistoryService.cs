using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Enza.PSC.BusinessAccess.Interfaces;
using Enza.PSC.DataAccess.Repositories.Interfaces;
using Enza.PSC.Entities;
using Enza.PSC.Entities.Bdtos;

namespace Enza.PSC.BusinessAccess.Services
{
    public class HistoryService : IHistoryService
    {
        private readonly IHistoryRepository historyRepository;

        public HistoryService(IHistoryRepository historyRepository)
        {
            this.historyRepository = historyRepository;
        }

        public async Task<IEnumerable<History>> GetAllAsync(HistoryRequestArgs args)
        {
            return await historyRepository.GetAllAsync(args);
        }

        public async Task<long> SaveAsync(History history)
        {
            return await historyRepository.SaveAsync(history);
        }
    }
}
