using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Threading.Tasks;

namespace TrialApp.Helper
{
    public interface IFileAccessHelper
    {
        string GetLocalFilePath(string fileName);
        void CopyFile(string sourceFilename, string destinationFilename, bool overwrite);
        System.Threading.Tasks.Task<string> BackUpFileAsync(string sourceFilename, string destinationFilename, bool overwrite);
        System.Threading.Tasks.Task RestoreDatabaseAsync(string dbPath, byte[] databaseFile, string filename);

        bool DoesFileExist(string fileName);

        /// <summary>
        /// Delete file (Only used for UWP)
        /// </summary>
        /// <param name="fileLocation">physical locatio of file</param>
        /// <returns></returns>
        Task DeleteFileFromLocation(string fileLocation);
        /// <summary>
        /// Get image stream of file (this is only used for UWP)
        /// </summary>
        /// <param name="fileLocation">physical locatio of image file</param>
        /// <returns></returns>
        Task<MemoryStream> GetImageStreamAsync(string fileLocation);

    }
    public interface IPhotoPickerService
    {
        Task<Stream> GetImageStreamAsync();
    }

}
