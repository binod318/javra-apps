using System;
using System.IO;
using System.Threading.Tasks;
using TrialApp.Helper;
using TrialApp.UWP.Helper;
using Windows.Storage;
using Xamarin.Forms;
using Xamarin.Essentials;
using System.Collections.Generic;
using System.Linq;
using Windows.Storage.Search;
using Windows.Storage.Pickers;
using Windows.Storage.Streams;

[assembly: Dependency(typeof(FileAccessHelper))]
[assembly: Dependency(typeof(PhotoPickerService))]
namespace TrialApp.UWP.Helper
{
    public class FileAccessHelper : IFileAccessHelper
    {       
        public async Task<string> BackUpFileAsync(string sourceFilename, string destinationFilename, bool overwrite)
        {

            try
            {
                var documents = FileSystem.CacheDirectory;
                //var documents = Environment.GetFolderPath(Environment.SpecialFolder.Personal);
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

                //now remove file 
            }
            catch(Exception e)
            {
                return "Unable to backup database.";
            }
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

        public bool DoesFileExist(string fileName)
        {
            var fullPath = GetLocalFilePath(fileName);
            return System.IO.File.Exists(fullPath);
        }

        public string GetLocalFilePath(string fileName)
        {
            return Path.Combine(ApplicationData.Current.LocalFolder.Path, fileName);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="dbPath"> Database file path (local folder of application where local database exists) </param>
        /// <param name="databaseFile"> byte array of database zip file</param>
        /// <param name="filename">Database file name insize zip folder (now required for now) </param>
        /// <returns></returns>
        public async Task RestoreDatabaseAsync(string dbPath, byte[] databaseFile, string filename = null)
        {
            var storageFolder = ApplicationData.Current.TemporaryFolder;
            //var storageFolder = FileSystem.CacheDirectory;

            var dbRestoreFolder = await storageFolder.CreateFolderAsync("TrialApp_DbRestore", CreationCollisionOption.ReplaceExisting);

            //create file to application internal folder
            var unzipPath = Path.Combine(storageFolder.Path, "TrialApp_DbRestore");
            //var unzipPath = storageFolder.Path;
            var unzipFileName = "TransactionRestoreDb.zip";

            //create new file without content
            var storageFile = await dbRestoreFolder.CreateFileAsync(unzipFileName, CreationCollisionOption.ReplaceExisting);

            //write file with byte stream
            await FileIO.WriteBytesAsync(storageFile, databaseFile);            

            //unzip the byte array file first
            ZipUtil.UnZipFiles(Path.Combine(unzipPath,unzipFileName), unzipPath, string.Empty, false);

            //var dbFolder = Path.Combine(filePath, "TrialApp_DbBackup");
            if (Directory.Exists(unzipPath))
            {
                //in zip contains folder so we need to look inside that folder or we need search deep scan
                var restoredFolder = await dbRestoreFolder.GetFolderAsync("TrialApp_DbBackup");
                if(restoredFolder != null)
                {
                    var restoredDbFile = await restoredFolder.GetFilesAsync();
                    var dbfile = restoredDbFile.FirstOrDefault(x => x.Name.ToLower() == "transaction.db");
                    if(dbfile != null)
                    {
                        //await dbfile.MoveAsync(ApplicationData.Current.LocalFolder, "Transaction.db", NameCollisionOption.ReplaceExisting);
                        await dbfile.CopyAsync(ApplicationData.Current.LocalFolder, "Transaction.db", NameCollisionOption.ReplaceExisting);
                    }

                }

            }
            await dbRestoreFolder.DeleteAsync(StorageDeleteOption.PermanentDelete);
        }

        public async Task DeleteFileFromLocation(string fileLocation)
        {
            var storageFile1 = await StorageFile.GetFileFromPathAsync(fileLocation);
            await storageFile1.DeleteAsync(StorageDeleteOption.PermanentDelete);
            
        }

        public async Task<MemoryStream> GetImageStreamAsync(string fileLocation)
        {
           
            var memoryStream = new MemoryStream();

            using (var fileStream = new FileStream(fileLocation, FileMode.Open, FileAccess.Read))
            {
                fileStream.CopyTo(memoryStream);
                fileStream.Dispose();
            }
            memoryStream.Position = 0;


            //var storageFile = await StorageFile.GetFileFromPathAsync(fileLocation);
            //var imageStream = await storageFile.OpenStreamForReadAsync();
            
            return memoryStream;
        }

        //public async ImageSource GetImageSourceFromFile(string fileLocation)
        //{

        //    var mediaFile = new MediaFile("/storage/emulated/0/Android/data/com.companyname/files/Pictures/IMG_20200831_175948.jpg", () =>
        //    {
        //        return new MemoryStream(bytes); // Your byte array is the argument
        //    });

        //    image.Source = ImageSource.FromStream(() => {
        //        return mediaFile.GetStream();
        //    });

        //    var storageFile1 = await StorageFile.GetFileFromPathAsync(fileLocation);
        //    var stream = storageFile1.OpenStreamForReadAsync();
        //    file.Dispose();
        //    return stream;


        //    await storageFile1.DeleteAsync(StorageDeleteOption.PermanentDelete);
        //}
    }

    public class PhotoPickerService : IPhotoPickerService
    {
        public async Task<Stream> GetImageStreamAsync()
        {
            // Create and initialize the FileOpenPicker
            FileOpenPicker openPicker = new FileOpenPicker
            {
                ViewMode = PickerViewMode.Thumbnail,
                SuggestedStartLocation = PickerLocationId.PicturesLibrary,
            };

            openPicker.FileTypeFilter.Add(".jpg");
            openPicker.FileTypeFilter.Add(".jpeg");
            openPicker.FileTypeFilter.Add(".png");

            // Get a file and return a Stream
            StorageFile storageFile = await openPicker.PickSingleFileAsync();

            if (storageFile == null)
            {
                return null;
            }

            IRandomAccessStreamWithContentType raStream = await storageFile.OpenReadAsync();
            return raStream.AsStreamForRead();
        }
    }
}
