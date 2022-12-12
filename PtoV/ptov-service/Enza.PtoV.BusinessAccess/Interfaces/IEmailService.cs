using System;
using System.Collections.Generic;
using System.Net.Mail;
using System.Threading.Tasks;

namespace Enza.PtoV.BusinessAccess.Interfaces
{
    public interface IEmailService
    {
        Task SendEmailAsync(MailAddress from, IEnumerable<string> recipients, string subject, string body, Action<AttachmentCollection> attachments);
        Task SendEmailAsync(IEnumerable<string> recipients, string subject, string body, Action<AttachmentCollection> attachments);
        Task SendEmailAsync(IEnumerable<string> recipients, string subject, string body);
    }
}
