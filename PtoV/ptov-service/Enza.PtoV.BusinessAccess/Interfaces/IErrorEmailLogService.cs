using System.Collections.Generic;
using System.Threading.Tasks;

namespace Enza.PtoV.BusinessAccess.Interfaces
{
    public interface IErrorEmailLogService
    {
        Task<IEnumerable<string>> GetUnsentEmailLogsAsync(string cropCodes);
        Task UpdateSentEmailLogAsync(string cropCode, string errorMessage);
    }
}
