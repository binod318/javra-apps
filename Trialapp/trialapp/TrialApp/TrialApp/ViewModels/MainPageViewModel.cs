using Microsoft.Identity.Client;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Windows.Input;
using TrialApp.Common.Extensions;
using TrialApp.Entities.Transaction;
using TrialApp.Services;
using TrialApp.ViewModels.Interfaces;
using TrialApp.Views;
using Xamarin.Essentials;
using Xamarin.Forms;

namespace TrialApp.ViewModels
{
    public class Trial : ObservableViewModel
    {
        private int _ezid;
        
        public int EZID
        {
            get { return _ezid; }
            set { _ezid = value; OnPropertyChanged(); }
        }
        private string _cropCode;

        public string CropCode
        {
            get { return _cropCode; }
            set { _cropCode = value; OnPropertyChanged(); }
        }
        private string _trialName;
        public string TrialName
        {
            get { return _trialName; }
            set { _trialName = value; OnPropertyChanged(); }
        }
        private int _trialTypeID;

        public int TrialTypeID
        {
            get { return _trialTypeID; }
            set { _trialTypeID = value; OnPropertyChanged(); }
        }

        public string _trialTypeName { get; set; }
        public string TrialTypeName
        {
            get { return _trialTypeName; }
            set { _trialTypeName = value; OnPropertyChanged(); }
        }
        
        private string _countryCode;

        public string CountryCode
        {
            get { return _countryCode; }
            set { _countryCode = value; OnPropertyChanged(); }
        }
        private string _statusName;

        public string StatusName
        {
            get { return _statusName; }
            set { _statusName = value; OnPropertyChanged(); }
        }
        private bool _selected;

        public bool Selected
        {
            get { return _selected; }
            set
            {
                _selected = value;
                OnPropertyChanged();
            }
        }
        private string _styleID;

        public string StyleID
        {
            get { return _styleID; }
            set { _styleID = value; }
        }

        private string _onlineStatus;

        public string OnlineStatus
        {
            get { return _onlineStatus; }
            set
            {
                _onlineStatus = value;
                OnPropertyChanged();
            }
        }
        private bool _isloginButton;

        public bool IsloginButton
        {
            get { return _isloginButton; }
            set
            {
                _isloginButton = value;
                OnPropertyChanged();
            }
        }
        private bool _isTrial;

        public bool IsTrial
        {
            get { return _isTrial; }
            set
            {
                _isTrial = value;
                OnPropertyChanged();
            }
        }
        private double _fontSizeStatus;

        public double FontSizeStatus
        {
            get { return _fontSizeStatus; }
            set
            {
                _fontSizeStatus = value;
                OnPropertyChanged();
            }
        }

        private double _fontSizeCountry;

        public double FontSizeCountry
        {
            get { return _fontSizeCountry; }
            set
            {
                _fontSizeCountry = value;
                OnPropertyChanged();
            }
        }
        private double _fontsizeTrialName;

        public double FontsizeTrialName
        {
            get { return _fontsizeTrialName; }
            set
            {
                _fontsizeTrialName = value;
                OnPropertyChanged();
            }
        }
        private double _fontsizeTrialNameList;

        public double FontsizeTrialNameList
        {
            get { return _fontsizeTrialNameList; }
            set
            {
                _fontsizeTrialNameList = value;
                OnPropertyChanged();
            }
        }
        private double _fontsizeStatusList;

        public double FontsizeStatusList
        {
            get { return _fontsizeStatusList; }
            set
            {
                _fontsizeStatusList = value;
                OnPropertyChanged();
            }
        }
        private double _fontsizeTrialTypeList;

        public double FontsizeTrialTypeList
        {
            get { return _fontsizeTrialTypeList; }
            set
            {
                _fontsizeTrialTypeList = value;
                OnPropertyChanged();
            }
        }
        private Color _trialColor;

        public Color TrialColor
        {
            get { return _trialColor; }
            set
            {
                _trialColor = value;
                OnPropertyChanged();
            }
        }
        public string CropSegmentCode { get; set; }
        public int TrialRegionID { get; set; }

        private string _displayPropertyValue;
        public string DisplayPropertyValue
        {
            get { return _displayPropertyValue; }
            set { _displayPropertyValue = value; OnPropertyChanged(); }
        }
        public bool PropertyVisible { get; set; }
        public double DisplayPropertyHeight { get; set; }
        public string CropCountry { get; set; }
        
    }

    public class MainPageViewModel : BaseViewModel
    {
        #region Private variables
        private bool _enableControls;
        private bool _submitVisible = false;
        private string _submitText;
        private List<TrialLookUp> _selectedTileList = new List<TrialLookUp>();
        private bool _displayConfirmation;
        //private readonly bool _restoreConfirmation;
        //private readonly bool _backupConfirmation;
        private readonly IDependencyService _dependencyService;
        private string _searchText;
        private bool _searchVisible;
        private readonly string title = "Remove submitted trials?";
        private readonly string _message = "Once removed, submitted trials will no longer be available on this device." +
                                            Environment.NewLine + Environment.NewLine + "You can always download trials again.";
        public string dbAlertTitle;
        public string dbAlertMgs;
        private ObservableCollection<Trial> _listSource;
        private ObservationAppService _observationAppService;
        private ImageSource _loginDownloadIcon;
        private string _loginDownloadText;
        private bool _propertyVisible;
        private readonly SettingParametersService _setPar;
        private string _latestSynctime; 
        private void DisplayDBAlert()
        {
            string[] values = { dbAlertTitle, dbAlertMgs };
            Xamarin.Forms.MessagingCenter.Send(this, "DisplayDBAlert", values);
        }
        #endregion

        #region public variables
        public readonly SettingParametersService _settingParametersService;
        public readonly SaveFilterService SaveFilterService;
        public TrialService trialService;
        public TraitService traitService;
        public CropRdService cropService;
        private readonly MSAuthService _authService;
        private readonly SimpleGraphService _simpleGraphService;
        public CountryService countryService;
        public ObservableCollection<Trial> ListSource
        {
            get { return _listSource; }
            set
            {
                _listSource = value;
                OnPropertyChanged();
            }
        }
        public string SearchText
        {
            get { return _searchText; }
            set
            {
                _searchText = value;
                OnPropertyChanged();
            }
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
        public bool SubmitVisible
        {
            get { return _submitVisible; }
            set
            {
                _submitVisible = value;
                OnPropertyChanged();
            }
        }
        public string SubmitText
        {
            get { return _submitText; }
            set
            {
                _submitText = value;
                OnPropertyChanged();
            }
        }
        public bool EnableControls
        {
            get { return _enableControls; }
            set
            {
                _enableControls = value;
                OnPropertyChanged();
            }
        }
        public ICommand SubmitCommand { get; set; }

        public ICommand GoToFilterScreen { get; set; }
        public ICommand GoToSettingScreen { get; set; }
        public ICommand GoToLoginCommand { get; set; }

        public List<TrialLookUp> SelectedTileList
        {
            get { return _selectedTileList; }
            set
            {
                _selectedTileList = value;
                OnPropertyChanged();
            }
        }
        public List<Trial> AllTrials { get; set; }
        public List<SaveFilter> SaveFilterList;
        internal SettingParameters Settings;

        public ImageSource LoginDownloadIcon
        {
            get { return _loginDownloadIcon; }
            set
            {
                _loginDownloadIcon = value;
                OnPropertyChanged();
            }
        }
        public string LoginDownloadText
        {
            get { return _loginDownloadText; }
            set
            {
                _loginDownloadText = value;
                OnPropertyChanged();
            }
        }

        public bool PropertyVisible
        {
            get { return _propertyVisible; }
            set { _propertyVisible = value; OnPropertyChanged(); }
        }
        public bool DisplayConfirmation
        {
            get { return _displayConfirmation; }
            set
            {
                _displayConfirmation = value;
                if (value)
                    DisplayAlert();
                OnPropertyChanged();
            }
        }
        //public bool RestoreConfirmation
        //{
        //    get { return _restoreConfirmation; }
        //    set
        //    {
        //        _displayConfirmation = value;
        //        if (value)
        //            DisplayDBAlert();
        //        OnPropertyChanged();
        //    }
        //}
        //public bool BackupConfirmation
        //{
        //    get { return _backupConfirmation; }
        //    set
        //    {
        //        _displayConfirmation = value;
        //        if (value)
        //            DisplayDBAlert();
        //        OnPropertyChanged();
        //    }
        //}
        public bool ReloadTrialProp { get; set; }
        public string DisplayPropertyId { get; set; }
        public bool IsAADLogin { get; set; }
        public string LatestSynctime
        {
            get { return _latestSynctime; }
            set { _latestSynctime = value; OnPropertyChanged(); }
        }

        #endregion

        public MainPageViewModel()
        {
            _observationAppService = new ObservationAppService();
            trialService = new TrialService();
            traitService = new TraitService();
            SaveFilterService = new SaveFilterService();
            _settingParametersService = new SettingParametersService();
            SubmitCommand = new SubmitOperation(this);
            GoToFilterScreen = new GoToFilterScreenCommand();
            GoToSettingScreen = new GoToSettingScreenCommand();
            ListSource = new ObservableCollection<Trial>();
            AllTrials = new List<Trial>();
            EnableControls = true;
            SaveFilterList = new List<SaveFilter>();
            FilterIcon = ImageSource.FromFile("Assets/filter.png");
            GoToLoginCommand = new GoToLoginCommand();
            cropService = new CropRdService();
            countryService = new CountryService();
            _authService = new MSAuthService( App.AADAppID, App.ClientID, App.RedirectURI);
            _simpleGraphService = new SimpleGraphService();
            _setPar = new SettingParametersService();
            Device.BeginInvokeOnMainThread(async () =>
            {
                await Process_Navigation();
            });
        }

        public async Task Process_Navigation()
        {
            if (_settingParametersService.CheckNotification())
            {
                // If already in Transfer page do not navigate instead set GoDownload and navigate when goes back to Main screen
                if (App.MainNavigation.CurrentPage.ToString() != "TrialApp.Views.TransferPage")
                {
                    var navigationPages = Navigation.NavigationStack.ToList();
                    foreach (var page in navigationPages)
                    {
                        if (page.ToString() == "TrialApp.Views.TransferPage" || page.ToString() == "TrialApp.Views.SignInPage"
                            || page.ToString() == "TrialApp.Views.SettingPage" || page.ToString() == "TrialApp.Views.FilterPage")
                            Navigation.RemovePage(page);
                    }
                    if (IsAADLogin)
                    {
                        await AADLoginAsync();
                        await App.MainNavigation.PushAsync(new TransferPage());
                    }
                    else
                    {
                        if (WebserviceTasks.CheckTokenValidDate())
                            await App.MainNavigation.PushAsync(new TransferPage());
                        else
                            await App.MainNavigation.PushAsync(new SignInPage());
                    }
                }
                else
                    WebserviceTasks.GoDownload = true;
            }
        }
        public async Task AADLoginAsync()
        {
            try
            {
                IsBusy = true;
                await Task.Delay(10);
                if (await _authService.SignInAsync())
                {
                    var Name = await _simpleGraphService.GetNameAsync();
                    //WebserviceTasks.UsernameWS = Name;
                    _setPar.UpdateParams("loggedinuser", Name);
                    _setPar.UpdateParams("IsRegistered", "1");
                    UserName = Name;
                    await UpdateNotificationHub(Name);
                    DrawLoginIcon();
                }
                IsBusy = false;
            }
            catch (Exception ex)
            {
                IsBusy = false;
                string[] values = { "Acquire token interactive failed", ex.Message };
                Console.WriteLine(ex.Message);
                MessagingCenter.Send(this, "DisplayAlert1", values);
            }
        }

        public async Task UpdateNotificationHub(string name)
        {
            try
            {
                INotificationHelper notificationHelper = DependencyService.Get<INotificationHelper>();

                //update tags

                notificationHelper.UpdateToken(name);
            }
            catch (Exception ex)
            {

                await Application.Current.MainPage.DisplayAlert("Error", "Update registration failed with : " + ex.Message, "OK");
            }
            
        }

        internal async Task RemoveTrials()
        {
            await trialService.RemoveTrialFromDeviceAsync(SelectedTileList, false);

        }
        internal async Task DeletePictureAsync()
        {
            await trialService.DeleteTrialPictures(SelectedTileList);

        }
        internal async Task UploadPictureAsync()
        {
            await trialService.UploadImagesAsync(SelectedTileList);
            
        }
        internal async Task UpdateTrial()
        {
            await trialService.UpdateTrialAndObservationData(SelectedTileList, App.IsAADLogin ? "Bearer " + WebserviceTasks.AdToken : WebserviceTasks.Token);
        }

        /// <summary>
        /// load trials on screen fetching all trial data from db.
        /// </summary>
        public async Task LoadTrials()
        {
            AllTrials.Clear();
            SearchText = "";
            var oldProperty = DisplayPropertyId;

            var data = await trialService.GetAllTrialsList();

            var croplist = await cropService.GetCropListAsync(string.Join(",", data.Select(x => "'" + x.CropCode + "'").Distinct()));
            var countrylist = await countryService.GetCountryListAsync(string.Join(",", data.Select(x => "'" + x.CountryCode + "'").Distinct()));

            foreach (var orgi in data)
            {
                var crop = croplist.FirstOrDefault(p => p.CropCode.Equals(orgi.CropCode))?.CropName;
                var country = countrylist.FirstOrDefault(p => p.CountryCode.Equals(orgi.CountryCode))?.CountryName;
                orgi.CropCountry = (string.IsNullOrWhiteSpace(crop) ? orgi.CropCode : crop) + " - " + (string.IsNullOrWhiteSpace(country) ? orgi.CountryCode : country);
            }

            DisplayPropertyId = Settings.DisplayPropertyID.ToText();
            if (string.IsNullOrWhiteSpace(DisplayPropertyId) || DisplayPropertyId == "0")
            {
                PropertyVisible = false;
            }
            else
                PropertyVisible = true;

            foreach (var _item in data)
            {
                var trial = new Trial
                {
                    CountryCode = _item.CountryCode,
                    CropCode = _item.CropCode,
                    EZID = _item.EZID,
                    StatusName = MainPage.TrialStatus[_item.StatusCode.ToString()],
                    TrialName = _item.TrialName,
                    TrialTypeID = _item.TrialTypeID,
                    TrialTypeName = _item.TrialTypeName,
                    IsTrial = true,
                    IsloginButton = false,
                    FontSizeStatus = Device.GetNamedSize(NamedSize.Small, typeof(Label)) - 1,
                    FontSizeCountry = Device.GetNamedSize(NamedSize.Small, typeof(Label)) + 1,
                    FontsizeTrialName = Device.GetNamedSize(NamedSize.Small, typeof(Label)) + 1,
                    FontsizeTrialNameList = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) + 2,
                    FontsizeStatusList = Device.GetNamedSize(NamedSize.Small, typeof(Label)) + 1,
                    FontsizeTrialTypeList = Device.GetNamedSize(NamedSize.Small, typeof(Label)),
                    TrialColor = _item.StatusCode == 30 ? Color.FromHex("#61ce2b") : Color.FromHex("#4990e2"),
                    StyleID = _item.EZID + "|" + _item.TrialName + "|" + _item.CropCode,
                    Selected = false,
                    OnlineStatus = _item.StatusCode.ToString(),
                    TrialRegionID = _item.TrialRegionID,
                    CropSegmentCode = _item.CropSegmentCode,
                    PropertyVisible = PropertyVisible,
                    DisplayPropertyHeight = PropertyVisible ? 25 : 0,
                    CropCountry = _item.CropCountry
                };
                AllTrials.Add(trial);
            }

            var filteredlist = await ApplyFilterOnTiles("");
            
            //Avoid unnecessary rendering of Tiles
            var idList1 = string.Join(",", filteredlist.Select(p => p.EZID.ToString() + p.Selected.ToString() + p.StatusName));
            var idList2 = string.Join(",", ListSource.Select(p => p.EZID.ToString() + p.Selected.ToString() + p.StatusName));
            
            if (!string.Equals(idList1, idList2) || (PropertyVisible && oldProperty != DisplayPropertyId))
            {
                ListSource.Clear();
                foreach (var _item in filteredlist)
                {
                    ListSource.Add(_item);
                }
            }

            ReloadTrialProp = true;
        }
        /// <summary>
        /// delete trial data after uploading data to server if any changes made otherwise delete directly.
        /// </summary>
        /// <returns></returns>
        internal async void DeleteTrials()
        {
             await trialService.RemoveTrialFromDeviceAsync(SelectedTileList, false);
        }
        /// <summary>
        /// Reload Trials displayed on mainpage.
        /// </summary>
        /// <param name="search">load trial with name starting with search parameter</param>
        internal async Task ReloadTrial(string search)
        {
            var data = await ApplyFilterOnTiles(search); // apply filter and return filter data that will be added later

            //Avoid unnecessary rendering of Tiles
            var idList1 = string.Join(",", data.Select(p => p.EZID.ToString() + p.Selected.ToString() + p.StatusName));
            var idList2 = string.Join(",", ListSource.Select(p => p.EZID.ToString() + p.Selected.ToString() + p.StatusName));

            if (!string.Equals(idList1, idList2))
            {
                ListSource.Clear();
                foreach (var trial in data)
                {
                    ListSource.Add(trial);
                }
            }

            RefreshSubmitTrialList(); // refresh submit trial status if user filters tiles.
        }

        /// <summary>
        /// fitler function for search and fitler.
        /// </summary>
        /// <param name="search"></param>
        /// <returns></returns>
        public async Task<ObservableCollection<Trial>> ApplyFilterOnTiles(string search)
        {
            if (search != "")
            {
                //ListSource.Clear();
                var data = ListSource.Where(x => x.TrialName.ToLower().Contains(search.ToLower())).ToList();
                //if (data.Count + 1 != ListSource.Count)
                //{
                    return new ObservableCollection<Trial>(data);
                //}
            }
            else
            {
                var filteredData = Enumerable.Empty<string>();
                var filteredTrials = AllTrials;
                bool filterFound = false;
                var propfilterquery = "";
                List<ObservationAppLookup> propfilterList = null;
                if (Settings.Filter)
                {
                    foreach (var val in SaveFilterList)
                    {
                        filteredData = val.FieldValue.Split('|').Select(x => x.Trim());
                        if (int.TryParse(val.Field, out int traitId))
                        {
                            var trait = (await traitService.GetTraitsAsync(traitId.ToString())).FirstOrDefault();
                            var dOperator = string.Empty;
                            var sym = string.Empty;
                            var brace = string.Empty;
                            if ((trait.DataType.ToLower() == "c" && !trait.ListOfValues) || trait.DataType.ToLower() == "d")
                            {
                                dOperator = " LIKE ";
                                sym = "%";
                            }
                            else
                            {
                                dOperator = " IN ( ";
                                brace = " )";
                            }

                            propfilterList = new List<ObservationAppLookup>();
                            var valuelist = val.FieldValue.Replace("'", "''").Split('|').ToArray();
                            var vFinal = valuelist.Aggregate("", (current, item) => current + ("'" + sym + "" + item + "" + sym + "',")).TrimEnd(',');
                            var vListfinal = vFinal.Split(',').ToArray();
                            propfilterquery = " ( TraitID = " + val.Field + " AND ( ";
                            if (dOperator == " IN ( ")
                                propfilterquery += " FinalObsValue " + dOperator + " " + vFinal + " OR ";
                            else
                            {
                                foreach (var item in vListfinal)
                                {
                                    propfilterquery += " FinalObsValue " + dOperator + " " + item + " OR ";
                                }
                            }
                            propfilterquery = propfilterquery.TrimEnd(' ').TrimEnd('R').TrimEnd('O');
                            propfilterquery += " ) )" + brace;
                            var trialswithfilteronprop = await _observationAppService.LoadObservationUsingQuery(propfilterquery);
                            filteredTrials = filteredTrials.Where(x => trialswithfilteronprop.Any(x2 => x2.EZID == x.EZID.ToString())).ToList();

                            filterFound = true;
                        }
                        else
                        {
                            switch (val.Field.ToLower())
                            {
                                case "trialtypeid":
                                    if (!string.IsNullOrWhiteSpace(val.FieldValue))
                                    {
                                        filteredTrials = filteredTrials.Where(x => filteredData.Contains(x.TrialTypeID.ToString())).ToList();
                                        filterFound = true;
                                    }
                                    break;
                                case "cropcode":
                                    if (!string.IsNullOrWhiteSpace(val.FieldValue))
                                    {
                                        filteredTrials = filteredTrials.Where(x => filteredData.Contains(x.CropCode)).ToList();
                                        filterFound = true;
                                    }
                                    break;
                                case "cropsegmentcode":
                                    if (!string.IsNullOrWhiteSpace(val.FieldValue))
                                    {
                                        filteredTrials = filteredTrials.Where(x => filteredData.Contains(x.CropSegmentCode)).ToList();
                                        filterFound = true;
                                    }
                                    break;
                                case "trialregionid":
                                    if (!string.IsNullOrWhiteSpace(val.FieldValue))
                                    {
                                        filteredTrials = filteredTrials.Where(x => filteredData.Contains(x.TrialRegionID.ToString())).ToList();
                                        filterFound = true;
                                    }
                                    break;
                                case "countrycode":
                                    if (!string.IsNullOrWhiteSpace(val.FieldValue))
                                    {
                                        filteredTrials = filteredTrials.Where(x => filteredData.Contains(x.CountryCode)).ToList();
                                        filterFound = true;
                                    }
                                    break;
                                default:
                                    if (!string.IsNullOrWhiteSpace(val.FieldValue))
                                    {
                                        propfilterList = new List<ObservationAppLookup>();
                                        var valuelist = val.FieldValue.Replace("'", "''").Split('|').ToArray();
                                        var splittedValue = valuelist.Aggregate("", (current, item) => current + ("'" + item + "',")).TrimEnd(',');
                                        
                                        propfilterquery =
                                            " ( TraitID = " + val.Field + " AND FinalObsValue IN (" + splittedValue + ") )";

                                        var trialswithfilteronprop = await _observationAppService.LoadObservationUsingQuery(propfilterquery);
                                        filteredTrials = filteredTrials.Where(x => trialswithfilteronprop.Any(x2 => x2.EZID == x.EZID.ToString())).ToList();

                                        filterFound = true;
                                    }
                                    break;
                            }
                        }
                    }
                }

                FilterIcon = Settings.Filter && filterFound ? ImageSource.FromFile("Assets/activefilter.png") : ImageSource.FromFile("Assets/filter.png");
                //if (AllTrials.Count != filteredTrials.Count || AllTrials.Count != ListSource.Count - 1)
                //{
                    return new ObservableCollection<Trial>(filteredTrials.ToList());

                //}
                

            }
        }

        public MainPageViewModel(IDependencyService dependencyService)
        {
            _dependencyService = dependencyService;
            EnableControls = true;
        }

        public void DrawLoginIcon()
        {
            var view = Settings.DefaultLayout;
            GridviewVisible = view == "grid" ? true : false;
            LoginDownloadIcon = string.IsNullOrWhiteSpace(UserName) ? ImageSource.FromFile("Assets/login.png") : ImageSource.FromFile("Assets/download.png");
            LoginDownloadText = string.IsNullOrWhiteSpace(UserName) ? "Login" : "Download";
        }

        public async Task DisplayPropertyvalueonTile()
        {
            if (!string.IsNullOrWhiteSpace(DisplayPropertyId))
            {
                // get list of trials
                var trials = string.Join(",", ListSource.Select(o => o.EZID));
                var data = await _observationAppService.GetObservationDataAll(trials, DisplayPropertyId);

                foreach (var x in data)
                {
                    var trial = ListSource.FirstOrDefault(o => o.EZID.ToString() == x.EZID);
                    if (trial != null)
                        trial.DisplayPropertyValue = x.ObsValueChar ?? (x.ObsValueInt != null ? x.ObsValueInt.ToString() :
                                                     x.ObsValueDate != null ? x.ObsValueDate.Split('T')[0] :
                                                     ((UnitOfMeasure.SystemUoM == "Imperial") ? x.ObsValueDecImp : x.ObsValueDecMet) != null ?
                                                     ((UnitOfMeasure.SystemUoM == "Imperial") ? x.ObsValueDecImp.ToString() : x.ObsValueDecMet.ToString()) : "");
                }
            }
        }

        public void DisplayAlert()
        {
            string[] values = { title, _message };
            Xamarin.Forms.MessagingCenter.Send(this, "DisplayAlert", values);
        }
        internal void UpdateSubmit(Entities.Transaction.TrialLookUp selectedTrial, bool isAdded)
        {
            var alreadyAdded = SelectedTileList.FirstOrDefault(x => x.EZID == selectedTrial.EZID);
            if (alreadyAdded != null)
                SelectedTileList.Remove(alreadyAdded);
            else
                SelectedTileList.Add(selectedTrial);
            if (SelectedTileList.Count > 0)
            {
                SubmitVisible = true;
                SubmitText = "SUBMIT (" + SelectedTileList.Count + ")";
            }
            else
                SubmitVisible = false;
        }

        public void PersistSubmitTrialList()
        {
            if (string.IsNullOrWhiteSpace(UserName))
                SelectedTileList.Clear();

            foreach (var _trial in SelectedTileList)
            {
                var tile = ListSource.FirstOrDefault(x => x.EZID == _trial.EZID);
                tile.Selected = true;
            }
            if (SelectedTileList.Count > 0)
            {
                SubmitVisible = true;
                SubmitText = "SUBMIT (" + SelectedTileList.Count + ")";
            }
            else
                SubmitVisible = false;
        }

        private void RefreshSubmitTrialList()
        {
            SelectedTileList.Clear();
            var data = ListSource.Where(x => x.Selected).ToList();
            foreach (var _data in data)
            {
                SelectedTileList.Add(new Entities.Transaction.TrialLookUp
                {
                    EZID = _data.EZID,
                    CountryCode = _data.CountryCode,
                    CropCode = _data.CropCode,
                    TrialName = _data.TrialName,
                    TrialTypeID = _data.TrialTypeID,
                    StatusCode = _data.StatusName == "New" ? 10 : _data.StatusName == "Synced" ? 20 : 30,
                });
            }
            if (SelectedTileList.Count > 0)
            {
                SubmitVisible = true;
                SubmitText = "SUBMIT (" + SelectedTileList.Count + ")";
            }
            else
                SubmitVisible = false;
        }

        public void ClearUserForSingOut()
        {
            WebserviceTasks.PasswordWS = "";
            WebserviceTasks.Token = "";
            WebserviceTasks.UsernameWS = "";
            UserName = "";
        }

        internal async Task RefershFilter()
        {
            var trials = trialService.GetAllTrials();
            var newSavefilterlist = new List<SaveFilter>();
            bool needtoupdate = false;
            foreach (var _data in SaveFilterList)
            {
                var filteredData = new List<string>();
                var filterDataToExclude = new List<string>(); ;
                var individualFilterItems = Enumerable.Empty<string>();
                switch (_data.Field)
                {
                    case "TrialTypeId":
                        individualFilterItems = trials.Select(x => x.TrialTypeID.ToText());
                        if (!string.IsNullOrWhiteSpace(_data.FieldValue))
                            filteredData = _data.FieldValue.Split(',').Select(x => x.Trim()).ToList();
                        foreach (var _filterparam in filteredData)
                        {
                            if (!individualFilterItems.Contains(_filterparam))
                            {
                                needtoupdate = true;
                                filterDataToExclude.Add(_filterparam);
                            }
                        }
                        if (needtoupdate)
                        {
                            filteredData = filteredData.Except(filterDataToExclude).ToList();
                            newSavefilterlist.Add(new SaveFilter()
                            {
                                Field = "TrialTypeId",
                                FieldValue = string.Join(",", filteredData.Select(x => x.Trim()))

                            });
                        }
                        break;
                    case "CropCode":
                        individualFilterItems = trials.Select(x => x.CropCode);
                        if (!string.IsNullOrWhiteSpace(_data.FieldValue))
                            filteredData = _data.FieldValue.Split(',').Select(x => x.Trim()).ToList();
                        foreach (var _filterparam in filteredData)
                        {
                            if (!individualFilterItems.Contains(_filterparam))
                            {
                                needtoupdate = true;
                                filterDataToExclude.Add(_filterparam);
                            }
                        }
                        if (needtoupdate)
                        {
                            filteredData = filteredData.Except(filterDataToExclude).ToList();
                            newSavefilterlist.Add(new SaveFilter()
                            {
                                Field = "CropCode",
                                FieldValue = string.Join(",", filteredData.Select(x => x.Trim()))

                            });
                        }
                        break;
                    case "CropSegmentCode":
                        individualFilterItems = trials.Select(x => x.CropSegmentCode);
                        if (!string.IsNullOrWhiteSpace(_data.FieldValue))
                            filteredData = _data.FieldValue.Split(',').Select(x => x.Trim()).ToList();
                        foreach (var _filterparam in filteredData)
                        {
                            if (!individualFilterItems.Contains(_filterparam))
                            {
                                needtoupdate = true;
                                filterDataToExclude.Add(_filterparam);
                            }

                        }
                        if (needtoupdate)
                        {
                            filteredData = filteredData.Except(filterDataToExclude).ToList();
                            newSavefilterlist.Add(new SaveFilter()
                            {
                                Field = "CropSegmentCode",
                                FieldValue = string.Join(",", filteredData.Select(x => x.Trim()))

                            });
                        }
                        break;
                    case "TrialRegionId":
                        individualFilterItems = trials.Select(x => x.TrialRegionID.ToText());
                        if (!string.IsNullOrWhiteSpace(_data.FieldValue))
                            filteredData = _data.FieldValue.Split(',').Select(x => x.Trim()).ToList();
                        foreach (var _filterparam in filteredData)
                        {
                            if (!individualFilterItems.Contains(_filterparam))
                            {
                                needtoupdate = true;
                                filterDataToExclude.Add(_filterparam);
                            }
                        }
                        if (needtoupdate)
                        {
                            filteredData = filteredData.Except(filterDataToExclude).ToList();
                            newSavefilterlist.Add(new SaveFilter()
                            {
                                Field = "TrialRegionId",
                                FieldValue = string.Join(",", filteredData.Select(x => x.Trim()))

                            });
                        }
                        break;
                    case "CountryCode":
                        individualFilterItems = trials.Select(x => x.CountryCode.ToText());
                        if (!string.IsNullOrWhiteSpace(_data.FieldValue))
                            filteredData = _data.FieldValue.Split(',').Select(x => x.Trim()).ToList();
                        foreach (var _filterparam in filteredData)
                        {
                            if (!individualFilterItems.Contains(_filterparam))
                            {
                                needtoupdate = true;
                                filterDataToExclude.Add(_filterparam);
                            }
                        }
                        if (needtoupdate)
                        {
                            filteredData = filteredData.Except(filterDataToExclude).ToList();
                            newSavefilterlist.Add(new SaveFilter()
                            {
                                Field = "CountryCode",
                                FieldValue = string.Join(",", filteredData.Select(x => x.Trim()))

                            });
                        }
                        break;
                }
            }
            await SaveFilterService.SaveFilterAsync(newSavefilterlist);
        }
    }

    internal class SubmitOperation : ICommand
    {
        private readonly MainPageViewModel _mainPageViewModel;
        public SubmitOperation(MainPageViewModel mainPageViewModel)
        {
            this._mainPageViewModel = mainPageViewModel;
        }

        public event EventHandler CanExecuteChanged;

        public bool CanExecute(object parameter)
        {
            return true;
        }

        public async void Execute(object parameter)
        {
            var isUploadSuccess = true;
            _mainPageViewModel.EnableControls = false;
            _mainPageViewModel.IsBusy = true;
            await Task.Delay(10);
            var listOfModified = _mainPageViewModel.SelectedTileList.Where(trial => trial.StatusCode == 30).ToList();
            if (listOfModified.Any())
            {
                try
                {
                    isUploadSuccess = await _mainPageViewModel.trialService.Uploaddata(listOfModified, App.IsAADLogin ? "Bearer " + WebserviceTasks.AdToken : WebserviceTasks.Token);
                }
                catch (Exception ex)
                {
                    isUploadSuccess = false;
                    await Application.Current.MainPage.DisplayAlert("Error", ex.Message, "OK");
                }
                
            }

            if (isUploadSuccess)
            {
                if (UnitOfMeasure.RaiseWarning)
                {
                     _mainPageViewModel.RemoveTrials();
                    _mainPageViewModel.SelectedTileList.Clear();
                     await _mainPageViewModel.LoadTrials();
                    _mainPageViewModel.PersistSubmitTrialList();

                    var isTrialUpdated = _mainPageViewModel.AllTrials.Any(x => x.OnlineStatus == "30");

                    if(!isTrialUpdated)
                    {
                        // set current system setting
                        var data = _mainPageViewModel._settingParametersService.GetParamsList().Single();
                        var dbValMeasuresystem = data.UoM ?? "";
                        UnitOfMeasure.SystemUoM = dbValMeasuresystem;
                        UnitOfMeasure.RaiseWarning = false;
                    }
                }
                _mainPageViewModel.DisplayConfirmation = true;
            }

            _mainPageViewModel.IsBusy = false;
            _mainPageViewModel.EnableControls = true;
        }
    }

    internal class GoToFilterScreenCommand : ICommand
    {
        public event EventHandler CanExecuteChanged;

        public bool CanExecute(object parameter)
        {
            return true;
        }

        public async void Execute(object parameter)
        {
            if (parameter is MainPageViewModel)
            {
                if (!(parameter is MainPageViewModel vm)) return;
                var data = vm.AllTrials.Select(x => new Entities.Transaction.TrialLookUp
                {
                    EZID = x.EZID,
                    CountryCode = x.CountryCode,
                    CropCode = x.CropCode,
                    TrialName = x.TrialName,
                    CropSegmentCode = x.CropSegmentCode,
                    TrialRegionID = x.TrialRegionID,
                    TrialTypeID = x.TrialTypeID,
                }).ToList();
                await App.MainNavigation.PushAsync(new FilterPage(data));
            }
            else if (parameter is TransferPageViewModel)
            {
                if (!(parameter is TransferPageViewModel vm)) return;

                if (vm.TotalDownloadedTrialList == null) return;

                var dataList =
                    new List<Entities.Transaction.TrialLookUp>(
                        vm.TotalDownloadedTrialList.Select(x =>
                         new Entities.Transaction.TrialLookUp()
                         {
                             CropCode = x.CropCode,
                             CountryCode = x.CountryCode,
                             TrialTypeID = x.TrialTypeID,
                             TrialRegionID = x.TrialRegionID,
                             CropSegmentCode = x.CropSegmentCode,
                             EZID = x.EZID
                         })).ToList();

                await App.MainNavigation.PushAsync(new FilterPage(dataList));
            }

        }

    }

    internal class GoToSettingScreenCommand : ICommand
    {
        public event EventHandler CanExecuteChanged;

        public bool CanExecute(object parameter)
        {
            return true;
        }

        public async void Execute(object parameter)
        {
            if (!(parameter is MainPageViewModel vm)) return;
            var data = vm.AllTrials.Select(x => new Entities.Transaction.TrialLookUp
            {
                EZID = x.EZID,
                CountryCode = x.CountryCode,
                CropCode = x.CropCode,
                TrialName = x.TrialName,
                CropSegmentCode = x.CropSegmentCode,
                TrialRegionID = x.TrialRegionID,
                TrialTypeID = x.TrialTypeID,
            }).ToList();
            await App.MainNavigation.PushAsync(new SettingPage(data));
        }

    }

    internal class GoToLoginCommand : ICommand
    {
        public event EventHandler CanExecuteChanged;

        public bool CanExecute(object parameter)
        {
            return true;
        }

        public async void Execute(object parameter)
        {
            try
            {
                if (!(parameter is MainPageViewModel vm) || vm.LoginDownloadIcon == null) return;

                var source = vm.LoginDownloadIcon as FileImageSource;
                var icon = source.File;
                if (vm.IsAADLogin)
                {
                    await vm.AADLoginAsync();
                    if (icon.Contains("download"))
                        await App.MainNavigation.PushAsync(new TransferPage());
                }
                else
                {
                    if (icon.Contains("download") && WebserviceTasks.CheckTokenValidDate())
                        await App.MainNavigation.PushAsync(new TransferPage());
                    else
                        await App.MainNavigation.PushAsync(new SignInPage());
                }
            }
            catch (Exception)
            {
                await App.MainNavigation.PushAsync(new SignInPage());
            }

        }

    }
}
