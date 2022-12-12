using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;
using System.Windows.Input;
using TrialApp.Common;
using TrialApp.Common.Extensions;
using TrialApp.Entities.Transaction;
using TrialApp.Services;
using TrialApp.ViewModels.Interfaces;
using Xamarin.Forms;

namespace TrialApp.ViewModels
{
    public class TransferPageViewModel : BaseViewModel
    {
        #region private variables

        private readonly IDependencyService _dependency;
        private readonly TrialService _service;
        private readonly SaveFilterService _saveFilterService;
        public readonly SettingParametersService _settingParametersService;
        private readonly SimpleGraphService _simpleGraphService;
        private List<TrialData> _trialList;
        private string _btnSelectTxt;
        private string _btnDownloadTxt;
        private bool _btnDownloadVisible;
        private bool _searchVisible;
        private string _searchText;
        private bool _enableControls;

        #endregion
        
        #region public variables

        public string SearchText
        {
            get { return _searchText; }
            set
            {
                _searchText = value;
                OnPropertyChanged();
            }
        }

        public bool IsAllSelected { get; set; }

        public bool EnableControls
        {
            get { return _enableControls; }
            set
            {
                _enableControls = value;
                OnPropertyChanged();
            }
        }

        public ICommand SelectAllCommand { get; set; }
        public ICommand DownloadCommand { get; set; }
        public string BtnSelectTxt
        {
            get { return _btnSelectTxt; }
            set
            {
                _btnSelectTxt = value;
                OnPropertyChanged();
            }
        }
        public string BtnDownloadTxt
        {
            get { return _btnDownloadTxt; }
            set
            {
                _btnDownloadTxt = value;
                OnPropertyChanged();
            }
        }
        public bool BtnDownloadVisible
        {
            get
            {
                return _btnDownloadVisible;
            }
            set
            {
                _btnDownloadVisible = value;
                OnPropertyChanged();
            }

        }
        public List<TrialData> TrialList
        {
            get { return _trialList != null ? _trialList.OrderByDescending(y => y.Year).ThenByDescending(e => e.EZID).ToList() : _trialList; }
            set
            {
                _trialList = value;
                foreach (var item in value)
                {
                    item.PropertyChanged -= OnItemPropertyChanged;
                    item.PropertyChanged += OnItemPropertyChanged;
                }
                OnPropertyChanged();
            }
        }
        public List<TrialData> TotalDownloadedTrialList { get; set; }
        public List<TrialData> FilteredDownloadedTrialList { get; set; }

        private void OnItemPropertyChanged(object sender, PropertyChangedEventArgs e)
        {
            var count = TrialList.Count(t => t.IsSelected);
            if (count > 0)
            {
                BtnDownloadTxt = TrialList.Count == count ? "DOWNLOAD ALL TRIALS" : "DOWNLOAD " + count + (count == 1 ? " TRIAL" : " TRIALS");
                BtnDownloadVisible = true;
            }
            else
                BtnDownloadVisible = false;
        }
        public bool SearchVisible
        {
            get { return _searchVisible; }
            set
            {
                _searchVisible = value;
                OnPropertyChanged();
            }
        }

        public List<int> TrialsFromNotification { get; set; }

        public ICommand GoToFilterScreen { get; set; }

        #endregion

        public TransferPageViewModel()
        {
            _service = new TrialService();
            _saveFilterService = new SaveFilterService();
            _settingParametersService = new SettingParametersService();
            _simpleGraphService = new SimpleGraphService();
            SelectAllCommand = new SelectAllCommand(this);
            DownloadCommand = new DownloadCommand(this);
            GoToFilterScreen = new GoToFilterScreenCommand();
            TrialsFromNotification = new List<int>();
            EnableControls = false;
            SearchVisible = false;
            BtnSelectTxt = "downloading...";
            FilterIcon = ImageSource.FromFile("Assets/filter.png");
            Device.BeginInvokeOnMainThread(async () =>
            {
                await DownloadTrialList();
            });
        }

        public TransferPageViewModel(IDependencyService dependency)
        {
            _dependency = dependency;
        }

        public async Task DownloadTrialList()
        {
            TrialsFromNotification = _settingParametersService.GetEZIDsFromNotification();
            IsBusy = true;
            var masterDataModule = new MasterDataModule();
            if (App.IsAADLogin)
            {
                if (await masterDataModule.getMetaInfoV2())
                    await masterDataModule.InitializeInputV2();
            }
            else
            {
                if (await masterDataModule.getMetaInfo())
                    await masterDataModule.InitializeInput();
            }

            await LoadTrialList();
            IsBusy = false;
            EnableControls = true;
        }


        public async Task DownloadPicturesAsync(List<int> ezids)
        {
            try
            {
                await Task.Delay(10);
                var containerClient = await WebserviceTasks.GetBlobClient();
                foreach (var ezid in ezids)
                {
                    var resultSegment = containerClient.GetBlobs(prefix: $"{ezid}/");
                    foreach (var blobPage in resultSegment)
                    {
                        if (blobPage.Name.Split('/').Length == 4)
                        {
                            var blockBlobImageClient = containerClient.GetBlobClient(blobPage.Name);
                            var path = "";
                            //check for different platform
                            if (Device.RuntimePlatform == Device.UWP)
                            {
                                path = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "TrialAppPictures", blobPage.Name.Split('/')[0], blobPage.Name.Split('/')[1], blobPage.Name.Split('/')[2], blobPage.Name.Split('/')[3]);
                            }
                            else
                            {
                                path = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Personal), "TrialAppPictures", blobPage.Name.Split('/')[0], blobPage.Name.Split('/')[1], blobPage.Name.Split('/')[2], blobPage.Name.Split('/')[3]);
                            }

                            var flder = Path.GetDirectoryName(path);
                            if (!Directory.Exists(flder))
                                Directory.CreateDirectory(flder);
                            using (var fileStream = System.IO.File.Create(path))
                            {
                                await blockBlobImageClient.DownloadToAsync(fileStream);
                            }
                        }
                        else if (blobPage.Name.Split('/').Length == 3)
                        {
                            var blockBlobImageClient = containerClient.GetBlobClient(blobPage.Name);
                            var path = "";
                            //check for different platform
                            if (Device.RuntimePlatform == Device.UWP)
                            {
                                path = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "TrialAppPictures", blobPage.Name.Split('/')[0], blobPage.Name.Split('/')[1], blobPage.Name.Split('/')[2]);
                            }
                            else
                            {
                                path = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Personal), "TrialAppPictures", blobPage.Name.Split('/')[0], blobPage.Name.Split('/')[1], blobPage.Name.Split('/')[2]);
                            }

                            var flder = Path.GetDirectoryName(path);
                            if (!Directory.Exists(flder))
                                Directory.CreateDirectory(flder);
                            using (var fileStream = System.IO.File.Create(path))
                            {
                                await blockBlobImageClient.DownloadToAsync(fileStream);
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                await Application.Current.MainPage.DisplayAlert("Error", ex.Message, "OK");
            }
        }


        public async Task LoadTrialList()
        {
            var trialList = new List<TrialData>();
            //var token = "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImtnMkxZczJUMENUaklmajRydDZKSXluZW4zOCIsImtpZCI6ImtnMkxZczJUMENUaklmajRydDZKSXluZW4zOCJ9.eyJhdWQiOiJlNTI3NDcxNi1mYTgwLTRiMDEtOTU2OC0wYjZmYzZhOWRhYWIiLCJpc3MiOiJodHRwczovL3N0cy53aW5kb3dzLm5ldC9lMGIxMDI3MC0yNDBiLTRlZGEtYWZmYi01MGZiMmI1OTIwZGUvIiwiaWF0IjoxNjAyNTAwMjIzLCJuYmYiOjE2MDI1MDAyMjMsImV4cCI6MTYwMjUwNDEyMywiYWlvIjoiQVNRQTIvOFJBQUFBMCtTSWc0U3JycG4yU3B1QXUvZ2JGMEFYUkFYTTZQZSt0MDByc0NYREJPRT0iLCJhbXIiOlsicHdkIl0sImZhbWlseV9uYW1lIjoiQmFudHdhIiwiZ2l2ZW5fbmFtZSI6IlByYWthc2giLCJpcGFkZHIiOiI3Ny42MS4yNDAuMTk0IiwibmFtZSI6IlByYWthc2ggQmFudHdhIiwibm9uY2UiOiI2MWVlOWFiNC01MDYyLTRkNjYtOTBmMC04Y2JmM2RlMTQ5NWEiLCJvaWQiOiI1NTQ0NzE1ZC0xOWViLTQzZjctYTQxZS04ZDMxNTQwZDhlNTciLCJvbnByZW1fc2lkIjoiUy0xLTUtMjEtMjk1NTQ2MjI1NC0zODQ3MzQwNTI2LTMwMDkzNDE5NTEtMjc4MyIsInJoIjoiMC5BUXNBY0FLeDRBc2syazZ2LTFEN0sxa2czaFpISi1XQS1nRkxsV2dMYjhhcDJxc0xBRzQuIiwicm9sZXMiOlsibWFuYWdlbWFzdGVyZGF0YXRyaWFscHJlcCIsInNhdmVvYnNlcnZhdGlvbnMiLCJBR19ST0xFX0Nyb3BUTyIsIkFHX1JPTEVfQ3JvcEVEIiwiZGlzcGxheXRyYWl0cyIsImFzc2lnbmxvdG51bWJlciIsIm1hbmFnZWdsb2JhbHRyYWl0cyIsImV4Y2x1ZGV2YXJpZXRpZXMiLCJkZWZpbmV0cmlhbCIsImFzc2lnbnVzZXJzIiwiQUdfUk9MRV9Dcm9wQlIiLCJBR19ST0xFX0Nyb3BCQSIsIkFHX1JPTEVfQ3JvcENGIiwiQUdfUk9MRV9Dcm9wRVAiLCJBR19ST0xFX0Nyb3BDSSIsIkFHX1JPTEVfQ3JvcEZOIiwiQUdfUk9MRV9Dcm9wQ0MiLCJBR19ST0xFX0Nyb3BMSyIsIkFHX1JPTEVfQ3JvcEtSIiwiQUdfUk9MRV9Dcm9wREwiLCJBR19ST0xFX0Nyb3BDUyIsIkFHX1JPTEVfQ3JvcE1FIiwiQUdfUk9MRV9Dcm9wUkMiLCJBR19ST0xFX0Nyb3BQQSIsIkFHX1JPTEVfQ3JvcFBQIiwiQUdfUk9MRV9Dcm9wTFQiLCJBR19ST0xFX0Nyb3BSQSIsIkFHX1JPTEVfQ3JvcE9OIiwiQUdfUk9MRV9Dcm9wTVciLCJBR19ST0xFX0Nyb3BSRCIsIkFHX1JPTEVfQ3JvcFNQIiwiQUdfUk9MRV9Dcm9wU1EiLCJBR19ST0xFX0Nyb3BURyIsIkFHX1JPTEVfQ3JvcFNOIl0sInN1YiI6Imo2VEFINlZXaVhoN1BiYzlzTnBZWnFxTXU0RFFDdGxsV05sZE1ncTRkNGsiLCJ0aWQiOiJlMGIxMDI3MC0yNDBiLTRlZGEtYWZmYi01MGZiMmI1OTIwZGUiLCJ1bmlxdWVfbmFtZSI6IlAuQmFudHdhQGVuemF6YWRlbi5ubCIsInVwbiI6IlAuQmFudHdhQGVuemF6YWRlbi5ubCIsInV0aSI6InpBLXM5NDd5dlV1WGxVQTdFb3dkQUEiLCJ2ZXIiOiIxLjAifQ.slhGjs2AFGXB5-tQ0sTadl39M5I2xrZWfuQBTGzrzhbwHawyQYtvVzDytGf-f2Kt5MTARxwD_oqfusPwXX068MxCOFe91Tcq2BMEOxSvWexpyU6s3u_1EkGalW9o5W3aB4st8wEAwZj5RGin6na4UQOuLynvTQLhAHapLA9MSGpkoHe9TF44lpOtgPbZTR7WskxT2InyMyt3IMCv2uY-uMbQAbg8T9uLSvRyqDBkAlzNGedbCWBP0y_H_PxpewYx5jonW8xAGp8GTXddUy_RN5KrhODMzIRtb2bo_Ry5FCaI_kmvdLEK0isHf-0ZZylrjHPQwgz2eA3p78Zj7emotg";
            var token = App.IsAADLogin ? "Bearer " + WebserviceTasks.AdToken : WebserviceTasks.Token;
            var trialDtoList = new List<Entities.ServiceResponse.TrialDto1>();
            try
            {
                var roles = _simpleGraphService.GetAllRolesAsync(WebserviceTasks.AdToken);

                //check for external user here 
                if (roles.Any(x => x.ToLower() == "externaluser"))
                    trialDtoList = await _service.GetExternalUserTrialsWrapperService(token, string.Join(",", TrialsFromNotification.Select(n => n.ToString()).ToArray()));
                else
                    trialDtoList = await _service.GetTrialsWrapperService(token);
            }
            catch (Exception ex)
            {
                await Application.Current.MainPage.DisplayAlert("Error", ex.Message, "OK");
            }
            DateTime dt;
            foreach (var val in trialDtoList)
            {
                DateTime.TryParseExact(val.Year, "yyyy", CultureInfo.InvariantCulture, DateTimeStyles.None, out dt);
                var vvar = new TrialData
                {
                    IsSelected = false,
                    EZID = Convert.ToInt32(val.EZID),
                    CountryCode = val.CountryCode?.ToUpper(),
                    CropCode = val.CropCode,
                    TrialTypeID = Convert.ToInt32(val.TrialTypeID),
                    TrialRegionID = val.TrialRegionID,
                    CropSegmentCode = val.CropSegmentCode?.ToUpper(),
                    DefaultTraitSetID = val.DefaultTraitSetID,
                    TrialName = val.Name + " " + val.UserTrialCode,
                    TrialDetails = string.Concat(val.CropCode, "-", val.CountryName),
                    Longitude = val.Longitude,
                    Latitude = val.Latitude,
                    UserTrialCode = val.UserTrialCode,
                    Year = dt
                };
                trialList.Add(vvar);
            }


            TotalDownloadedTrialList = trialList;//.OrderByDescending(o => o.EZID).ThenByDescending(o => o.Year).ToList();
            await ReloadList();
        }

        public void SearchTextChanged(object sender, TextChangedEventArgs e)
        {
            var entry = sender as Entry;
            FilterData(entry.Text.ToText());
        }
        /// <summary>
        /// filter list according to search parameter provided on method. Ignores case of filter parameter.
        /// </summary>
        /// <param name="searchParam">search parameter to filter ignoring case</param>
        public void FilterData(string searchParam)
        {
            //here
            if (FilteredDownloadedTrialList == null || !FilteredDownloadedTrialList.Any())
                return;
            var filteredData =
                FilteredDownloadedTrialList.Where(x => x.TrialName.ToLower().Contains(searchParam?.ToLower())).ToList();
            BtnSelectTxt = filteredData.Count > 0
                ? string.Concat("Select all (", filteredData.Count.ToString(), ")")
                : "No records";
            TrialList = filteredData;
            foreach (var _data in FilteredDownloadedTrialList.Except(filteredData).Where(x => x.IsSelected))
            {
                _data.IsSelected = false;
            }

        }

        public async Task ReloadList()
        {
            if (TotalDownloadedTrialList == null) return;

            //if from notification
            if (TrialsFromNotification != null && TrialsFromNotification.Count() > 0)
                FilteredDownloadedTrialList = TotalDownloadedTrialList.Where(r => TrialsFromNotification.Contains(r.EZID)).ToList();
            else
            {
                var saveFilterList = new List<SaveFilter>();
                var result = _settingParametersService.GetParamsList().Single();
                if (result.Filter)
                    saveFilterList = await _saveFilterService.GetSaveFilterAsync();

                FilterIcon = result.Filter && saveFilterList.Any(x => x.FieldValue != "") ? ImageSource.FromFile("Assets/activefilter.png") : ImageSource.FromFile("Assets/filter.png");

                var filteredData = Enumerable.Empty<string>();
                var filteredTrials = TotalDownloadedTrialList;
                foreach (var val in saveFilterList)
                {
                    filteredData = val.FieldValue.Split('|').Select(x => x.Trim());
                    switch (val.Field.ToLower())
                    {
                        case "trialtypeid":
                            if (!string.IsNullOrWhiteSpace(val.FieldValue))
                                filteredTrials = filteredTrials.Where(x => filteredData.Contains(x.TrialTypeID.ToString())).ToList();
                            break;
                        case "cropcode":
                            if (!string.IsNullOrWhiteSpace(val.FieldValue))
                                filteredTrials = filteredTrials.Where(x => filteredData.Contains(x.CropCode)).ToList();
                            break;
                        case "cropsegmentcode":
                            if (!string.IsNullOrWhiteSpace(val.FieldValue))
                                filteredTrials = filteredTrials.Where(x => filteredData.Contains(x.CropSegmentCode)).ToList();
                            break;
                        case "trialregionid":
                            if (!string.IsNullOrWhiteSpace(val.FieldValue))
                                filteredTrials = filteredTrials.Where(x => filteredData.Contains(x.TrialRegionID.ToString())).ToList();
                            break;
                        case "countrycode":
                            if (!string.IsNullOrWhiteSpace(val.FieldValue))
                                filteredTrials = filteredTrials.Where(x => filteredData.Contains(x.CountryCode)).ToList();
                            break;
                    }
                }
                FilteredDownloadedTrialList = filteredTrials;
            }

            TrialList = FilteredDownloadedTrialList;
            BtnDownloadVisible = TrialList.Any(x => x.IsSelected == true) ? true : false;
            BtnSelectTxt = TrialList.Count > 0 ? string.Concat("Select all (", TrialList.Count.ToString(), ")") : "No records";
            SearchText = "";
            _settingParametersService.DeleteNotificationLog(String.Join(",", TrialsFromNotification.ToArray()));
            WebserviceTasks.GoDownload = false;
        }
    }

    public class TrialData : INotifyPropertyChanged, ICloneable<TrialData>
    {
        private bool _isSelected;
        public int EZID { get; set; }
        public string CropCode { get; set; }
        public string TrialName { get; set; }
        public int TrialTypeID { get; set; }
        public string CountryCode { get; set; }
        public int TrialRegionID { get; set; }
        public string CropSegmentCode { get; set; }
        public int DefaultTraitSetID { get; set; }
        public string Latitude { get; set; }
        public string UserTrialCode { get; set; }
        public DateTime? Year { get; set; }

        public string Longitude { get; set; }
        public bool IsSelected
        {
            get { return _isSelected; }
            set
            {
                _isSelected = value;
                NotifyPropertyChanged();
            }
        }

        public string TrialDetails { get; set; }

        public event PropertyChangedEventHandler PropertyChanged;

        private void NotifyPropertyChanged([CallerMemberName] string name = "")
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
        }

        public TrialData Clone()
        {
            return new TrialData
            {
                EZID = EZID,
                TrialRegionID = TrialRegionID,
                CountryCode = CountryCode,
                CropCode = CropCode,
                TrialTypeID = TrialTypeID,
                CropSegmentCode = CropSegmentCode,
                DefaultTraitSetID = DefaultTraitSetID,
                IsSelected = IsSelected,
                TrialName = TrialName,
                TrialDetails = TrialDetails,
                Latitude = Latitude,
                Longitude = Longitude
            };
        }
    }

    internal class SelectAllCommand : ICommand
    {
        private readonly TransferPageViewModel _transferPageViewModel;
        public event EventHandler CanExecuteChanged;

        public SelectAllCommand(TransferPageViewModel vm)
        {
            _transferPageViewModel = vm;
        }
        public bool CanExecute(object parameter)
        {
            var obj = _transferPageViewModel;
            if (obj != null)
            {
                if (obj.EnableControls)
                    return true;
            }
            return false;
        }

        public void Execute(object parameter)
        {
            var obj = _transferPageViewModel;
            obj.IsAllSelected = !obj.IsAllSelected;

            if (obj.TrialList == null) return;
            foreach (var item in obj.TrialList)
            {
                item.IsSelected = obj.IsAllSelected;
            }
            obj.BtnSelectTxt = obj.TrialList.Count > 0 ? string.Concat(obj.IsAllSelected ? "Unselect all (" : "Select all (", obj.TrialList.Count.ToString(), ")") : "No records";
        }
    }

    internal class DownloadCommand : ICommand
    {
        private TransferPageViewModel _transferPageViewModel;
        public event EventHandler CanExecuteChanged;
        private TrialService _trialService = new TrialService();
        private MSAuthService _authService = new MSAuthService(App.AADAppID, App.ClientID, App.RedirectURI);
        public DownloadCommand(TransferPageViewModel vm)
        {
            _transferPageViewModel = vm;
        }
        public bool CanExecute(object parameter)
        {
            return true;
        }

        public async void Execute(object parameter)
        {
            //check if the token is expired
            if (!App.IsAADLogin && !WebserviceTasks.CheckTokenValidDate())
                await App.MainNavigation.PushAsync(new Views.SignInPage());
            else
            {
                try
                {

                    if (App.IsAADLogin)
                        await _authService.SignInAsync();
                    _transferPageViewModel.BtnSelectTxt = "downloading...";
                    _transferPageViewModel.IsBusy = true;
                    _transferPageViewModel.EnableControls = false;
                    _transferPageViewModel.SearchVisible = false;
                    var selectedTrialList = _transferPageViewModel.TrialList.Where(t => t.IsSelected);
                    var trialDatas = selectedTrialList as IList<TrialData> ?? selectedTrialList.ToList();
                    if (trialDatas.Any())
                    {
                        var reqList = trialDatas.Select(t => new Entities.Transaction.TrialLookUp
                        {
                            EZID = t.EZID,
                            CropCode = t.CropCode,
                            TrialName = t.TrialName,
                            TrialTypeID = t.TrialTypeID,
                            CountryCode = t.CountryCode,
                            TrialRegionID = t.TrialRegionID,
                            CropSegmentCode = t.CropSegmentCode,
                            DefaultTraitSetID = t.DefaultTraitSetID,
                            StatusCode = 10,
                            Latitude = t.Latitude,
                            Longitude = t.Longitude
                        });
                        var ezIdSuccess = await _trialService.DownloadTrialEntriesData(reqList, false, App.IsAADLogin ? "Bearer " + WebserviceTasks.AdToken : WebserviceTasks.Token);
                        _transferPageViewModel.TotalDownloadedTrialList = _transferPageViewModel.TotalDownloadedTrialList.Where(x => !ezIdSuccess.Contains(x.EZID)).ToList();
                        _transferPageViewModel.FilteredDownloadedTrialList = _transferPageViewModel.FilteredDownloadedTrialList.Where(x => !ezIdSuccess.Contains(x.EZID)).ToList();
                        _transferPageViewModel.TrialList = _transferPageViewModel.TrialList.Where(x => !ezIdSuccess.Contains(x.EZID)).ToList();

                        //Ask question only when at least a trial is successfully downloaded
                        if (ezIdSuccess.Any())
                        {
                            var result = false;
                            if (Device.RuntimePlatform == Device.UWP)
                                result = !(await Application.Current.MainPage.DisplayAlert("Download Pictures", "Do you want to download the pictures so you can see them offline?", "No", "Yes"));
                            else
                                result = await Application.Current.MainPage.DisplayAlert("Download Pictures", "Do you want to download the pictures so you can see them offline?", "Yes", "No");
                            if (result)
                            {
                                await _transferPageViewModel.DownloadPicturesAsync(ezIdSuccess);
                            }
                        }

                        if (trialDatas.Count == ezIdSuccess.Count)
                        {
                            _transferPageViewModel.BtnDownloadVisible = false;
                        }
                        else
                        {
                            var count = _transferPageViewModel.TrialList.Count(t => t.IsSelected);
                            if (count > 0)
                            {
                                _transferPageViewModel.BtnDownloadTxt = "DOWNLOAD " + count + (count == 1 ? " TRIAL" : " TRIALS");
                                _transferPageViewModel.BtnDownloadVisible = true;
                            }
                            else
                            {
                                _transferPageViewModel.BtnDownloadVisible = false;
                            }
                            MessagingCenter.Send(_transferPageViewModel, "Error");
                        }
                    }
                    _transferPageViewModel.BtnSelectTxt = _transferPageViewModel.TrialList.Count > 0 ? string.Concat("Select all (", _transferPageViewModel.TrialList.Count.ToString(), ")") : "No records";
                    _transferPageViewModel.IsBusy = false;
                    _transferPageViewModel.EnableControls = true;
                }
                catch (Exception)
                {

                    
                }
            }
        }
    }
}
