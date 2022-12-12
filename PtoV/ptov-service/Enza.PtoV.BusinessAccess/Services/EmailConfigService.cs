using System.Collections.Generic;
using System.Threading.Tasks;
using Enza.PtoV.BusinessAccess.Interfaces;
using Enza.PtoV.DataAccess.Data.Interfaces;
using Enza.PtoV.Entities;
using Enza.PtoV.Entities.Args;

namespace Enza.PtoV.BusinessAccess.Services
{
    public class EmailConfigService : IEmailConfigService
    {
        private readonly IEmailConfigRepository _emailConfigRepository;
        private readonly IEmailService _emailService;
        public EmailConfigService(IEmailConfigRepository emailConfigRepository, IEmailService emailService)
        {
            _emailConfigRepository = emailConfigRepository;
            _emailService = emailService;
        }

        public Task AddAsync(EmailConfig entity)
        {
            return _emailConfigRepository.AddAsync(entity);
        }

        public Task DeleteAsync(int configID)
        {
            return _emailConfigRepository.DeleteAsync(new EmailConfig
            {
                ConfigID = configID
            });
        }

        public Task<IEnumerable<EmailConfig>> GetAllAsync(EmailConfigRequestArgs args)
        {
            return _emailConfigRepository.GetAllAsync(args);
        }

        public Task<EmailConfig> GetEmailConfigAsync(string groupName, string cropCode)
        {
            return _emailConfigRepository.GetEmailConfigAsync(groupName, cropCode);
        }

        public Task<EmailConfig> GetEmailConfigByGroupAsync(string groupName)
        {
            return _emailConfigRepository.GetEmailConfigByGroupAsync(groupName);
        }

    }
}
