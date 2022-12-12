using System;
using System.Collections.Generic;
using System.Linq;
using TrialApp.Common.Extensions;
using TrialApp.Entities.Transaction;
using TrialApp.Services;
using TrialApp.ViewModels;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;

namespace TrialApp.Views
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
	public partial class MainPage : ContentPage
	{
        private readonly TrialService _service;
        private readonly MainPageViewModel _vm;
        private const string AlertMesage = "Measurement system has been changed. You must submit updated trials first.";
        public static readonly Dictionary<string, string> TrialStatus = new Dictionary<string, string>
        {
            {"10","New"},
            {"20","Synced"},
            {"30","Updated"}
        };

        public MainPage ()
		{
			InitializeComponent ();
            _vm = new MainPageViewModel();
            _service = new TrialService();
            _vm.Navigation = Navigation;
            MessagingCenter.Unsubscribe<MainPageViewModel, string[]>(this, "DisplayAlert");
            WebserviceTasks.ServiceUsername = App.ServiceAccName;
            WebserviceTasks.ServicePassword = App.ServiceAccPswrd;
            MessagingCenter.Subscribe<MainPageViewModel, string[]>(this, "DisplayAlert", async (sender, values) =>
            {
                var action = false;
                if (Device.RuntimePlatform == Device.UWP)
                    action = !(await DisplayAlert(values[0], values[1],  "Keep", "Remove"));
                else
                    action = await DisplayAlert(values[0], values[1], "Remove", "Keep");
                if (action)
                {
                    _vm.IsBusy = true;
                    //wait picture to be uploaded before delete
                    await _vm.UploadPictureAsync();
                    await _vm.RemoveTrials();
                    //wait picture to be uploaded before delete
                    //await _vm.UploadPictureAsync();
                    await _vm.RefershFilter();
                    _vm.SubmitVisible = false;
                    //_vm.SelectedTileList.Clear();
                    _vm.IsBusy = false;
                    //run delete picture Async
                    await _vm.DeletePictureAsync();
                    _vm.SelectedTileList.Clear();
                    OnAppearing();
                    _vm._settingParametersService.UpdateParams("measuringsystem", UnitOfMeasure.SystemUoM);
                }
                else
                {
                    _vm.IsBusy = true;
                    await _vm.UpdateTrial();
                    //run upload picture Async
                    await _vm.UploadPictureAsync();
                    _vm.IsBusy = false;
                    _vm.SubmitVisible = false;
                    _vm.SelectedTileList.Clear();
                    OnAppearing();
                    _vm._settingParametersService.UpdateParams("measuringsystem", UnitOfMeasure.SystemUoM);
                }
            });




            _vm.IsAADLogin = App.IsAADLogin;
            MessagingCenter.Unsubscribe<MainPageViewModel, string[]>(this, "DisplayDBAlert");
            MessagingCenter.Subscribe<MainPageViewModel, string[]>(this, "DisplayDBAlert", async (sender, values) =>
            {
                await DisplayAlert(values[0], values[1], "OK");      
            });

            MessagingCenter.Unsubscribe<MainPageViewModel, string[]>(this, "DisplayAlert1");
            MessagingCenter.Subscribe<MainPageViewModel, string[]>(this, "DisplayAlert1", async (sender, values) =>
            {
                await DisplayAlert(values[0], values[1], "OK");
            });

            MessagingCenter.Subscribe<object, string>(this, App.NotificationReceivedKey, OnMessageReceived);

            MessagingCenter.Unsubscribe<VarietyPageTablet, int>(this, "ReloadTrial");
            MessagingCenter.Subscribe<VarietyPageTablet, int>(this, "ReloadTrial", TriggerReloadTrial);

            MessagingCenter.Unsubscribe<object, string>(Application.Current, "SyncDateUpdate");
            MessagingCenter.Subscribe<object, string>(Application.Current, "SyncDateUpdate", UpdateSynctime);

            BindingContext = _vm;
        }

        protected async override void OnAppearing()
        {
            try
            {
                if (WebserviceTasks.GoDownload)
                {
                    WebserviceTasks.GoDownload = false;
                    await App.MainNavigation.PushAsync(new TransferPage());
                }
                else
                {
                    _vm.SearchVisible = false;
                    _vm.UserName = WebserviceTasks.UsernameWS.ToText();
                    _vm.Settings = (await _vm._settingParametersService.GetAllAsync()).Single();
                    _vm.DrawLoginIcon();
                    _vm.SaveFilterList = await _vm.SaveFilterService.GetSaveFilterAsync();                    
                    _vm.ReloadTrialProp = false;
                    var dbValMeasuresystem = _vm.Settings.UoM ?? "";
                    await _vm.LoadTrials();

                    //Fill property value in Tile
                    if (_vm.PropertyVisible)
                        await _vm.DisplayPropertyvalueonTile();

                    _vm.PersistSubmitTrialList();
                    
                    //Compare Measuring system of system and database value
                    if (dbValMeasuresystem != UnitOfMeasure.SystemUoM)
                    {
                        var isTrialUpdated = _vm.AllTrials.Any(x => x.OnlineStatus == "30");

                        if (string.IsNullOrEmpty(dbValMeasuresystem) || (!string.IsNullOrEmpty(dbValMeasuresystem) && !isTrialUpdated))
                            _vm._settingParametersService.UpdateParams("measuringsystem", UnitOfMeasure.SystemUoM);
                        else
                        {
                            if (!UnitOfMeasure.RaiseWarning)                                
                                await DisplayAlert("Alert", AlertMesage, "OK"); //Alert message

                            //Set warning message
                            UnitOfMeasure.RaiseWarning = true;
                        }
                        
                    }
                }

            }
            catch (Exception)
            {
                
            }
        }

        void OnMessageReceived(object sender, string msg)
        {
            //If there is already display alert active do not display second one because it repeats every step
            if (!WebserviceTasks.DisplayAlertActive)
                Device.BeginInvokeOnMainThread(async () =>
                {
                    WebserviceTasks.DisplayAlertActive = true;
                    await DisplayAlert("Trial status updated", msg, "Ok");
                    WebserviceTasks.DisplayAlertActive = false;
                    await _vm.Process_Navigation();
                });
        }

        async void TriggerReloadTrial(object sender, int msg)
        {
            await _vm.LoadTrials();

            //Fill property value in Tile
            if (_vm.PropertyVisible)
                await _vm.DisplayPropertyvalueonTile();
        }

        async void UpdateSynctime(object sender, string msg)
        {
            if (msg.ToLower().Contains("error"))
                _vm.LatestSynctime = msg;
            else
            {
                _vm.LatestSynctime = string.IsNullOrWhiteSpace(msg) ? "" : "Last sync date/time : " + msg;

                await _vm.LoadTrials();

                //Fill property value in Tile
                if (_vm.PropertyVisible)
                    await _vm.DisplayPropertyvalueonTile();
            }            
        }

        private async void Tile_Tapping(object sender, MR.Gestures.TapEventArgs e)
        {
            //if measurement system is changed and local observation is not submitted then navigate to next page is not allowed
            if (UnitOfMeasure.RaiseWarning)
            {
                await DisplayAlert("Alert", AlertMesage, "OK");
                return;
            }

            var tile = sender as MR.Gestures.StackLayout;
            var test = e.ViewPosition;
            var classid = tile?.ClassId;

            if (classid != null)
            {
                var ezid = Convert.ToInt32(tile.ClassId.Split('|')[0]);
                var trialName = tile.ClassId.Split('|')[1];
                var cropCode = tile.ClassId.Split('|')[2];

                if (Device.RuntimePlatform == Device.UWP)
                {
                    await App.MainNavigation.PushAsync(new VarietyPageTabletUWP(ezid, trialName, cropCode));
                }
                else
                {
                   if (Device.Idiom == TargetIdiom.Phone)
                        await App.MainNavigation.PushAsync(new VarietyPage(ezid, trialName, cropCode));
                   else if ((Device.Idiom == TargetIdiom.Tablet) || (Device.Idiom == TargetIdiom.Desktop))
                        await App.MainNavigation.PushAsync(new VarietyPageTablet(ezid, trialName, cropCode));
                }
            }
        }

        private async void Tile_LongPressing(object sender, MR.Gestures.LongPressEventArgs e)
        {

            if (!App.IsAADLogin && !WebserviceTasks.CheckTokenValidDate())
                await App.MainNavigation.PushAsync(new SignInPage());
            else
            {
                if (App.IsAADLogin)
                    await _vm.AADLoginAsync();
                var tile = sender as MR.Gestures.StackLayout;

                var param = (ViewModels.Trial)tile.LongPressedCommandParameter;
                param.Selected = !param.Selected;
                var param1 = new Entities.Transaction.TrialLookUp
                {
                    CountryCode = param.CountryCode,
                    TrialName = param.TrialName,
                    EZID = param.EZID,
                    TrialTypeID = param.TrialTypeID,
                    StatusCode = param.StatusName == "New" ? 10 : param.StatusName == "Synced" ? 20 : 30,// param.StatusCode,
                    CropCode = param.CropCode
                };
                _vm.UpdateSubmit(param1, param.Selected);
            }
        }

        private async void Entry_OnTextChanged(object sender, TextChangedEventArgs e)
        {
            var data = sender as SearchBar;
            if (_vm.ReloadTrialProp)
                await _vm.ReloadTrial(data.Text);
        }

        private void SearchImage_Click(object sender, EventArgs e)
        {
            if (_vm.SearchVisible)
                _vm.SearchVisible = false;
            else
            {
                _vm.SearchVisible = true;
                //EntrySearch.Focus();
            }
        }
    }
}