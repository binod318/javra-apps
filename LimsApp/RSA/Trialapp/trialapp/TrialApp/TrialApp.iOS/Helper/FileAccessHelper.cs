using Foundation;
using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using TrialApp.Helper;
using TrialApp.iOS.Helper;
using UIKit;
using Xamarin.Forms;

[assembly: Dependency(typeof(FileAccessHelper))]
[assembly: Dependency(typeof(PhotoPickerService))]
namespace TrialApp.iOS.Helper
{
    public class FileAccessHelper : IFileAccessHelper
    {
        #region Computed Properties

        public AppDelegate ThisApp
        {
            get { return (AppDelegate)UIApplication.SharedApplication.Delegate; }
        }

        #endregion

        public string GetLocalFilePath(string filename)
        {
            // Storing the database here is a best practice.
            string path = Environment.GetFolderPath(Environment.SpecialFolder.Personal);
            return Path.Combine(path, filename);
        }

        public void CopyFile(string sourceFilename, string destinationFilename, bool overwrite)
        {
            var sourcePath = GetLocalFilePath(sourceFilename);
            var destinationPath = GetLocalFilePath(destinationFilename);

            File.Copy(sourcePath, destinationPath, overwrite);
        }

        //public async Task CopyFileAsync(string sourcePath, string destinationPath)
        //{
        //    using (Stream source = File.OpenRead(sourcePath))
        //    {
        //        using (Stream destination = File.Create(destinationPath))
        //        {
        //            await source.CopyToAsync(destination);
        //        }
        //    }
        //}

        public bool DoesFileExist(string filename)
        {
            var fullPath = GetLocalFilePath(filename);
            return File.Exists(fullPath);
        }

        public async Task<string> BackUpFileAsync(string sourceFilename, string destinationFilename, bool overwrite)
        {
            try
            {
                var documents = Environment.GetFolderPath(Environment.SpecialFolder.Personal);
                var directoryname = Path.Combine(documents, "TrialApp_DbBackup");
                Directory.CreateDirectory(directoryname);
                var filePath = Path.Combine(directoryname, destinationFilename);

                var dbName = Path.GetFileName(sourceFilename);
                var dbPath = Path.Combine(directoryname, dbName);
                File.Copy(sourceFilename, dbPath, true);
                //await CopyFileAsync(sourceFilename, dbPath);

                var zipfilePath = Path.Combine(documents, "TransactionDb.zip");
                ZipUtil.ZipFiles(Path.GetDirectoryName(dbPath), zipfilePath, string.Empty);

                return await EmailHelper.SendDefaultMailAsync(zipfilePath);
            }
            catch
            {
                return "Unable to backup database.";
            }
            
            
        }

        public static async Task CopyFileAsync(string sourceFilePath, string destinationFilePath)
        {
            using (FileStream sourceStream = File.Open(sourceFilePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
            using (FileStream destinationStream = File.Create(destinationFilePath))
            {
                await sourceStream.CopyToAsync(destinationStream);
            }
        }

        public async Task RestoreDatabaseAsync(string dbPath, byte[] databaseFile, string filename)
        {
            //var documents =
            //Environment.GetFolderPath(Environment.SpecialFolder.Personal);
            //var directoryname = Path.Combine(documents, "TrialApp_DbBackup");

            //var backupDatabaseFiles = Directory.EnumerateFiles(directoryname)?.ToList();
            //if (backupDatabaseFiles != null)
            //{
            //    var backupDatabaseFile = backupDatabaseFiles.LastOrDefault(p => p.Split('.').Last().Equals("db", StringComparison.CurrentCultureIgnoreCase));
            //    await CopyFileAsync(backupDatabaseFile, dbPath);
            //}
        }

        public Task DeleteFileFromLocation(string fileLocation)
        {
            throw new NotImplementedException();
        }

        Task<MemoryStream> IFileAccessHelper.GetImageStreamAsync(string fileLocation)
        {
            throw new NotImplementedException();
        }
    }

    public class PhotoPickerService : IPhotoPickerService
    {
        TaskCompletionSource<Stream> taskCompletionSource;
        UIImagePickerController imagePicker;

        public Task<Stream> GetImageStreamAsync()
        {
            // Create and define UIImagePickerController
            imagePicker = new UIImagePickerController
            {
                SourceType = UIImagePickerControllerSourceType.PhotoLibrary,
                MediaTypes = UIImagePickerController.AvailableMediaTypes(UIImagePickerControllerSourceType.PhotoLibrary)
            };

            // Set event handlers
            imagePicker.FinishedPickingMedia += OnImagePickerFinishedPickingMedia;
            imagePicker.Canceled += OnImagePickerCancelled;

            // Present UIImagePickerController;
            UIWindow window = UIApplication.SharedApplication.KeyWindow;
            var viewController = window.RootViewController;
            viewController.PresentViewController(imagePicker, true, null);

            // Return Task object
            taskCompletionSource = new TaskCompletionSource<Stream>();
            return taskCompletionSource.Task;
        }
        void OnImagePickerFinishedPickingMedia(object sender, UIImagePickerMediaPickedEventArgs args)
        {
            UIImage image = args.EditedImage ?? args.OriginalImage;

            if (image != null)
            {
                // Convert UIImage to .NET Stream object
                NSData data;
                if (args.ReferenceUrl.PathExtension.Equals("PNG") || args.ReferenceUrl.PathExtension.Equals("png"))
                {
                    data = image.AsPNG();
                }
                else
                {
                    data = image.AsJPEG(1);
                }
                Stream stream = data.AsStream();

                UnregisterEventHandlers();

                // Set the Stream as the completion of the Task
                taskCompletionSource.SetResult(stream);
            }
            else
            {
                UnregisterEventHandlers();
                taskCompletionSource.SetResult(null);
            }
            imagePicker.DismissModalViewController(true);
        }

        void OnImagePickerCancelled(object sender, EventArgs args)
        {
            UnregisterEventHandlers();
            taskCompletionSource.SetResult(null);
            imagePicker.DismissModalViewController(true);
        }

        void UnregisterEventHandlers()
        {
            imagePicker.FinishedPickingMedia -= OnImagePickerFinishedPickingMedia;
            imagePicker.Canceled -= OnImagePickerCancelled;
        }
    }
}