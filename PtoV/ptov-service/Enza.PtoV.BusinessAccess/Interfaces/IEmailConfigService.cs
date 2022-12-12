using System.Collections.Generic;
using System.Threading.Tasks;
using Enza.PtoV.Entities;
using Enza.PtoV.Entities.Args;

namespace Enza.PtoV.BusinessAccess.Interfaces
{
    public interface IEmailConfigService
    {
        Task<IEnumerable<EmailConfig>> GetAllAsync(EmailConfigRequestArgs args);
        Task AddAsync(EmailConfig entity);
        Task DeleteAsync(int configID);

        Task<EmailConfig> GetEmailConfigByGroupAsync(string groupName);
        Task<EmailConfig> GetEmailConfigAsync(string groupName, string cropCode);
    }

    public class EmailConfigGroups
    {
        public const string PtoV_SYNC_DATA_ERROR = "PtoV_SYNC_DATA_ERROR";
        public const string EXTERNALLOT_SYNC_DATA_ERROR = "EXTERNALLOT_SYNC_DATA_ERROR";
        public const string ENUMBER_SYNC_DATA_ERROR = "ENUMBER_SYNC_DATA_ERROR";
        public const string EXE_ERROR = "EXE_ERROR";
        public const string DEFAULT_EMAIL_GROUP = "DEFAULT_EMAIL_GROUP";
    }
}
