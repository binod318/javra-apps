using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using TrialApp.Services;
using TrialApp.ViewModels;
using Xamarin.Essentials;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;

namespace TrialApp.Views
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class SettingPage : ContentPage
    {
        private readonly SettingPageViewModel _vm;
        private readonly MSAuthService _authService;
        public SettingPage(List<Entities.Transaction.TrialLookUp> allTrials)
        {
            InitializeComponent();
            _vm = BindingContext as SettingPageViewModel;
            _authService = new MSAuthService(App.AADAppID, App.ClientID, App.RedirectURI);
            _vm.TrialList = allTrials;
        }
        protected override async void OnAppearing()
        {
            base.OnAppearing();
            await _vm.LoadProperties();
        }

        private async void SignOut_Activated(object sender, EventArgs e)
        {
            var username = WebserviceTasks.UsernameWS;
            if (string.IsNullOrEmpty(username)) return;

            var answer = false;
            if (Device.RuntimePlatform == Device.UWP)
                answer = !await DisplayAlert("Question?", "Do you really want to Sign out?", "Yes", "No");
            else
             answer = await DisplayAlert("Question?", "Do you really want to Sign out?", "Yes", "No");
            if (!answer) return;

            if (App.IsAADLogin)
                await _authService.SignOutAsync();
            _vm.ClearUserForSignOut();
            await _vm.LoadLayoutGrid();
        }

        private void LayoutPicker_SelectedIndexChanged(object sender, EventArgs e)
        {
            var value = sender as Picker;
            if (value == null || _vm == null) return;

            var select = value.SelectedIndex;
            _vm.UpdateLayoutSetting(select);
        }

        private void PropertyPicker_SelectedIndexChanged(object sender, EventArgs e)
        {
            var value = sender as Picker;
            if (value == null || _vm == null) return;

            var select = value.SelectedItem as Entities.Master.Trait;
            if (select != null)
                _vm.UpdatePropertyChange(select.TraitID);
        }

        private async void AutoSyncSwitch_Toggled(object sender, ToggledEventArgs e)
        {
            var autosyncrunning = Convert.ToBoolean(await SecureStorage.GetAsync("AutoSyncData"));
            await SecureStorage.SetAsync("AutoSyncData", e.Value.ToString());

            //if set to true trigger background task
            if (!autosyncrunning && e.Value)
            {
                App.AutoSyncData = true;
                App.TriggerBackgroundTask();
                await App.RunBackgroundTask(true, true); //run logic now
            }

            //if set to false cancel background task
            if(autosyncrunning && !e.Value)
            {
                App.AutoSyncData = false;
                App.StopBackgroundTask();
                MessagingCenter.Send<object, string>(Application.Current, "SyncDateUpdate", "");
            }
        }

        private async void TimeIntervalPicker_SelectedIndexChanged(object sender, EventArgs e)
        {
            var data = sender as Picker;
            var value = data.SelectedItem.ToString();

            var oldtime = await SecureStorage.GetAsync("AutoSyncTimeInterval");
            if(value != oldtime)
            {
                await SecureStorage.SetAsync("AutoSyncTimeInterval", value);
                //App.TimeIntervalChanged = true;
                App.RestartBackgroundTask();
                await App.RunBackgroundTask(true, true);
            }
        }
    }
}