using System;
using System.Collections.Generic;
using System.Net.Mail;
using System.Threading.Tasks;
using Enza.UTM.BusinessAccess.Interfaces;

namespace Enza.UTM.BusinessAccess.Services
{
    public class EmailService : IEmailService
    {
        public async Task SendEmailAsync(MailAddress from, IEnumerable<string> recipients, 
            string subject, string body, Action<AttachmentCollection> attachments, string priority = null)
        {
            using(var client = new SmtpClient())
            {
                var msg = new MailMessage
                {
                    Subject = subject,
                    Body = body,
                    IsBodyHtml = true
                };
                if(from != null)
                {
                    msg.From = from;
                }
                msg.To.Add(string.Join(",", recipients));

                if (!string.IsNullOrWhiteSpace(priority) && priority.Contains("high"))
                    msg.Priority = MailPriority.High;

                attachments?.Invoke(msg.Attachments);
                await client.SendMailAsync(msg);
            }
        }
        public Task SendEmailAsync(IEnumerable<string> recipients, string subject, string body, Action<AttachmentCollection> attachments, string priority = null)
        {
            return SendEmailAsync(null, recipients, subject, body, attachments, priority);
        }

        public Task SendEmailAsync(IEnumerable<string> recipients, string subject, string body, string priority = null)
        {
            return SendEmailAsync(recipients, subject, body, null, priority);
        }

        public Task SendEmailAsync(string from, IEnumerable<string> recipients, string subject, string body, string priority = null)
        {
            return SendEmailAsync(new MailAddress(from), recipients, subject, body, null, priority);
        }
    }
}
