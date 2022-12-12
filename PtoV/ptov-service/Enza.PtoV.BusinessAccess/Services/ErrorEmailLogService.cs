using System.Collections.Generic;
using System.Threading.Tasks;
using Enza.PtoV.BusinessAccess.Interfaces;
using Enza.PtoV.DataAccess.Data.Interfaces;

namespace Enza.PtoV.BusinessAccess.Services
{
    public class ErrorEmailLogService : IErrorEmailLogService
    {
        private readonly IErrorEmailLogRepository _errorEmailLogRepository;
        public ErrorEmailLogService(IErrorEmailLogRepository errorEmailLogRepository)
        {
            _errorEmailLogRepository = errorEmailLogRepository;
        }

        public Task<IEnumerable<string>> GetUnsentEmailLogsAsync(string cropCodes)
        {
            return _errorEmailLogRepository.GetUnsentEmailLogsAsync(cropCodes);
        }

        public Task UpdateSentEmailLogAsync(string cropCode, string errorMessage)
        {
            return _errorEmailLogRepository.UpdateSentEmailLogAsync(cropCode, errorMessage);
        }
    }
}
