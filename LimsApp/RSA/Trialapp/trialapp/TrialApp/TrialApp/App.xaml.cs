using Xamarin.Forms;
using TrialApp.Views;
using System;
using System.Linq;
using System.Threading.Tasks;
using Xamarin.Essentials;
using TrialApp.Services;
using TrialApp.ViewModels;
using TrialApp.Controls;
using Xamarin.Forms.PlatformConfiguration.WindowsSpecific;
using System.Globalization;

namespace TrialApp
{
    public partial class App : Xamarin.Forms.Application
    {
        private static MyTimer timer;

        public static NavigationPage MainNavigation;
        public const string NotificationReceivedKey = "NotificationReceived";
        //public static string ClientID = "e5274716-fa80-4b01-9568-0b6fc6a9daab"; //msidentity-samples-testing tenant
        public static bool IsAADLogin = false;
        public static string AADAppID = "";
        public static string ClientID = "";
        public static string RedirectURI = "";
        public static string ServiceAccName = "";
        public static string ServiceAccPswrd = "";
        public static string Username = string.Empty;
        public static string DebugTag { get; set; } = "TrialappDebug";

        /// <summary>
        /// This is a feature Flag for Hide variety, need to be removed when HideVariety is in Prod.
        /// </summary>
        public static bool ReleaseHideVariety = true;

        public static object ParentWindow { get; set; }
        public static string TokenString { get; internal set; }
        public static string NotificationRefreshToken { get; set; }
        public static bool AutoSyncData { get; set; }

        public App()
        {
            //MjU4OTM2QDMxMzgyZTMxMmUzMElRemE0UzQrSkx2Q1EvcFhJMThSb3VneldCMDQ5RGpUaWRWdDhlcUlpQTQ9
            Syncfusion.Licensing.SyncfusionLicenseProvider.RegisterLicense("MzQ1MTg5QDMxMzgyZTMzMmUzMFI4N0t0d0dCYjhzbUV6ajd0eHJlZEhILzNxZnVzZTh1bXRJbWdYZmxISUk9");
            
            CultureInfo.DefaultThreadCurrentCulture = new CultureInfo("en-US");
            CultureInfo.DefaultThreadCurrentUICulture = new CultureInfo("en-US");

            InitializeComponent();
            //DependencyService.Register<MockDataStore>();
            MainPage = MainNavigation = new NavigationPage(new MainPage());

            //trigger background task
            TriggerBackgroundTask();

            //To show both Titleview and Toolbar on Navigation bar
            MainNavigation.On<Xamarin.Forms.PlatformConfiguration.Windows>().SetToolbarDynamicOverflowEnabled(false);
        }

        protected override void OnStart()
        {
            Console.WriteLine(DebugTag + ": App.xaml: OnStart()");
        }

        protected override void OnSleep()
        {
            Console.WriteLine(DebugTag + ": App.xaml: OnSleep()");
        }

        protected override void OnResume()
        {
            Console.WriteLine(DebugTag + ": App.xaml: OnResume()");
        }

        public static async void TriggerBackgroundTask()
        {
            Console.WriteLine(DebugTag + ": Background sync triggered.");

            //get sync time and toggle
            //var interval = Task.Run(async () => await SecureStorage.GetAsync("AutoSyncTimeInterval")).Result;
            //var autosyncdata = Task.Run(async () => await SecureStorage.GetAsync("AutoSyncData")).Result;
            var interval = await SecureStorage.GetAsync("AutoSyncTimeInterval");
            var autosyncdata = await SecureStorage.GetAsync("AutoSyncData");

            int.TryParse(interval, out int _interval);
            bool.TryParse(autosyncdata, out bool _autosync);

            //assign to static variable
            AutoSyncData = _autosync;

            if (_interval == 0)
            {
                _interval = 60; //default value 60 minutes
                //Task.Run(async () => await SecureStorage.SetAsync("AutoSyncTimeInterval", _interval.ToString()));
                await SecureStorage.SetAsync("AutoSyncTimeInterval", _interval.ToString());
            }

            if (_autosync)
            {
                // Device.StartTimer(TimeSpan.FromMinutes(_interval), RunBackgroundTask); //start timer
                timer = new MyTimer(TimeSpan.FromMinutes(_interval), async () => await RunBackgroundTask(true, true));
                timer.Start();
            }
        }

        public static void RestartBackgroundTask()
        {
            Console.WriteLine(DebugTag + ": Background sync restarted.");
            StopBackgroundTask();
            TriggerBackgroundTask();
        }

        public static void StopBackgroundTask()
        {
            Console.WriteLine(DebugTag + ": Background sync stopped.");
            timer.Stop();
        }

        public static async Task RunBackgroundTask(bool master, bool transaction)
        {
            Console.WriteLine(DebugTag + ": Background sync started to run.");

            if (IsAADLogin)
            {
                var _authService = new MSAuthService(AADAppID, ClientID, RedirectURI);
                await _authService.SignInAsync();
            }

            Console.WriteLine(DebugTag + ": AdToken : " + WebserviceTasks.AdToken);

            //start synchronizing only if user is logged in and token is valid
            if ((IsAADLogin && !string.IsNullOrWhiteSpace(WebserviceTasks.AdToken)) || (!IsAADLogin && !string.IsNullOrWhiteSpace(WebserviceTasks.Token)))
            {
                try
                {
                    //get if autosync is set on or off
                    var autosyncdata = await SecureStorage.GetAsync("AutoSyncData");

                    //sync master data
                    if (master)
                        await SynchronizeMasterData();

                    //sync transaction data
                    if (transaction)
                        await SynchronizeTransactionData();

                    Device.BeginInvokeOnMainThread(() =>
                    {
                        //put here your code which updates the view
                        // MessagingCenter.Send(Application.Current, "SyncDateUpdate", Convert.ToBoolean(autosyncdata) ? System.DateTime.Now.ToString() : "");
                        MessagingCenter.Send<object, string>(Xamarin.Forms.Application.Current, "SyncDateUpdate", AutoSyncData ? DateTime.Now.ToString() : "");
                    });
                }
                catch (Exception ex)
                {
                    Console.WriteLine(DebugTag + ": Error synchronizing data. " + ex.Message);

                    Device.BeginInvokeOnMainThread(() =>
                    {
                        //await Application.Current.MainPage.DisplayAlert("Error", ex.Message, "OK");
                        MessagingCenter.Send<object, string>(Xamarin.Forms.Application.Current, "SyncDateUpdate", "Error synchronizing data.");
                    });
                }
            }
        }

        public static async Task SynchronizeMasterData()
        {
            Console.WriteLine(DebugTag + ": Master data sync started." + DateTime.Now.ToString());

            var masterDataModule = new MasterDataModule();

            if (IsAADLogin)
            {
                if (await masterDataModule.getMetaInfoV2())
                    await masterDataModule.InitializeInputV2();
            }
            else
            {
                if (await masterDataModule.getMetaInfo())
                    await masterDataModule.InitializeInput();
            }

            Console.WriteLine(DebugTag + ": Master data sync completed." + DateTime.Now.ToString());
        }

        public static async Task SynchronizeTransactionData()
        {
            Console.WriteLine(DebugTag + ": Transaction data sync started. " + DateTime.Now.ToString());

            var trialService = new TrialService();

            //get downloaded trial list
            var trials = trialService.GetAllTrials();

            if (trials.Any())
            {
                //upload
                await trialService.Uploaddata(trials.Where(x => x.StatusCode == 30).ToList(), IsAADLogin ? "Bearer " + WebserviceTasks.AdToken : WebserviceTasks.Token);

                //download
                await trialService.DownloadTrialEntriesData(trials, true, IsAADLogin ? "Bearer " + WebserviceTasks.AdToken : WebserviceTasks.Token);
            }

            Console.WriteLine(DebugTag + ": Transaction data sync completed. " + DateTime.Now.ToString());
        }
    }

}
