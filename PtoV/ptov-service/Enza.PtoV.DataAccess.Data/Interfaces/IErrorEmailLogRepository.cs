using Enza.PtoV.DataAccess.Interfaces;
using Enza.PtoV.Entities;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Enza.PtoV.DataAccess.Data.Interfaces
{
    public interface IErrorEmailLogRepository : IRepository<object>
    {
        Task<IEnumerable<string>> GetUnsentEmailLogsAsync(string cropCodes);
        Task UpdateSentEmailLogAsync(string cropCode, string errorMessage);
    }
}
