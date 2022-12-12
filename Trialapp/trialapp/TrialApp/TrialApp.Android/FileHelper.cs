using System;
using System.IO;
using TrialApp.Common;
using TrialApp.Droid;
using Xamarin.Forms;

[assembly: Dependency(typeof(FileHelper))]
namespace TrialApp.Droid
{
   public class FileHelper : IFileHelper
    {
        public string GetLocalFilePath(string filename)
        {
            string path = Environment.GetFolderPath(Environment.SpecialFolder.Personal);
            return Path.Combine(path, filename);
        }
    }
}
