using Xamarin.Forms;
using System.Threading.Tasks;
using TrialApp.Helper;
using System.IO;
using System;
using Stormlion.PhotoBrowser;
using System.Collections.Generic;
using TrialApp.Models;

namespace TrialApp.ViewModels
{
    public class PictureBaseViewModel : BaseViewModel
    {
        #region private variables

        private ImageSource _imageToUpload;
        private bool _imagePrevPopup = false;
        public Stream streamImg;
        private PhotoBrowser myPhotoBrowser;

        #endregion

        #region public properties

        public PhotoBrowser MyPhotoBrowser
        {
            get { return myPhotoBrowser; }
            set { myPhotoBrowser = value; OnPropertyChanged(); }
        }

        public ImageSource ImageToUpload
        {
            get { return _imageToUpload; }
            set { _imageToUpload = value; OnPropertyChanged(); }
        }

        public bool ImagePrevPopup
        {
            get { return _imagePrevPopup; }
            set { _imagePrevPopup = value; OnPropertyChanged(); }
        }

        public List<string> PictureUrlList { get; set; }

        public string PictureLocation;

        public TrialImage SelectedTrialImage { get; set; }


        #endregion


        public async Task UploadPhotoFromGalleryAsync()
        {
            PictureLocation = "";
            var file = "";
            streamImg = await DependencyService.Get<IPhotoPickerService>().GetImageStreamAsync();
            if (streamImg != null)
            {
                if (Device.RuntimePlatform == Device.UWP)
                {
                    var appDataFolder = System.Environment.GetFolderPath(System.Environment.SpecialFolder.CommonApplicationData);
                    if (!Directory.Exists(appDataFolder))
                        Directory.CreateDirectory(appDataFolder);
                    file = Path.Combine(appDataFolder, "tempTrialImg.jpg");
                }
                else
                {
                    file = Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.Personal), "tempTrialImg.jpg");

                }
                try
                {
                    //while (!IsFileReady(file)) {
                        using (var fileStream = new FileStream(file, FileMode.OpenOrCreate, FileAccess.Write, FileShare.ReadWrite))
                        {
                            streamImg.CopyTo(fileStream);
                            fileStream.Dispose();
                            fileStream.Close();
                        }
                    //}
                    
                }
                catch (Exception)
                {
                   await Task.Delay(1000);
                    using (var fileStream = new FileStream(file.Replace("Img.jpg", "Imgg.jpg"), FileMode.OpenOrCreate, FileAccess.Write, FileShare.ReadWrite))
                    {
                        streamImg.CopyTo(fileStream);
                        fileStream.Dispose();
                        fileStream.Close();
                    }
                }
                
                //ImageToUpload = null;
                //ImageToUpload = ImageSource.FromFile(file);


                ImagePrevPopup = true;
                PictureLocation = file;
            }
        }
        public static bool IsFileReady(string filename)
        {
            // If the file can be opened for exclusive access it means that the file
            // is no longer locked by another process.
            try
            {
                using (FileStream inputStream = File.Open(filename, FileMode.Open, FileAccess.Read, FileShare.None))
                    return inputStream.Length > 0;
            }
            catch (Exception)
            {
                return false;
            }
        }
        public async Task UploadPictureConfirmed(int trialEzid, string trialEntryEzid, string fieldnumber, string varietyName, string traitID,string traitName)
        {
            try
            {
                var guid = DateTime.Now.ToString("yyyyMMddHHmmssfff");
                //traitID added
                string path;
                string fileName;
                //string tempPath;

                if (Device.RuntimePlatform == Device.UWP)
                {
                    if (string.IsNullOrWhiteSpace(traitID))
                        path = Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.CommonApplicationData), "TrialAppPictures", trialEzid.ToString(), trialEntryEzid);
                    else
                        path = Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.CommonApplicationData), "TrialAppPictures", trialEzid.ToString(), trialEntryEzid, traitID);
                }
                else
                {
                    if (string.IsNullOrWhiteSpace(traitID))
                        path = Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.Personal), "TrialAppPictures", trialEzid.ToString(), trialEntryEzid);
                    else
                        path = Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.Personal), "TrialAppPictures", trialEzid.ToString(), trialEntryEzid, traitID);
                }

                if (!Directory.Exists(path))
                    Directory.CreateDirectory(path);
                //trait name added            
                if (string.IsNullOrWhiteSpace(traitName))
                    fileName = Path.Combine(path, guid + "_" + fieldnumber + "_" + varietyName + ".jpg");
                else
                {
                    traitName = traitName.Trim().Replace(' ', '-');
                    fileName = Path.Combine(path, guid + "_" + fieldnumber + "_" + varietyName + "_" + traitName + ".jpg");
                }

                //tempPath = Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.Personal), "tempTrialImg.jpg");
                if (File.Exists(PictureLocation))
                {
                    File.Copy(PictureLocation, fileName);
                    if (Device.RuntimePlatform == Device.UWP)
                    {
                        var fileAccessHelper = DependencyService.Get<IFileAccessHelper>();
                        await fileAccessHelper.DeleteFileFromLocation(PictureLocation);
                    }
                    else
                    {
                        File.Delete(PictureLocation);
                    }

                }
                ImagePrevPopup = false;
                await Application.Current.MainPage.DisplayAlert("Saved", "Image Saved!", "Ok");

            }
            catch (Exception ex)
            {
               await Application.Current.MainPage.DisplayAlert("Error!!", "Error occured while uploading picture, please contact app administrator with th following Message:: "
                   +ex.Message + "\n" + ex.StackTrace, "OK");
            }
        }

        public async Task UploadPhotoFromCameraAsync(string filePathWithName)
        {            
            ImageToUpload = ImageSource.FromFile(filePathWithName);
            ImagePrevPopup = true;            
        }

    }
}
