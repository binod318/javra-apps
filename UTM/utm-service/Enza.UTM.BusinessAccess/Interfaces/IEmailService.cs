using System;
using System.Collections.Generic;
using System.Net.Mail;
using System.Threading.Tasks;

namespace Enza.UTM.BusinessAccess.Interfaces
{
    public interface IEmailService
    {
        Task SendEmailAsync(MailAddress from, IEnumerable<string> recipients, string subject, string body, Action<AttachmentCollection> attachments, string priority = null);
        Task SendEmailAsync(IEnumerable<string> recipients, string subject, string body, Action<AttachmentCollection> attachments, string priority = null);
        Task SendEmailAsync(IEnumerable<string> recipients, string subject, string body, string priority = null);
        Task SendEmailAsync(string from, IEnumerable<string> recipients, string subject, string body, string priority = null);
    }
}
