using Enza.PtoV.DataAccess.Interfaces;
using Enza.PtoV.Entities;
using System.Threading.Tasks;

namespace Enza.PtoV.DataAccess.Data.Interfaces
{
    public interface IEmailConfigRepository : IRepository<EmailConfig>
    {
        Task<EmailConfig> GetEmailConfigByGroupAsync(string groupName);
        Task<EmailConfig> GetEmailConfigAsync(string groupName, string cropCode);
    }
}
