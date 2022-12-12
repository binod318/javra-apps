using TrialApp.Droid;
using System;
using System.Collections.Generic;
using System.Text;
using Xamarin.Forms;
using System.IO;
using Android.Content;
using TrialApp.Helper;
using System.Threading.Tasks;
using TrialApp.Droid.Helper;
using Java.Util.Zip;
using System.Linq;
using Xamarin.Essentials;

[assembly: Dependency(typeof(FileAccessHelper))]
[assembly: Dependency(typeof(PhotoPickerService))]
namespace TrialApp.Droid
{
    public class FileAccessHelper : IFileAccessHelper
    {
        static Context _context;

        public static void Init(Context context)
        {
            _context = context;
        }

        public string GetLocalFilePath(string filename)
        {
            // Storing the database here is a best practice.
            string path = System.Environment.GetFolderPath(System.Environment.SpecialFolder.Personal);
            return System.IO.Path.Combine(path, filename);
        }

        public void CopyFile(string sourceFilename, string destinationFilename, bool overwrite)
        {
            var sourcePath = GetLocalFilePath(sourceFilename);
            var destinationPath = GetLocalFilePath(destinationFilename);

            System.IO.File.Copy(sourcePath, destinationPath, overwrite);
        }

        public async Task CopyFileAsync(string sourcePath, string destinationPath)
        {
            using (Stream source = File.OpenRead(sourcePath))
            {
                using (Stream destination = File.Create(destinationPath))
                {
                    await source.CopyToAsync(destination);
                }
            }
        }

        public bool DoesFileExist(string filename)
        {
            var fullPath = GetLocalFilePath(filename);
            return System.IO.File.Exists(fullPath);
        }

        public async Task<string> BackUpFileAsync(string sourceFilename, string destinationFilename, bool overwrite)
        {
            var emailInfo = Platform.CurrentActivity.PackageManager
            .GetApplicationInfo(Platform.CurrentActivity.PackageName,
                             Android.Content.PM.PackageInfoFlags.MetaData).MetaData;


            //Java.IO.File sdCard = Android.OS.Environment.ExternalStorageDirectory;
            //var dbPath = sdCard.AbsoluteFile + "/" + "TrialApp_DbBackup";
            var dbPath = Environment.GetFolderPath(Environment.SpecialFolder.Personal) + "/" + "TrialApp_DbBackup";
            //var dbPath = _context.GetExternalFilesDir(null) + "/" + "TrialApp_DbBackup";
            Java.IO.File dir = new Java.IO.File(dbPath);

            if (Directory.Exists(dir.AbsolutePath))
            {
                Directory.Delete(dir.AbsolutePath, true);
            }

            //if (!System.IO.File.Exists(dbPath))
            dir.Mkdir();

            
            var filePath = Path.Combine(dir.AbsolutePath, destinationFilename);
            await this.CopyFileAsync(sourceFilename, filePath);
            
            var zipfilePath = Path.Combine(dir.AbsolutePath, "TransactionDb.zip");
            
            ZipUtil.ZipFiles(Path.GetDirectoryName(filePath), zipfilePath, string.Empty);

            //Send email
            var subject = emailInfo.GetString("Subject");
            var emailText = emailInfo.GetString("EmailText");
            
            return EmailHelper.SendDefaultMailAsync(_context, subject, emailText, zipfilePath);
        }


        public async Task RestoreDatabaseAsync(string dbPath, byte[] databaseFile, string filename)
        {
            Java.IO.File sdCard = Android.OS.Environment.ExternalStorageDirectory;
            var restorePath = sdCard.AbsoluteFile + "/" + "TrialApp_DbRestore";
            Java.IO.File dir = new Java.IO.File(restorePath);

            if (!File.Exists(restorePath))
                dir.Mkdir();


            var filePath = Path.Combine(restorePath, "TransactionRestoreDb");
            var unzipPath = Path.Combine(dir.AbsolutePath, "TransactionRestoreDb.zip");

            File.WriteAllBytes(unzipPath, databaseFile);


            ZipUtil.UnZipFiles(unzipPath, filePath, string.Empty, false);

            var dbFolder = Path.Combine(filePath, "TrialApp_DbBackup");
            if (Directory.Exists(dbFolder))
            {

                var dbFilePath = Directory.GetFiles(dbFolder)?.FirstOrDefault(p => Path.GetExtension(p).Equals(".db", StringComparison.CurrentCultureIgnoreCase));
                if (dbFilePath != null)
                {
                    if (File.Exists(dbPath))
                        File.Delete(dbPath);

                    File.Move(dbFilePath, dbPath);
                    Directory.Delete(restorePath, true);
                }

            }

            await Task.Delay(700);

            //Decompress decompress = new Decompress(unzipPath, filePath);
            //decompress.UnZip();
            //System.IO.File.WriteAllBytes(dbPath, databaseFile);
        }

        public Task DeleteFileFromLocation(string fileLocation)
        {
            throw new NotImplementedException();
        }

        public Task<MemoryStream> GetImageStreamAsync(string fileLocation)
        {
            throw new NotImplementedException();
        }
    }
    public class PhotoPickerService : IPhotoPickerService
    {
        public Task<Stream> GetImageStreamAsync()
        {
            // Define the Intent for getting images
            Intent intent = new Intent();
            intent.SetType("image/*");
            intent.SetAction(Intent.ActionGetContent);

            // Start the picture-picker activity (resumes in MainActivity.cs)
            MainActivity.Instance.StartActivityForResult(
                Intent.CreateChooser(intent, "Select Picture"),
                MainActivity.PickImageId);

            // Save the TaskCompletionSource object as a MainActivity property
            MainActivity.Instance.PickImageTaskCompletionSource = new TaskCompletionSource<Stream>();

            // Return Task object
            return MainActivity.Instance.PickImageTaskCompletionSource.Task;
        }
    }

}

