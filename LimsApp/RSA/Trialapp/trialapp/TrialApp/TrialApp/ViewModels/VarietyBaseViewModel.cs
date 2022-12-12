using Stormlion.PhotoBrowser;
using Syncfusion.SfCarousel.XForms;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Data;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Input;
using TrialApp.Entities.ServiceResponse;
using TrialApp.Helper;
using TrialApp.Models;
using TrialApp.Services;
using TrialApp.ViewModels.Abstract;
using TrialApp.Views;
using Xamarin.Essentials;
using Xamarin.Forms;

namespace TrialApp.ViewModels
{
    public class VarietyBaseViewModel : GridFilterViewModel
    {
        protected TrialEntryAppService _trialEntryAppService;
        protected FieldSetService _fieldSetService;
        protected TraitService _traitService;
        protected ObservationAppService _observationService;

        public int TrialEZID { get; set; }
        public string TrialName { get; set; }
        public string CropCode { get; set; }
        public bool IsPageLoaded { get; set; }
        public bool PictureviewerPopupVisible { get; set; }
        public ObservableCollection<TrialImage> TrialImages { get; set; }

        #region Add variety properties

        private string varietyName;

        public string VarietyName
        {
            get { return varietyName; }
            set
            {
                varietyName = value;
                if (string.IsNullOrWhiteSpace(varietyName) || string.IsNullOrWhiteSpace(ConsecutiveNumber))
                    ButtonEnabled = false;
                else
                    ButtonEnabled = true;
                OnPropertyChanged();
            }
        }

        private string consecutiveNumber;

        public string ConsecutiveNumber
        {
            get { return consecutiveNumber; }
            set
            {
                consecutiveNumber = value;
                if (string.IsNullOrWhiteSpace(consecutiveNumber) || string.IsNullOrWhiteSpace(VarietyName))
                    ButtonEnabled = false;
                else
                    ButtonEnabled = true;
                OnPropertyChanged();
            }
        }

        private bool buttonEnabled;

        public bool ButtonEnabled
        {
            get { return buttonEnabled; }
            set
            {
                buttonEnabled = value;
                if (buttonEnabled)
                    ButtonColor = Color.FromHex("#2B7DF4");
                else
                    ButtonColor = Color.FromHex("#ebebeb");

                OnPropertyChanged();
            }
        }
        private bool displayMessage;

        public bool DisplayMessage
        {
            get { return displayMessage; }
            set
            {
                displayMessage = value;
                OnPropertyChanged();
            }
        }


        private string confirmationMessage;

        public string ConfirmationMessage
        {
            get { return confirmationMessage; }
            set
            {
                confirmationMessage = value;
                if (string.IsNullOrWhiteSpace(confirmationMessage))
                    DisplayMessage = false;
                else
                    DisplayMessage = true;

                OnPropertyChanged();
            }
        }
        private Color confirmationColor;

        public Color ConfirmationColor
        {
            get { return confirmationColor; }
            set
            {
                confirmationColor = value;
                OnPropertyChanged();
            }
        }
        private Color _buttonColor;

        public Color ButtonColor
        {
            get { return _buttonColor; }
            set
            {
                _buttonColor = value;
                OnPropertyChanged();
            }
        }

        private bool _addVarietyPopupVisible;

        public bool AddVarietyPopupVisible
        {
            get { return _addVarietyPopupVisible; }
            set { _addVarietyPopupVisible = value; OnPropertyChanged(); }
        }

        private bool _historyGridVisible;

        public bool HistoryGridVisible
        {
            get { return _historyGridVisible; }
            set { _historyGridVisible = value; OnPropertyChanged(); }
        }

        private bool _traitInfoVisible;

        public bool TraitInfoVisible
        {
            get { return _traitInfoVisible; }
            set { _traitInfoVisible = value; OnPropertyChanged(); }
        }

        public DateTime MaxDate { get; set; } = DateTime.Today;

        private bool _traitEditorPopupVisible;

        public bool TraitEditorPopupVisible
        {
            get { return _traitEditorPopupVisible; }
            set { _traitEditorPopupVisible = value; OnPropertyChanged(); }
        }

        private string _editorColumnLabel;

        public string EditorColumnLabel
        {
            get { return _editorColumnLabel; }
            set { _editorColumnLabel = value; OnPropertyChanged(); }
        }




        public MemoryStream ImageStream { get; set; }

        private string _traitEditorText;

        public string TraitEditorText
        {
            get { return _traitEditorText; }
            set { _traitEditorText = value; OnPropertyChanged(); }
        }

        private bool _editorReadOnly;

        public bool EditorReadOnly
        {
            get { return _editorReadOnly; }
            set { _editorReadOnly = value; OnPropertyChanged(); }
        }

        #region ButtonProps

        private bool _showNewTrial;

        public bool ShowNewTrial
        {
            get { return _showNewTrial; }
            set { _showNewTrial = value; OnPropertyChanged(); }
        }
        private bool _showHistory;

        public bool ShowHistory
        {
            get { return _showHistory; }
            set { _showHistory = value; OnPropertyChanged(); }
        }
        private bool _showInfo;

        public bool ShowInfo
        {
            get { return _showInfo; }
            set { _showInfo = value; OnPropertyChanged(); }
        }
        private bool _showAdd;

        public bool ShowAdd
        {
            get { return _showAdd; }
            set { _showAdd = value; OnPropertyChanged(); }
        }
        private bool _showUpdate;

        public bool ShowUpdate
        {
            get { return _showUpdate; }
            set { _showUpdate = value; OnPropertyChanged(); }
        }
        private bool _showSave;

        public bool ShowSave
        {
            get { return _showSave; }
            set { _showSave = value; OnPropertyChanged(); }
        }
        private bool _showCancel;

        public bool ShowCancel
        {
            get { return _showCancel; }
            set { _showCancel = value; OnPropertyChanged(); }
        }
        private bool _showHamburger;

        public bool ShowHamburger
        {
            get { return _showHamburger; }
            set { _showHamburger = value; OnPropertyChanged(); }
        }
        private bool _showCamera;
        public bool ShowCamera
        {
            get { return _showCamera; }
            set { _showCamera = value; OnPropertyChanged(); }
        }
        private bool _showGallery;
        public bool ShowGallery
        {
            get { return _showGallery; }
            set { _showGallery = value; OnPropertyChanged(); }
        }

        private bool _showObsDate;

        public bool ShowObsDate
        {
            get { return _showObsDate; }
            set { _showObsDate = value; OnPropertyChanged(); }
        }

        private bool _showNormalObs;

        public bool ShowNormalObs
        {
            get { return _showNormalObs; }
            set { _showNormalObs = value; OnPropertyChanged(); }
        }

        private bool _showObsDatePicker;

        public bool ShowObsDatePicker
        {
            get { return _showObsDatePicker; }
            set { _showObsDatePicker = value; OnPropertyChanged(); }
        }

        public bool ShowUpdateNav
        {
            get { return _showObsDatePicker; }
            set { _showObsDatePicker = value; OnPropertyChanged(); }
        }

        private bool _showUpdateMode;

        public bool ShowUpdateMode
        {
            get { return _showUpdateMode; }
            set { _showUpdateMode = value; OnPropertyChanged(); }
        }


        private string _updateModeText;
        public string UpdateModeText
        {
            get { return _updateModeText; }
            set { _updateModeText = value; OnPropertyChanged(); }
        }

        private ImageSource _updateModeIcon;
        public ImageSource UpdateModeIcon
        {
            get { return _updateModeIcon; }
            set { _updateModeIcon = value; OnPropertyChanged(); }
        }

        private string _navModeIcon;
        public string NavModeIcon
        {
            get { return _navModeIcon; }
            set { _navModeIcon = value; OnPropertyChanged(); }
        }

        private string _obsDateVal = DateTime.Now.Date.ToString("yyyy-MM-dd");


        public string ObsDateVal
        {
            get { return _obsDateVal; }
            set { _obsDateVal = value; OnPropertyChanged(); }
        }

        private string _historyDateVal = "Prev. Observations";

        public string HistoryDateVal
        {
            get { return _historyDateVal; }
            set { _historyDateVal = value; OnPropertyChanged(); }
        }
        #endregion


        public List<object> TrialPropertiesParams { get; set; }
        public ICommand CreateNewVarietyCommand { get; set; }
        public ICommand TrialPropCommand { get; set; }

        #endregion

        public VarietyBaseViewModel()
        {
            _trialEntryAppService = new TrialEntryAppService();
            _fieldSetService = new FieldSetService();
            _traitService = new TraitService();
            _observationService = new ObservationAppService();
            TrialPropCommand = new TrialProperties();
            TrialPropertiesParams = new List<object>();
            DataTableCollection = new DataTable();
            TrialImages = new ObservableCollection<TrialImage>();
        }


        //public DataTable DataTableCollection { get; set; }

        private DataTable dataTableCollection;

        public DataTable DataTableCollection
        {
            get { return dataTableCollection; }
            set { dataTableCollection = value; OnPropertyChanged(); }
        }

        public async Task<string> CheckTrialEntry()
        {
            var data = await _trialEntryAppService.GetTrialEntriesByNameAsync(TrialEZID.ToString(), ConsecutiveNumber, VarietyName);

            if (!data.Any()) return "";

            var datawithsamefield = data.Where(o => o.FieldNumber.ToLower() == ConsecutiveNumber.ToLower());
            var datawithsamename = data.Where(o => o.VarietyName.ToLower() == VarietyName.ToLower());
            if (datawithsamefield.Any())
                return "Fieldnumber " + ConsecutiveNumber + " already exists in current trial with the variety name(s) - " + string.Join(",", datawithsamefield.Select(i => i.VarietyName)) + ".";
            else
                return "Variety " + VarietyName + " already exists in current trial with the fieldnumber(s) - " + string.Join(",", datawithsamename.Select(i => i.FieldNumber)) + ".";

        }
        public async Task ShowImages(string trialEzid)
        {
            IsBusy = true;
            try
            {
                await Task.Delay(10);
                var pics = new List<Photo>();

                var files = new List<string>();
                if (Device.RuntimePlatform == Device.UWP)
                {
                    var dir = Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.CommonApplicationData), "TrialAppPictures", trialEzid);
                    if (!Directory.Exists(dir))
                        Directory.CreateDirectory(dir);
                    files = Directory.GetFiles(Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.CommonApplicationData), "TrialAppPictures", trialEzid),
                    "*.*",
                    SearchOption.AllDirectories).ToList();
                }
                else
                {
                    var dir = Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.Personal), "TrialAppPictures", trialEzid);
                    if (!Directory.Exists(dir))
                        Directory.CreateDirectory(dir);
                    files = Directory.GetFiles(Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.Personal), "TrialAppPictures", trialEzid),
                    "*.*",
                    SearchOption.AllDirectories).ToList();
                }

                var current = Connectivity.NetworkAccess;
                if (current == NetworkAccess.Internet)
                    files = await GetOnlineImages(trialEzid, files);
                if (!files.Any())
                {
                    await Application.Current.MainPage.DisplayAlert("Alert", "No photo added for this trial.", "OK");
                    IsBusy = false;
                    return;
                }

                PictureUrlList = files;

                if (Device.RuntimePlatform == Device.UWP)
                {
                    TrialImages.Clear();
                    PictureviewerPopupVisible = true;
                    if (files.Any())
                    {
                        var fileAccessHelper = DependencyService.Get<IFileAccessHelper>();
                        foreach (var file in files)
                        {
                            var myfile = file.Replace("9999fromblob", "");
                            var fieldNr = "";
                            var varietyName = "";
                            var traitName = "";
                            var date = "";
                            var path = myfile.Split('/');
                            var fileName = path[path.Length - 1];
                            var fileNameOnly = Path.GetFileNameWithoutExtension(fileName); //fileName.Split([".jpg",".png"])[0];
                            var nameSplit = fileNameOnly.Split('_');

                            //first date, second fieldnr, third varietyname, fourth traitName (if length is 4) else there will be no traitName
                            date = nameSplit.Length >= 1 ? nameSplit[0].Replace('-', ' ') : "";
                            fieldNr = nameSplit.Length >= 2 ? nameSplit[1].Replace('-', ' ') : "";
                            varietyName = nameSplit.Length >= 3 ? nameSplit[2].Replace('-', ' ') : "";
                            traitName = nameSplit.Length >= 4 ? nameSplit[3].Replace('-', ' ') : "";

                            var title = "";
                            if (!string.IsNullOrWhiteSpace(traitName))
                                title = fieldNr + "  " + $"{varietyName}\n" + GetPictureDate(date) + $"\n{traitName}";
                            else
                                title = fieldNr + "  " + $"{varietyName}\n" + GetPictureDate(date);

                            //var imageStream = await fileAccessHelper.GetImageStreamAsync(file);

                            try
                            {
                                TrialImages.Add(new TrialImage
                                {
                                    Title = title,
                                    ImageSource = ImageSource.FromFile(myfile),
                                    FromBlob = file.Contains("9999fromblob") ? true : false,
                                    ImageLocation = file
                                });
                            }
                            catch (Exception e)
                            {

                            }

                        }
                    }


                }
                else
                {
                    try
                    {
                        if (files.Count > 0)
                        {
                            foreach (var file in files)
                            {
                                var myfile = file.Replace("9999fromblob", "");
                                var fieldNr = "";
                                var varietyName = "";
                                var traitName = "";
                                var date = "";
                                var path = myfile.Split('/');
                                var fileName = path[path.Length - 1];
                                var fileNameOnly = Path.GetFileNameWithoutExtension(fileName); //fileName.Split([".jpg",".png"])[0];
                                var nameSplit = fileNameOnly.Split('_');

                                //first date, second fieldnr, third varietyname, fourth traitName (if length is 4) else there will be no traitName
                                date = nameSplit.Length >= 1 ? nameSplit[0].Replace('-', ' ') : "";
                                fieldNr = nameSplit.Length >= 2 ? nameSplit[1].Replace('-', ' ') : "";
                                varietyName = nameSplit.Length >= 3 ? nameSplit[2].Replace('-', ' ') : "";
                                traitName = nameSplit.Length >= 4 ? nameSplit[3].Replace('-', ' ') : "";

                                var title = "";
                                if (!string.IsNullOrWhiteSpace(traitName))
                                    title = fieldNr + "  " + $"{varietyName}\n" + GetPictureDate(date) + $"\n{traitName}";
                                else
                                    title = fieldNr + "  " + $"{varietyName}\n" + GetPictureDate(date);

                                pics.Add(new Photo { URL = "file://" + myfile, Title = title });
                            }

                            MyPhotoBrowser = new PhotoBrowser
                            {
                                Photos = pics.OrderBy(o => o.Title).ToList(),
                                ActionButtonPressed = async (index) =>
                                {
                                    var data = MyPhotoBrowser.Photos;
                                    var currentPhoto = data[index];

                                    var nameonly = Path.GetFileNameWithoutExtension(currentPhoto.URL);
                                    var result = PictureUrlList.Where(o => o.Contains(nameonly)).FirstOrDefault();

                                    if (result.Contains("9999fromblob"))
                                    {
                                        await Application.Current.MainPage.DisplayAlert("Error!", "Unable to delete this photo. This photo is already uploaded to server.", "OK");
                                        return;
                                    }

                                    var value = await Application.Current.MainPage.DisplayAlert("Delete photo?", "Do you really want to delete this photo?", "YES", "NO");
                                    if (value)
                                    {
                                        MyPhotoBrowser.Photos.RemoveAt(index);
                                        var filepath = currentPhoto.URL.Replace("file://", "");

                                        //Delete file
                                        if (File.Exists(filepath))
                                            File.Delete(filepath);

                                        PhotoBrowser.Close();
                                        if (MyPhotoBrowser.Photos.Any())
                                            MyPhotoBrowser.Show();
                                    }

                                },
                                EnableGrid = true,
                                //BackgroundColor = Color.White,
                                //DidDisplayPhoto = (index) =>
                                //{
                                //    Debug.WriteLine($"Selection changed: {index}");
                                //},

                                //Android_ContainerPaddingPx = 20,
                                //iOS_ZoomPhotosToFill = false 

                                //EnableGrid = true
                            };

                            MyPhotoBrowser.Show();
                        }

                    }
                    catch (Exception)
                    {
                    }

                }


            }
            catch (Exception ex)
            {
                await Application.Current.MainPage.DisplayAlert("Error", ex.Message + "\n" + ex.StackTrace, "Ok");
            }

            IsBusy = false;
        }

        private async Task<List<string>> GetOnlineImages(string trialEzid, List<string> files)
        {
            try
            {
                var containerClient = await WebserviceTasks.GetBlobClient();
                var resultSegment = containerClient.GetBlobs(prefix: $"{trialEzid}/");
                foreach (var blobPage in resultSegment)
                {
                    var ext = Path.GetExtension(blobPage.Name);
                    var blobLength = blobPage.Name.Split('/').Length;
                    var fileindevice = files.FirstOrDefault(x => x.Contains(Path.GetFileNameWithoutExtension(blobPage.Name)));
                    //check last name of blob image consists on the pics  list
                    if (!string.IsNullOrWhiteSpace(fileindevice))
                    {
                        if (!fileindevice.Contains("9999fromblob"))
                        {
                            var newname = fileindevice.Replace(ext, "") + "9999fromblob" + ext;
                            int index = files.FindIndex(x => x == fileindevice);
                            files[index] = newname;
                        }

                        continue;

                    }

                    if (blobLength == 4)
                    {
                        var blockBlobImageClient = containerClient.GetBlobClient(blobPage.Name);
                        var path = "";
                        if (Device.RuntimePlatform == Device.UWP)
                        {
                            path = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "TrialAppPictures", blobPage.Name.Split('/')[0], blobPage.Name.Split('/')[1], blobPage.Name.Split('/')[2], blobPage.Name.Split('/')[3]);
                        }
                        else
                        {
                            path = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Personal), "TrialAppPictures", blobPage.Name.Split('/')[0], blobPage.Name.Split('/')[1], blobPage.Name.Split('/')[2], blobPage.Name.Split('/')[3]);
                        }
                        var newname = blobPage.Name.Replace(ext, "") + "9999fromblob" + ext;
                        var browserpath = "";
                        if (Device.RuntimePlatform == Device.UWP)
                        {
                            browserpath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "TrialAppPictures", blobPage.Name.Split('/')[0], blobPage.Name.Split('/')[1], blobPage.Name.Split('/')[2], blobPage.Name.Split('/')[3]);

                        }
                        else
                        {
                            browserpath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Personal), "TrialAppPictures", newname.Split('/')[0], newname.Split('/')[1], newname.Split('/')[2], blobPage.Name.Split('/')[3]);

                        }

                        //var browserpath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Personal), "TrialAppPictures", newname.Split('/')[0], newname.Split('/')[1], newname.Split('/')[2], blobPage.Name.Split('/')[3]);
                        var flder = Path.GetDirectoryName(path);
                        if (!Directory.Exists(flder))
                            Directory.CreateDirectory(flder);
                        using (var fileStream = File.Create(path))
                        {
                            await blockBlobImageClient.DownloadToAsync(fileStream);
                        }
                        files.Add(browserpath);
                    }

                    if (blobLength == 3)
                    {
                        var blockBlobImageClient = containerClient.GetBlobClient(blobPage.Name);
                        var path = "";
                        if (Device.RuntimePlatform == Device.UWP)
                        {
                            path = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "TrialAppPictures", blobPage.Name.Split('/')[0], blobPage.Name.Split('/')[1], blobPage.Name.Split('/')[2]);
                        }
                        else
                        {
                            path = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Personal), "TrialAppPictures", blobPage.Name.Split('/')[0], blobPage.Name.Split('/')[1], blobPage.Name.Split('/')[2]);
                        }
                        //var path = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Personal), "TrialAppPictures", blobPage.Name.Split('/')[0], blobPage.Name.Split('/')[1], blobPage.Name.Split('/')[2]);

                        var newname = blobPage.Name.Replace(ext, "") + "9999fromblob" + ext;
                        var browserpath = "";
                        if (Device.RuntimePlatform == Device.UWP)
                        {
                            browserpath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "TrialAppPictures", newname.Split('/')[0], newname.Split('/')[1], newname.Split('/')[2]);

                        }
                        else
                        {
                            browserpath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Personal), "TrialAppPictures", newname.Split('/')[0], newname.Split('/')[1], newname.Split('/')[2]);

                        }
                        //var browserpath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Personal), "TrialAppPictures", newname.Split('/')[0], newname.Split('/')[1], newname.Split('/')[2]);
                        var flder = Path.GetDirectoryName(path);
                        if (!Directory.Exists(flder))
                            Directory.CreateDirectory(flder);
                        using (var fileStream = File.Create(path))
                        {
                            await blockBlobImageClient.DownloadToAsync(fileStream);
                        }
                        files.Add(browserpath);
                    }
                }
            }
            catch (Exception ex)
            {
                await Application.Current.MainPage.DisplayAlert("Error", ex.Message, "OK");
            }
            return files;
        }


        private string GetPictureDate(string name)
        {
            string format = "yyyyMMddHHmmssfff";
            try
            {
                var data = DateTime.ParseExact(name, format, CultureInfo.InvariantCulture);
                return data.ToString();
            }
            catch
            {
                return "";
            }
            //return File.GetCreationTime(path).ToString();
        }
        public async Task<bool> DeleteTrialEntry(string varietyId)
        {
            if (string.IsNullOrWhiteSpace(varietyId))
                return false;

            var varietyInfo = await _trialEntryAppService.GetVarietiesInfoAsync(varietyId);
            if (!varietyInfo.NewRecord)
                return false;

            var traitList = await _observationService.LoadTraitsHavingObservation("'" + varietyId + "'");
            if (traitList.Count() > 0)
                return false;

            return true;
        }
        public async Task<bool> CheckIsNewRecordAsync(string varietyId)
        {
            var varietyInfo = await _trialEntryAppService.GetVarietiesInfoAsync(varietyId);
            return varietyInfo.NewRecord;
        }

        public async Task<bool> CheckHasObeservationDataAsync(string varietyId)
        {
            var traitList = await _observationService.LoadTraitsHavingObservation("'" + varietyId + "'");
            return traitList.Count > 0;
                
        }

        public void LoadTrialPropParams()
        {
            TrialPropertiesParams.Add(TrialEZID);
            TrialPropertiesParams.Add(CropCode);
            TrialPropertiesParams.Add(Navigation);
        }
    }

    internal class TrialProperties : ICommand
    {
        public bool CanExecute(object parameter)
        {
            return true;
        }

        public async void Execute(object parameter)
        {
            if (parameter is List<object> list)
            {
                var trialEzId = (int)list[0];
                var crop = (string)list[1];
                var navigation = (INavigation)list[2];
                await App.MainNavigation.PushAsync(new TrialPropertiesPage(trialEzId, crop));
            }
        }

        public event EventHandler CanExecuteChanged;
    }
}
