using Android.Content;
using System;
using System.IO;

namespace TrialApp.Droid.Helper
{
    public static class EmailHelper
    {
        [Obsolete]
        public static void UploadBackupDatabaseAsync(string sourceFilename)
        {
            var mail = new System.Net.Mail.MailMessage();
            var SmtpServer = new System.Net.Mail.SmtpClient("smtp.gmail.com");
            mail.From = new System.Net.Mail.MailAddress("trialapp@javra.com");
            mail.To.Add("binod.gurung@javra.com");
            mail.Subject = "Trialapp Database backup";
            mail.Body = "mail with attachment";

            System.Net.Mail.Attachment attachment;
            attachment = new System.Net.Mail.Attachment(sourceFilename);
            mail.Attachments.Add(attachment);

            SmtpServer.Port = 587;
            SmtpServer.Credentials = new System.Net.NetworkCredential("ios.javra@gmail.com", "Iphone@Dev");
            SmtpServer.EnableSsl = true;

            SmtpServer.Send(mail);
        }


        public static string SendDefaultMailAsync(Context ctx, string subject, string emailText, string sourceFilePath)
        {
            try
            {
                var fileName = Path.GetFileName(sourceFilePath);

                var file = new Java.IO.File(sourceFilePath);

                //Android.Net.Uri fileUri = Android.Net.Uri.FromFile(file);
                Android.Net.Uri fileUri = Android.Support.V4.Content.FileProvider.GetUriForFile(ctx,
                        ctx.PackageName + ".fileprovider",
                        file);

                var email = new Intent(Intent.ActionSend);
                email.PutExtra(Intent.ExtraSubject, subject);
                email.PutExtra(Intent.ExtraText, emailText);
                email.PutExtra(Intent.ExtraStream, fileUri);

                ctx.GetExternalCacheDirs();

                email.SetType("message/rfc822");
                
                ctx.StartActivity(Intent.CreateChooser(email, "Send email..."));

                return "";
            }
            catch (Exception ex)
            {
                //return "Unable to backup database.";
                return ex.Message;
            }
        }
    }
}