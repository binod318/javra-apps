using System;

using Android.App;
using Android.Content.PM;
using Android.Views;
using Android.OS;
using TrialApp.Droid.Helper;
using TrialApp.Entities.Transaction;
using System.Globalization;
using Firebase.Iid;
using Firebase.Messaging;
using Android.Util;
using Android.Content;
using Android.Gms.Common;
using System.Threading.Tasks;
using WindowsAzure.Messaging;
using Firebase;
using TrialApp.Services;
using Microsoft.Identity.Client;
using System.Net;
using Plugin.CurrentActivity;
using Plugin.Media;
using System.IO;
using Java.Security;
using Xamarin.Essentials;
using Android.Gms.Extensions;

namespace TrialApp.Droid
{
    [Activity(Label = "TrialApp", Icon = "@drawable/icon", Theme = "@style/MainTheme", MainLauncher = false, ConfigurationChanges = ConfigChanges.ScreenSize | ConfigChanges.Orientation)]
    [IntentFilter(new[] { Intent.ActionView },
        Categories = new[] { Intent.CategoryBrowsable, Intent.CategoryDefault },
        DataHost = "auth",
        DataScheme = "msal" + AppConstants.ClientID)]
    [IntentFilter(new[] { Intent.ActionView },
        Categories = new[] { Intent.CategoryBrowsable, Intent.CategoryDefault },
        DataHost = AppConstants.Appname,
        DataScheme = "msauth",
        DataPath = "/" + AppConstants.SignatureHash)]
    //[IntentFilter(new[] { Intent.ActionView },
    //    Categories = new[] { Intent.CategoryBrowsable, Intent.CategoryDefault },
    //    DataHost = AppConstants.Appname,
    //    DataScheme = "msauth",
    //    DataPath = "/VOZmx761wZLrMfIr/WNynVMl7Hc=")]
    public class MainActivity : global::Xamarin.Forms.Platform.Android.FormsAppCompatActivity
    {
        public const string TAG = "MainActivity";
        internal static readonly string CHANNEL_ID = "my_notification_channel";

        internal static MainActivity Instance { get; private set; }

        protected override async void OnCreate(Bundle savedInstanceState)
        {
            TabLayoutResource = Resource.Layout.Tabbar;
            ToolbarResource = Resource.Layout.Toolbar;

            base.OnCreate(savedInstanceState);

            Log.Info(AppConstants.DebugTag, "MainActivity : OnCreate() called.");

            CrossCurrentActivity.Current.Init(this, savedInstanceState);
            // HERE
#if DEBUG
            ServicePointManager.ServerCertificateValidationCallback = delegate { return true; };
#endif

            IsPlayServicesAvailable();
            CreateNotificationChannel();

            Rg.Plugins.Popup.Popup.Init(this);
            global::Xamarin.Forms.Forms.Init(this, savedInstanceState);
            await CrossMedia.Current.Initialize();
            Xamarin.Essentials.Platform.Init(this, savedInstanceState);
            Stormlion.PhotoBrowser.Droid.Platform.Init(this);

            MR.Gestures.Android.Settings.LicenseKey = "KS76-ADY5-PWBZ-H9TX-VHXY-LMGE-42LG-DSYB-LW25-TBZ8-RWW2-VPWP-MTQF"; // GetMrGestureKey(ApplicationInfo.LoadLabel(PackageManager));

            Syncfusion.Licensing.SyncfusionLicenseProvider.RegisterLicense("MzQ1MTg5QDMxMzgyZTMzMmUzMFI4N0t0d0dCYjhzbUV6ajd0eHJlZEhILzNxZnVzZTh1bXRJbWdYZmxISUk9");
            WebserviceTasks.SetDefaults(Application.Context.ApplicationInfo.NonLocalizedLabel.ToString());
            AppConstants.SetSecureStorage();
            //Initialize local context
            LocSettings.Init(this);
            FileAccessHelper.Init(this);

            UnitOfMeasure.SystemUoM = RegionInfo.CurrentRegion.IsMetric ? "Metric" : "Imperial";
            Instance = this;
            //IsPlayServicesAvailable();
            var options = new FirebaseOptions.Builder()
            .SetApplicationId(AppConstants.ApplicationID)
            .SetApiKey(AppConstants.ApiKey).Build();
            try
            {
                var fapp = FirebaseApp.InitializeApp(this, options);
            }
            //ignore if exists
            catch (Exception) {}
            // Set the current activity so the AuthService knows where to start.

            var lang = this.Resources.Configuration.Locale.Language;
            if (lang.ToLower().Contains("th"))
            {
                _ = new System.Globalization.ThaiBuddhistCalendar();
            }
            MSAuthService.ParentWindow = CrossCurrentActivity.Current.Activity;
            App.AADAppID = AppConstants.Appname;
            App.ClientID = AppConstants.ClientID;
            App.IsAADLogin = Convert.ToBoolean(AppConstants.IsAADLogin);
            App.RedirectURI = $"msauth://{AppConstants.Appname}/{AppConstants.SignatureHash}";
            App.ServiceAccName = AppConstants.ServiceAccName;
            App.ServiceAccPswrd = AppConstants.ServiceAccPswrd;
            LoadApplication(new App());

        }

        public static readonly int PickImageId = 1000;

        public TaskCompletionSource<Stream> PickImageTaskCompletionSource { set; get; }

        protected override void OnActivityResult(int requestCode, Result resultCode, Intent intent)
        {
            base.OnActivityResult(requestCode, resultCode, intent);
            AuthenticationContinuationHelper.SetAuthenticationContinuationEventArgs(requestCode, resultCode, intent);
            if (requestCode == PickImageId)
            {
                if ((resultCode == Result.Ok) && (intent != null))
                {
                    Android.Net.Uri uri = intent.Data;
                    Stream stream = ContentResolver.OpenInputStream(uri);

                    // Set the Stream as the completion of the Task
                    PickImageTaskCompletionSource.SetResult(stream);
                }
                else
                {
                    PickImageTaskCompletionSource.SetResult(null);
                }
            }
        }
        public override void OnRequestPermissionsResult(int requestCode, string[] permissions, Android.Content.PM.Permission[] grantResults)
        {
            Xamarin.Essentials.Platform.OnRequestPermissionsResult(requestCode, permissions, grantResults);

            base.OnRequestPermissionsResult(requestCode, permissions, grantResults);
        }
        public bool IsPlayServicesAvailable()
        {
            int resultCode = GoogleApiAvailability.Instance.IsGooglePlayServicesAvailable(this);
            if (resultCode != ConnectionResult.Success)
            {
                if (GoogleApiAvailability.Instance.IsUserResolvableError(resultCode))
                {
                    // In a real project you can give the user a chance to fix the issue.
                    //Console.WriteLine($"Error: {GoogleApiAvailability.Instance.GetErrorString(resultCode)}");
                    Log.Error(AppConstants.DebugTag, $"Error: {GoogleApiAvailability.Instance.GetErrorString(resultCode)}");
                }
                else
                {
                    //Console.WriteLine("Error: Play services not supported!");
                    Log.Error(AppConstants.DebugTag, "Error: Play services not supported!");
                    Finish();
                }
                return false;
            }
            else
            {
                //Console.WriteLine("Play Services available.");
                Log.Info(AppConstants.DebugTag, "Play Services available.");
                return true;
            }
        }
        private void CreateNotificationChannel()
        {
            if (Build.VERSION.SdkInt < BuildVersionCodes.O)
            {
                // Notification channels are new in API 26 (and not a part of the
                // support library). There is no need to create a notification
                // channel on older versions of Android.
                return;
            }
            var channelName = CHANNEL_ID;
            var channelDescription = string.Empty;
            var channel = new NotificationChannel(CHANNEL_ID, channelName, NotificationImportance.Default)
            {
                Description = channelDescription
            };

            var notificationManager = (NotificationManager)GetSystemService(NotificationService);
            notificationManager.CreateNotificationChannel(channel);
        }

        private string GetMrGestureKey(string v)
        {
            if (v == "TrialAppTest")
                return "MKKT-8LTS-WNVK-646E-LKY2-H8ZE-PXK6-7Q23-4BUE-VQ99-C7WB-D54J-XHJ4";
            else if (v == "TrialAppAccept")
                return "9D3D-EM78-SNBR-SH6B-VUY3-QCEG-2CDA-NKYQ-UPP4-B3UD-338L-2NNM-WYEA";
            return "KS76-ADY5-PWBZ-H9TX-VHXY-LMGE-42LG-DSYB-LW25-TBZ8-RWW2-VPWP-MTQF";
        }
        // This service handles the device's registration with FCM.
        //[Service]
        //[IntentFilter(new[] { "com.google.firebase.INSTANCE_ID_EVENT" })]
        //[Obsolete]
        // This service is used if app is in the foreground and a message is received.
        [Service]
        [IntentFilter(new[] { "com.google.firebase.MESSAGING_EVENT" })]
        public class MyFirebaseIIDService : FirebaseMessagingService
        {
            public async override void OnNewToken(string token)
            {
                var instanceIdResult = await FirebaseInstanceId.Instance.GetInstanceId().AsAsync<IInstanceIdResult>();
                var refreshedToken = instanceIdResult.Token;

                if (!string.IsNullOrWhiteSpace(refreshedToken))
                {
                    Log.Info(AppConstants.DebugTag, $"Token refreshed : {refreshedToken}");
                    App.NotificationRefreshToken = refreshedToken;
                    //SendRegistrationToServer(refreshedToken);
                }
            }
        }
        // This service is used if app is in the foreground and a message is received.
        [Service]
        [IntentFilter(new[] { "com.google.firebase.MESSAGING_EVENT" })]
        public class MyFirebaseMessagingService : FirebaseMessagingService
        {
            public override void OnMessageReceived(RemoteMessage message)
            {
                base.OnMessageReceived(message);

                Log.Info(AppConstants.DebugTag, "Trialapp notification Received.");

                try
                {
                    // Check if message contains a data payload.
                    if (message.Data.Count > 0)
                    {
                        var ezid = message.Data["EZID"];
                        SplashActivity.LognotificationToDB(ezid);
                        Xamarin.Forms.MessagingCenter.Send<object, string>(this, TrialApp.App.NotificationReceivedKey, message.Data["body"]);

                    }

                    // Check if message contains a notification payload.
                    if (message.GetNotification().Body != null)
                    {

                    }
                }
                catch (Exception ex)
                {
                    //Console.WriteLine("Error extracting message: " + ex);
                    Log.Error(AppConstants.DebugTag, $"Error extracting message: {ex}");
                }
            }
        }
    }
}

