using System;
using System.IO;
using System.Threading.Tasks;
using Xamarin.Essentials;

namespace TrialApp.UWP.Helper
{
    public static class EmailHelper
    {
        
        public static async Task<string> SendDefaultMailAsync(string sourceFilePath)
        {
            try
            {


                var message = new EmailMessage
                {
                    Subject = "Trialapp Database backup",
                    Body = "Trialapp UWP Database backup file is attached here."
                };
                var fn = "File.zip";
                var file = Path.Combine(FileSystem.CacheDirectory, fn);
                File.Copy(sourceFilePath, file);

                message.Attachments.Add(new EmailAttachment(file));

                await Email.ComposeAsync(message).ConfigureAwait(false);





                //var message = new EmailMessage
                //{
                //    Subject = "Trialapp Database backup",
                //    Body = "Trialapp UWP Database backup file is attached here."
                //};

                //message.Attachments.Add(new EmailAttachment(sourceFilePath));
                //await Email.ComposeAsync(message);

                return "";


            }
            catch (Exception ex)
            {
                return ex.Message;
            }
        }

    }
}