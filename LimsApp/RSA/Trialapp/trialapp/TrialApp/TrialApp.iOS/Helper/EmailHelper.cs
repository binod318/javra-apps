using System;
using System.IO;
using System.Threading.Tasks;
using Foundation;
using MailKit;
using MailKit.Net.Imap;
using MessageUI;
using UIKit;

namespace TrialApp.iOS.Helper
{
    public static class EmailHelper
    {
        public static MFMailComposeViewController mailController;
        public static async Task<string> SendDefaultMailAsync(string t_pathpdf)
        {
            try
            { NSData t_dat = NSData.FromFile(t_pathpdf);
                    string t_fname = Path.GetFileName(t_pathpdf.ToString());
                    mailController = new MFMailComposeViewController();

                    var Subject = NSBundle.MainBundle.ObjectForInfoDictionary("Subject")?.ToString();
                    var BodyText = NSBundle.MainBundle.ObjectForInfoDictionary("BodyText")?.ToString();

                    mailController.SetSubject(Subject);
                    mailController.SetMessageBody(BodyText, false);
                    mailController.AddAttachmentData(t_dat, @"application/x-sqlite3", t_fname);

                    mailController.Finished += (object sender, MFComposeResultEventArgs e) =>
                    {
                        Console.WriteLine(e.Result.ToString());
                        e.Controller.DismissViewController(true, null);
                    };

                    await UIApplication.SharedApplication.KeyWindow.RootViewController.PresentViewControllerAsync(mailController, true);
                    return "";
            }
            catch (Exception ex)
            {
                return ex.Message;
            }
        }

        public static bool RetriveMailAttachment()
        {
            try
            {
                using (var client = new ImapClient())
                {
                    // For demo-purposes, accept all SSL certificates
                    client.ServerCertificateValidationCallback = (s, c, h, e) => true;

                    client.Connect("imap.mail.me.com", 993, true);

                    client.Authenticate("joey", "password");

                    // The Inbox folder is always available on all IMAP servers...
                    var inbox = client.Inbox;
                    inbox.Open(FolderAccess.ReadOnly);

                    Console.WriteLine("Total messages: {0}", inbox.Count);
                    Console.WriteLine("Recent messages: {0}", inbox.Recent);

                    for (int i = 0; i < inbox.Count; i++)
                    {
                        var message = inbox.GetMessage(i);
                        Console.WriteLine("Subject: {0}", message.Subject);
                    }

                    client.Disconnect(true);
                }
                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }
    }
}