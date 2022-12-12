using System.IO;
using Xamarin.Forms;
using TrialApp.iOS;
using System;
using TrialApp.Common;

[assembly: Dependency(typeof(FileHelper))]
namespace TrialApp.iOS
{
   public class FileHelper : IFileHelper
    {
        public string GetLocalFilePath(string filename)
        {
            string docFolder = Environment.GetFolderPath(Environment.SpecialFolder.Personal);
            string libFolder = Path.Combine(docFolder, "..", "Library", "Databases");

            if (!Directory.Exists(libFolder))
            {
                Directory.CreateDirectory(libFolder);
            }

            return Path.Combine(libFolder, filename);
            // return Path.Combine(Environment.SpecialFolder.ApplicationData.ToString(), filename);
        }
    }
}
