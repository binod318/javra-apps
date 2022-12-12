using Foundation;
using Plugin.FilePicker;
using Plugin.FilePicker.Abstractions;
using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using TrialApp.Helper;
using TrialApp.iOS.Helper;
using UIKit;
using Xamarin.Forms;

[assembly: Dependency(typeof(RestoreDb))]
namespace TrialApp.iOS.Helper
{
    public class RestoreDb : IRestoreDb
    {
        public AppDelegate ThisApp
        {
            get { return (AppDelegate)UIApplication.SharedApplication.Delegate; }
        }
        NSUrl _baseUrl;
        private NSUrl makeUrl(string fname = null)
        {
            _baseUrl = NSFileManager.DefaultManager.GetUrlForUbiquityContainer(null);
            var url = _baseUrl.Append("Documents", true);
            if (fname != null) url = url.Append(fname, false);
            return url;
        }

        public async void RestoreMyDb(string sourceFilename, string restoreZipPath, Action showMessage)
        {
            try
            {
                var documents =
                Environment.GetFolderPath(Environment.SpecialFolder.Personal);
                var directoryname = Path.Combine(documents, "TrialApp_DbRestore");
                Directory.CreateDirectory(directoryname);
                var unzipPath = Path.Combine(directoryname, restoreZipPath);
                var filePath = Path.Combine(directoryname, "TransactionRestoreDb");
                
                FileData filedata = new FileData();

                //filedata = await new FilePickerImplementation().PickFile();
                filedata = await CrossFilePicker.Current.PickFile();
                if (filedata?.DataArray == null)
                    return;
                #region popup
                showMessage();
                #endregion
                var databaseFile = filedata.DataArray;
                File.WriteAllBytes(unzipPath, databaseFile);
                
                ZipUtil.UnZipFiles(unzipPath, filePath, string.Empty, false);

                var dbFolder = Path.Combine(filePath, "TrialApp_DbBackup");
                if (Directory.Exists(dbFolder))
                {
                    //var dbFilePath = Path.Combine(dbFolder, "TransactionDb_Backup.db");
                    var dbFilePath = Directory.GetFiles(dbFolder)?.FirstOrDefault(p => Path.GetExtension(p).Equals(".db", StringComparison.CurrentCultureIgnoreCase));
                    if (dbFilePath != null)
                    {

                        if (File.Exists(sourceFilename))
                            File.Delete(sourceFilename);

                        File.Move(dbFilePath, sourceFilename);
                        Directory.Delete(dbFolder, true);
                    }
                }

                await Task.Delay(700);
            }
            catch (Exception)
            {
                //await page.DisplayAlert("Backup Failed", $"Unable to save to iCloud at present\r\n{ex.Message}", "OK");
            }

        }

        public static Stream GenerateStreamFromString(string s)
        {
            var stream = new MemoryStream();
            var writer = new StreamWriter(stream);
            writer.Write(s);
            writer.Flush();
            stream.Position = 0;
            return stream;
        }
        public async System.Threading.Tasks.Task CopyFileAsync(Stream source1, string destinationPath)
        {
            using (Stream source = source1)
            {
                using (Stream destination = File.Create(destinationPath))
                {
                    await source.CopyToAsync(destination);
                }
            }
        }

    }
    class ZipDocument : UIDocument
    {
        private byte[] _data;

        public ZipDocument(NSUrl url, MemoryStream data = null) : base(url)
        {
            _data = data == null ? new byte[0] : data.ToArray();
        }

        public override bool LoadFromContents(NSObject contents, string typeName, out NSError outError)
        {
            outError = null;
            if (contents != null)
            {
                _data = ((NSData)contents).ToArray();
            }
            return true;
        }

        public override NSObject ContentsForType(string typeName, out NSError outError)
        {
            outError = null;
            return NSData.FromArray(_data);
        }
    }
}