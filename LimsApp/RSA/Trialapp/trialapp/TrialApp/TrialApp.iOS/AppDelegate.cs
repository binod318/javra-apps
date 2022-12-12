using Syncfusion.SfNavigationDrawer.XForms.iOS;
using System;
using System.Globalization;
using System.IO;
using System.Linq;
using Foundation;
using SQLite;
using TrialApp.Entities.Transaction;
using TrialApp.Services;
using UIKit;
using UserNotifications;
using WindowsAzure.Messaging;
using Microsoft.Identity.Client;
using Syncfusion.ListView.XForms.iOS;
using System.Threading.Tasks;
using Xamarin.Essentials;
using System.Collections.Generic;

namespace TrialApp.iOS
{
    // The UIApplicationDelegate for the application. This class is responsible for launching the 
    // User Interface of the application, as well as listening (and optionally responding) to 
    // application events from iOS.
    [Register("AppDelegate")]
    public partial class AppDelegate : global::Xamarin.Forms.Platform.iOS.FormsApplicationDelegate
    {
        public static NSData notificationRefreshTokenIos;

        private SBNotificationHub Hub { get; set; }
        private bool isRegistered = true;
        private string userName = "";
        
        //
        // This method is invoked when the application has loaded and is ready to run. In this 
        // method you should instantiate the window, load the UI into it and then make the window
        // visible.
        //
        // You have 17 seconds to return from this method, or iOS will terminate your application.
        //
        public override bool FinishedLaunching(UIApplication app, NSDictionary options)
        {
            Console.WriteLine(App.DebugTag + ": Appdelegate: FinishedLaunching start. ");
            //SQLitePCL.Batteries_V2.Init();
            CopyDatabase();

            Rg.Plugins.Popup.Popup.Init();
            global::Xamarin.Forms.Forms.Init();
            SfListViewRenderer.Init();
            SfNavigationDrawerRenderer.Init();
            //SfDataGridRenderer.Init();
            global::Xamarin.FormsMaps.Init();
            Stormlion.PhotoBrowser.iOS.Platform.Init();
            MR.Gestures.iOS.Settings.LicenseKey = GetMrGestureKey(NSBundle.MainBundle.ObjectForInfoDictionary("CFBundleName").ToString().Trim());

            CultureInfo.DefaultThreadCurrentCulture = GetCulture();

            UnitOfMeasure.SystemUoM = NSLocale.CurrentLocale.UsesMetricSystem ? "Metric" : "Imperial";
            Syncfusion.Licensing.SyncfusionLicenseProvider.RegisterLicense("MzQ1MTg5QDMxMzgyZTMzMmUzMFI4N0t0d0dCYjhzbUV6ajd0eHJlZEhILzNxZnVzZTh1bXRJbWdYZmxISUk9");

            //For other platforms Namespace is sent as input param but for android we don't need namespace so we send Application name instead of Namespace
            WebserviceTasks.SetDefaults(Foundation.NSBundle.MainBundle.ObjectForInfoDictionary("CFBundleDisplayName").ToString());
            AppConstants.SetSecureStorage();
            App.AADAppID = AppConstants.AADAppID;
            App.IsAADLogin = Convert.ToBoolean(AppConstants.IsAADLogin);
            App.RedirectURI = AppConstants.RedirectURI;
            App.ClientID = AppConstants.ClientID;
            App.ServiceAccName = AppConstants.ServiceAccName;
            App.ServiceAccPswrd = AppConstants.ServiceAccPswrd;
            MSAuthService.ParentWindow = new UIViewController(); // iOS broker requires a view controller

            
            LoadApplication(new App());
            base.FinishedLaunching(app, options);
            RegisterForRemoteNotifications();
            InitThaiCalendarCrashFix();
            Console.WriteLine(App.DebugTag + ": Appdelegate: FinishedLaunching end. ");
            return true;
        }
        private static void InitThaiCalendarCrashFix()
        {
            var localeIdentifier = NSLocale.CurrentLocale.LocaleIdentifier;
            if (localeIdentifier == "th_TH")
            {
                _ = new ThaiBuddhistCalendar();
            }
        }
        void RegisterForRemoteNotifications()
        {
            var fileHelper = new FileHelper();
            var transDbPath = fileHelper.GetLocalFilePath("Transaction.db");
            Hub = new SBNotificationHub(AppConstants.ListenConnectionString, AppConstants.NotificationHubName);

            using (var db = new SQLiteConnection(transDbPath))
            {
                var settingParam = db.Query<SettingParameters>("select LoggedInUser, IsRegistered from SettingParameters");
                //user = settingParam.FirstOrDefault().LoggedInUser;
                bool.TryParse(settingParam.FirstOrDefault().IsRegistered.ToString(), out isRegistered);
                userName = settingParam.FirstOrDefault().LoggedInUser;
            }
            Console.WriteLine(isRegistered + " isRegistered value!!!!  ");
            
            if (!isRegistered)
            {
                Console.WriteLine(App.DebugTag + ": Appdelegate: RegisterForRemoteNotifications() ");
                // register for remote notifications based on system version
                if (UIDevice.CurrentDevice.CheckSystemVersion(10, 0))
                {
                    UNUserNotificationCenter.Current.RequestAuthorization(UNAuthorizationOptions.Alert |
                        UNAuthorizationOptions.Sound |
                        UNAuthorizationOptions.Sound,
                        (granted, error) =>
                        {
                            if (granted)
                                InvokeOnMainThread(UIApplication.SharedApplication.RegisterForRemoteNotifications);
                        });
                    InvokeOnMainThread(UIApplication.SharedApplication.RegisterForRemoteNotifications);
                }
                else if (UIDevice.CurrentDevice.CheckSystemVersion(8, 0))
                {
                    var pushSettings = UIUserNotificationSettings.GetSettingsForTypes(
                    UIUserNotificationType.Alert | UIUserNotificationType.Badge | UIUserNotificationType.Sound,
                    new NSSet());

                    UIApplication.SharedApplication.RegisterUserNotificationSettings(pushSettings);
                    UIApplication.SharedApplication.RegisterForRemoteNotifications();
                }
                else
                {
                    UIRemoteNotificationType notificationTypes = UIRemoteNotificationType.Alert | UIRemoteNotificationType.Badge | UIRemoteNotificationType.Sound;
                    UIApplication.SharedApplication.RegisterForRemoteNotificationTypes(notificationTypes);
                }
            }
        }
        private CultureInfo GetCulture()
        {
            try
            {
                return new CultureInfo(NSLocale.CurrentLocale.LocaleIdentifier.Split('_')[1])
                {
                    NumberFormat = { NumberDecimalSeparator = NSLocale.CurrentLocale.DecimalSeparator }
                };
            }
            catch (CultureNotFoundException)
            {
                return new CultureInfo(NSLocale.CurrentLocale.LocaleIdentifier.Split('_')[0])
                {
                    NumberFormat = { NumberDecimalSeparator = NSLocale.CurrentLocale.DecimalSeparator }
                };
            }
        }
        private string GetMrGestureKey(string v)
        {
            if (v == "TrialAppTest")
                return "MKKT-8LTS-WNVK-646E-LKY2-H8ZE-PXK6-7Q23-4BUE-VQ99-C7WB-D54J-XHJ4";
            else if (v == "TrialAppAccept")
                return "9D3D-EM78-SNBR-SH6B-VUY3-QCEG-2CDA-NKYQ-UPP4-B3UD-338L-2NNM-WYEA";
            return "KS76-ADY5-PWBZ-H9TX-VHXY-LMGE-42LG-DSYB-LW25-TBZ8-RWW2-VPWP-MTQF";
        }

        private void CopyDatabase()
        {
            Console.WriteLine(App.DebugTag + ": CopyDatabase(). ");
            var fileHelper = new FileHelper();
            var transDbPath = fileHelper.GetLocalFilePath("Transaction.db");
            var masterDbPath = fileHelper.GetLocalFilePath("Master.db");
            var masterSource = Path.Combine(NSBundle.MainBundle.BundlePath, "Master.db");
            var transactionSource = Path.Combine(NSBundle.MainBundle.BundlePath, "Transaction.db");
            CopyDatabaseIfNotExists(transDbPath, transactionSource);
            CopyDatabaseIfNotExists(masterDbPath, masterSource);

            //All db change script for transaction database 
            DbChangeonTransactionTable(transDbPath);

            //All db change script for master database 
            DbChangeonMasterTable(masterDbPath);
        }

        private void DbChangeonTransactionTable(string transDbPath)
        {
            Console.WriteLine(App.DebugTag + ": transDbPath. " + transDbPath);
            using (var db = new SQLiteConnection(transDbPath))
            {
                try
                {
                    db.BeginTransaction();

                    //DefaultTraitsPerTrial
                    var avail = db.ExecuteScalar<bool>("SELECT CASE WHEN (SELECT name FROM sqlite_master WHERE type='table' AND name='DefaultTraitsPerTrial' ) IS NOT NULL THEN  1 ELSE 0 END");
                    if (!avail)
                        db.Execute("CREATE TABLE 'DefaultTraitsPerTrial' ('EZID' INTEGER NOT NULL, 'TraitID' INTEGER NOT NULL, 'Order' INTEGER, PRIMARY KEY (EZID, TraitID) );");

                    // Add IsRegistered field in DefaultTraitsPerTrial table
                    avail = db.ExecuteScalar<bool>("SELECT CASE WHEN (select sql from sqlite_master where type = 'table' and name = 'DefaultTraitsPerTrial' and sql like '%FieldsetID%' ) IS NOT NULL THEN  1 ELSE 0  END");
                    if (!avail)
                    {
                        db.Execute("ALTER TABLE DefaultTraitsPerTrial ADD [FieldsetID] INT");
                    }

                    // Add IsHidden field in TrialEntryApp table
                    avail = db.ExecuteScalar<bool>("SELECT CASE WHEN (select sql from sqlite_master where type = 'table' and name = 'TrialEntryApp' and sql like '%IsHidden%' ) IS NOT NULL THEN  1 ELSE 0  END");
                    if (!avail)
                    {
                        db.Execute("ALTER TABLE TrialEntryApp ADD [IsHidden] bit NOT NULL Default 0");
                    }


                    db.Commit();

                }
                catch (Exception)
                {

                }
            }
        }

        private void DbChangeonMasterTable(string masterDbPath)
        {
            Console.WriteLine(App.DebugTag + ": masterDbPath. " + masterDbPath);
            using (var db = new SQLiteConnection(masterDbPath))
            {
                try
                {

                }
                catch (Exception)
                {

                }
            }
        }

        private void CopyDatabaseIfNotExists(string DestPath, string dbSource)
        {
            if (!File.Exists(DestPath))
            {
                using (var br = new BinaryReader(new FileStream(dbSource, FileMode.Open, FileAccess.Read)))
                {
                    using (var bw = new BinaryWriter(new FileStream(DestPath, FileMode.Create, FileAccess.Write)))
                    {
                        byte[] buffer = new byte[2048];
                        int length = 0;
                        while ((length = br.Read(buffer, 0, buffer.Length)) > 0)
                        {
                            bw.Write(buffer, 0, length);
                        }
                    }
                }
            }
        }
        public override void RegisteredForRemoteNotifications(UIApplication application, NSData deviceToken)
        {
            if (!isRegistered)
            {
                Hub = new SBNotificationHub(AppConstants.ListenConnectionString, AppConstants.NotificationHubName);

                Hub.UnregisterAll(deviceToken, (error) =>
                {
                    if (error != null)
                    {
                        System.Diagnostics.Debug.WriteLine("Error calling Unregister: {0}", error.ToString());
                        return;
                    }
                    var tag = new List<string> { "apns", Guid.NewGuid().ToString() };
                    if (!string.IsNullOrEmpty(userName))
                        tag.Add(userName.Replace(" ", "_"));
                    NSSet tags = new NSSet(tag.ToArray());

                    Hub.RegisterNative(deviceToken, tags, (errorCallback) =>
                {
                    if (errorCallback != null)
                        System.Diagnostics.Debug.WriteLine("RegisterNativeAsync error: " + errorCallback.ToString());

                });
                    notificationRefreshTokenIos = deviceToken;
                });
                
            }
        }

        public override void DidReceiveRemoteNotification(UIApplication application, NSDictionary userInfo, Action<UIBackgroundFetchResult> completionHandler)
        {
            Console.WriteLine(App.DebugTag + ": DidReceiveRemoteNotification. ");

            NSDictionary aps = userInfo.ObjectForKey(new NSString("aps")) as NSDictionary;

            string alert = string.Empty;
            var message = (aps[new NSString("alert")] as NSString).ToString();
            LognotificationToDB(message.Split('|')[0]);
            if (aps.ContainsKey(new NSString("alert")))
                alert = message.Split('|')[1];

            //show alert
            if (!string.IsNullOrEmpty(alert))
            {
                //UIAlertView avAlert = new UIAlertView("Notification", alert, null, "OK", null);
                //avAlert.Show();

                Xamarin.Forms.MessagingCenter.Send<object, string>(this, TrialApp.App.NotificationReceivedKey, message.Split('|')[1]);
            }
        }
        public override void ReceivedRemoteNotification(UIApplication application, NSDictionary userInfo)
        {
            Console.WriteLine(App.DebugTag + ": ReceivedRemoteNotification. ");
            ProcessNotification(userInfo, false);
        }
        void ProcessNotification(NSDictionary options, bool fromFinishedLaunching)
        {
            // Check to see if the dictionary has the aps key.  This is the notification payload you would have sent
            if (null != options && options.ContainsKey(new NSString("aps")))
            {
                //Get the aps dictionary
                NSDictionary aps = options.ObjectForKey(new NSString("aps")) as NSDictionary;

                string alert = string.Empty;

                //Extract the alert text
                // NOTE: If you're using the simple alert by just specifying
                // "  aps:{alert:"alert msg here"}  ", this will work fine.
                // But if you're using a complex alert with Localization keys, etc.,
                // your "alert" object from the aps dictionary will be another NSDictionary.
                // Basically the JSON gets dumped right into a NSDictionary,
                // so keep that in mind.
                var message = (aps[new NSString("alert")] as NSString).ToString();
                LognotificationToDB(message.Split('|')[0]);
                if (aps.ContainsKey(new NSString("alert")))
                    alert = message.Split('|')[1];

                //If this came from the ReceivedRemoteNotification while the app was running,
                // we of course need to manually process things like the sound, badge, and alert.
                if (!fromFinishedLaunching)
                {
                    //Manually show an alert
                    if (!string.IsNullOrEmpty(alert))
                    {
                        UIAlertView avAlert = new UIAlertView("Notification", alert, null, "OK", null);
                        avAlert.Show();

                        // In case app is closed, use above code. If we use below code then unnecessary navigation is happening
                        //Xamarin.Forms.MessagingCenter.Send<object, string>(this, TrialApp.App.NotificationReceivedKey, message.Split('|')[1]);
                    }
                }
            }
        }

        private void LognotificationToDB(string v)
        {
            var fileHelper = new FileHelper();
            var transDbPath = fileHelper.GetLocalFilePath("Transaction.db");
            using (var db = new SQLiteConnection(transDbPath))
            {
                db.Execute("INSERT INTO NotificationLog VALUES ( " + v + ", 1)");
            }
        }
        public override bool OpenUrl(UIApplication app, NSUrl url, string sourceApplication, NSObject annotation)
        {
            if (AuthenticationContinuationHelper.IsBrokerResponse(sourceApplication))
            {
                AuthenticationContinuationHelper.SetBrokerContinuationEventArgs(url);
                return true;
            }

            else if (!AuthenticationContinuationHelper.SetAuthenticationContinuationEventArgs(url))
            {
                return false;
            }

            return true;
        }

        public override void WillEnterForeground(UIApplication application)
        {
            base.WillEnterForeground(application);
            Console.WriteLine(App.DebugTag + ": App will enter foreground");
        }

        /// <summary>
        /// When application goes background or screen locks this method is called. 
        /// This method takes few seconds before it goes to suspended state. so we synchronize data before app goes to suspended state.
        /// </summary>
        /// <param name="application"></param>
        public override async void DidEnterBackground(UIApplication application)
        {
            Console.WriteLine(App.DebugTag + ": App entering background state.");
            base.DidEnterBackground(application);

            var autosyncdata = await SecureStorage.GetAsync("AutoSyncData");
            bool.TryParse(autosyncdata, out bool _autosync);

            if (_autosync)
            {
                nint taskId = 0;

                taskId = UIApplication.SharedApplication.BeginBackgroundTask(() =>
                {
                    //when time is up and task has not finished, call this method to finish the task to prevent the app from being terminated
                    Console.WriteLine(App.DebugTag + ": Background task ended. ");

                    UIApplication.SharedApplication.EndBackgroundTask(taskId);
                });

                await Task.Factory.StartNew(async () => await App.RunBackgroundTask(false, true));
            }
        }

        public override void WillTerminate(UIApplication uiApplication)
        {
            base.WillTerminate(uiApplication);
            Console.WriteLine(App.DebugTag + ": App will terminate now.");
        }
    }
}
