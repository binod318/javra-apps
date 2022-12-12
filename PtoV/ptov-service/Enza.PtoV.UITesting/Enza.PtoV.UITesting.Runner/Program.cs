using Enza.PtoV.UITesting.Tests;
using NUnitLite;
using System;
using System.Configuration;
using System.IO;
using System.Net.Mail;

namespace Enza.PtoV.UITesting.Runner
{
    public static class Program
    {
        public static int Main(string[] args)
        {
            var arguements = new[]
            {
                "--trace=Off",
                "--labels=Off",
                "-noh"
            };
            var result = new AutoRun(typeof(PtoVTest).Assembly).Execute(arguements);
            SendReport();
            return result;
        }

        private static void SendReport()
        {
            var reportDir = Path.Combine(AppContext.BaseDirectory, @"Reports\");
            var fileName = Path.Combine(reportDir, "index.html");
            if (File.Exists(fileName))
            {
                //send email
                using (var client = new SmtpClient())
                {
                    var msg = new MailMessage
                    {
                        Subject = "PtoV UI Test Report",
                        Body = "Please find the test report attached herewith."
                    };
                    var recipients = ConfigurationManager.AppSettings["ReportRecipients"]
                        .Split(new[] { ',', ';' }, StringSplitOptions.RemoveEmptyEntries);
                    foreach(var recipient in recipients)
                    {
                        msg.To.Add(recipient);
                    }                    
                    msg.Attachments.Add(new Attachment(fileName));
                    client.Send(msg);
                }
            }
        }
    }
}
