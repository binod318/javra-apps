using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using TrialApp.Services;
using Xamarin.Forms;
using TrialApp.Entities.Transaction;
using System.Windows.Input;
using TrialApp.Helper;
using Plugin.FilePicker;
using Xamarin.Essentials;

namespace TrialApp.ViewModels
{
    public class SettingPageViewModel : BaseViewModel
    {
        #region private variables  

        private Entities.Master.Trait _selectedProperty;
        private readonly ObservationAppService _observationAppService;
        private readonly SettingParametersService _settingParametersService;
        private readonly TraitService _traitService;
        private int _defaultLayout;
        private Thickness _ttleMargin;
        private bool _isSignOutVisible;
        private bool _autoSyncToggle;
        private string _timeInterval;

        #endregion

        #region public properties

        public int DefaultLayout
        {
            get { return _defaultLayout; }
            set
            {
                _defaultLayout = value;

                if (value == 0)
                    GridviewVisible = true;
                if (value == 1)
                    ListviewVisible = true;

                OnPropertyChanged();
            }
        }

        public Entities.Master.Trait SelectedProperty
        {
            get { return _selectedProperty; }
            set { _selectedProperty = value; OnPropertyChanged(); }
        }

        public Thickness TitleMargin
        {
            get { return _ttleMargin; }
            set { _ttleMargin = value; OnPropertyChanged(); }
        }

        public bool IsSignOutVisible
        {
            get { return _isSignOutVisible; }
            set { _isSignOutVisible = value; OnPropertyChanged(); }
        }

        public List<TrialLookUp> TrialList { get; set; }

        public ICommand BackupDatabase { get; set; }
        public ICommand RestoreDatabase { get; set; }

        public SettingParameters SettingsData { get; set; }

        public bool AutoSyncToggle
        {
            get { return _autoSyncToggle; }
            set 
            { 
                _autoSyncToggle = value;
                OnPropertyChanged(); 
            }
        }
        public string TimeInterval
        {
            get { return _timeInterval; }
            set { _timeInterval = value; OnPropertyChanged(); }
        }

        #endregion

        public SettingPageViewModel()
        {
            _observationAppService = new ObservationAppService();
            _settingParametersService = new SettingParametersService();
            _traitService = new TraitService();
            Propertylist = new List<Entities.Master.Trait>();
            BackupDatabase = new BackupDatabaseCommand();
            RestoreDatabase = new RestoreDatabaseCommand();
            Task.Run(async () =>
            {
                await LoadLayoutGrid();
                var autosyncdata = await SecureStorage.GetAsync("AutoSyncData");
                TimeInterval = await SecureStorage.GetAsync("AutoSyncTimeInterval");
                AutoSyncToggle = Convert.ToBoolean(autosyncdata);
            });
        }

        public void UpdateLayoutSetting(int index)
        {
            // 0 is gridview and 1 is listview
            GridviewVisible = (index == 0) ? true : false;

            _settingParametersService.UpdateParams("defaultlayout", index == 0 ? "grid" : "list");
        }

        public void UpdatePropertyChange(int id)
        {
            _settingParametersService.UpdateParams("displaypropertyid", id.ToString());
        }

        public async Task LoadLayoutGrid()
        {
            if (string.IsNullOrWhiteSpace(WebserviceTasks.UsernameWS))
            {
                IsSignOutVisible = false;
                TitleMargin = (Device.RuntimePlatform == Device.iOS) 
                                ? new Thickness(-30, 0, 0, 0) 
                                : new Thickness(-75, 0, 0, 0);
            }
            else
            {
                IsSignOutVisible = true;
                TitleMargin = (Device.RuntimePlatform == Device.iOS)
                                ? new Thickness(28, 0, 0, 0)
                                : new Thickness(-15, 0, 0, 0);
            }

            SettingsData = (await _settingParametersService.GetAllAsync()).Single(); //_settingParametersService.GetParamsList().Single();

            if (SettingsData != null)
            {
                var layout = SettingsData.DefaultLayout;
                DefaultLayout = layout == "grid" ? 0 : 1;
            }

            await Task.Delay(1);
        }

        public async Task LoadProperties()
        {
            if (Propertylist.Any()) return;

            var trialList = string.Join(",", TrialList.Select(x => x.EZID));
            var propertyList = await _observationAppService.LoadPropertiesHavingObservation(trialList);
            var traitIDs = string.Join(",", propertyList.Select(x => x.TraitID.ToString()));
            if (!string.IsNullOrWhiteSpace(traitIDs))
            {
                var data = await _traitService.GetTraitsAsync(traitIDs);

                // Fill empty value at top
                var firstdata = new Entities.Master.Trait()
                {
                    TraitID = 0,
                    ColumnLabel = ""

                };

                data.Insert(0, firstdata);
                Propertylist = data;
            }

            

            // Select value based on setting
            if (SettingsData != null && Propertylist != null)
            {
                var displayProperty = SettingsData.DisplayPropertyID;
                SelectedProperty = Propertylist.FirstOrDefault(o => o.TraitID == displayProperty);
            }

        }

        public void ClearUserForSignOut()
        {
            WebserviceTasks.PasswordWS = "";
            WebserviceTasks.Token = "";
            WebserviceTasks.UsernameWS = "";
            UserName = "";
        }
    }

    internal class BackupDatabaseCommand : ICommand
    {

        public event EventHandler CanExecuteChanged;

        public bool CanExecute(object parameter)
        {
            return true;
        }
        
        public async void Execute(object parameter)
        {
            var status = await Permissions.CheckStatusAsync<Permissions.StorageWrite>();
            if (status != PermissionStatus.Granted)
            {
                status = await Permissions.RequestAsync<Permissions.StorageWrite>();
            }
            if (status == PermissionStatus.Granted)
            {
                var path = Common.DbPath.GetTransactionDbPath();

                var fileAccessHelper = DependencyService.Get<IFileAccessHelper>();

                var dbBackupFileName = string.Empty;
                
                dbBackupFileName = $"TransactionDb_Backup.db";

                var msg = await fileAccessHelper.BackUpFileAsync(path, dbBackupFileName, true);
                
                await Task.Delay(1000);

                if (!string.IsNullOrWhiteSpace(msg))
                    await Application.Current.MainPage.DisplayAlert("Alert", msg, "OK");

            }

        }
    }
    internal class RestoreDatabaseCommand : ICommand
    {
        public event EventHandler CanExecuteChanged;

        public bool CanExecute(object parameter)
        {
            return true;
        }

        public async void Execute(object parameter)
        {
            var status = await Permissions.CheckStatusAsync<Permissions.StorageRead>();
            if (status != PermissionStatus.Granted)
            {
                status = await Permissions.RequestAsync<Permissions.StorageRead>();
            }
            if (status == PermissionStatus.Granted)
            {
                var path = Common.DbPath.GetTransactionDbPath();
                var fileAccessHelper = DependencyService.Get<IFileAccessHelper>();

                try
                {
                    if (Device.RuntimePlatform != Device.iOS)
                    {
                        var fileData = await CrossFilePicker.Current.PickFile();

                        if (fileData == null || string.IsNullOrWhiteSpace(fileData.FileName))
                            return; // user canceled file picking

                        if(fileData.FileName.ToLower().Contains("zip"))
                        {
                            string fileName = fileData.FileName;

                            var dbBackupFileName = $"TransactionDb_Backup.db";

                            await fileAccessHelper.RestoreDatabaseAsync(path, fileData.DataArray, dbBackupFileName);
                            await ShowMessage();
                        }
                        else
                            await Application.Current.MainPage.DisplayAlert("Error", "Please select valid file type (zip).", "OK");


                    }
                    else
                    {

                        var dbBackupFileName = $"TransactionDb_Backup.db";
                        //await fileAccessHelper.RestoreDatabaseAsync(path, null, dbBackupFileName);
                        DependencyService.Get<Helper.IRestoreDb>().RestoreMyDb(path, $"TransactionDb_Backup.zip",  async() =>
                        {
                            await ShowMessage();
                        });
                    }
                }
                catch (Exception)
                {
                }
            }

        }

        private async Task ShowMessage()
        {
            await Application.Current.MainPage.DisplayAlert("DB restored successfully!", "You must restart the app to see the changes.", "OK");
            //(Application.Current).MainPage = App.MainNavigation = new NavigationPage(new Views.MainPage());
        }
    }
}
