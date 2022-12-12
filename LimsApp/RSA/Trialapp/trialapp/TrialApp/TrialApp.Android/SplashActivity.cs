using System.IO;
using System.Threading.Tasks;
using Android.App;
using Android.OS;
using Android.Support.V7.App;
using Android.Widget;
using Application = Android.App.Application;
using System;
using SQLite;
using TrialApp.Entities.Transaction;
using System.Linq;
using Android.Content;
using Android.Util;
//using TrialApp.Entities.Master;
//using TrialApp.Entities.Transaction;

namespace TrialApp.Droid
{
    [Activity(Theme = "@style/Theme.Splash", MainLauncher = true, NoHistory = true)]
    public class SplashActivity : AppCompatActivity
    {
        public static string loggedinUser;
        public static bool? isRegistered;
        protected override async void OnCreate(Bundle savedInstanceState)
        {
            Log.Info(AppConstants.DebugTag, "Splash activity : OnCreate() called.");
            base.OnCreate(savedInstanceState);

            //this code is added for when clicked on notification from tray
            Intent intent = this.Intent;
            if (intent != null)
            {
                Bundle extras = intent.Extras;

                if (extras != null)
                {
                    string ezid = extras.GetString("EZID");
                    //string body = extras.GetString("body");

                    LognotificationToDB(ezid);
                }
            }

            Xamarin.Essentials.Platform.Init(this, savedInstanceState); 

            SetContentView(Resource.Layout.Splash);

            var txtVersion = FindViewById<TextView>(Resource.Id.textVersion);

            var manager = this.PackageManager;
            var versionName = manager.GetPackageInfo(this.PackageName, 0).VersionName;

            txtVersion.Text = "Version: " + versionName;

            await Task.Delay(100);

            CopyDatabase();

            StartActivity(typeof(MainActivity));
        }

        public override void OnRequestPermissionsResult(int requestCode, string[] permissions, Android.Content.PM.Permission[] grantResults)
        {
            Xamarin.Essentials.Platform.OnRequestPermissionsResult(requestCode, permissions, grantResults);

            base.OnRequestPermissionsResult(requestCode, permissions, grantResults);
        }

        private void CopyDatabase()
        {
            Log.Info(AppConstants.DebugTag, "Splash activity : CopyDatabase() called.");
            var fileHelper = new FileHelper();
            var transDbPath = fileHelper.GetLocalFilePath("Transaction.db");
            var masterDbPath = fileHelper.GetLocalFilePath("Master.db");
            CopyDatabaseIfNotExists(transDbPath, "Transaction.db");
            CopyDatabaseIfNotExists(masterDbPath, "Master.db");

            //All db change script for transaction database 
            DbChangeonTransactionTable(transDbPath);

            //All db change script for master database 
            DbChangeonMasterTable(masterDbPath);
        }

        private void DbChangeonTransactionTable(string transDbPath)
        {
            using (var db = new SQLiteConnection(transDbPath))
            {
                try
                {

                    var settingParam = db.Query<SettingParameters>("select LoggedInUser, IsRegistered from SettingParameters");
                    loggedinUser = settingParam.FirstOrDefault().LoggedInUser;
                    isRegistered = settingParam.FirstOrDefault().IsRegistered;

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
        internal static void UpdateRegistration()
        {
            Log.Info(AppConstants.DebugTag, "Splash activity : UpdateRegistration() called.");
            var fileHelper = new FileHelper();
            var transDbPath = fileHelper.GetLocalFilePath("Transaction.db");
            using (var db = new SQLiteConnection(transDbPath))
            {
                db.Execute("update SettingParameters set IsRegistered = ?", 1);
                db.Commit();
            }
        }
        internal static void LognotificationToDB(string v)
        {
            Log.Info(AppConstants.DebugTag, "Splash activity : LognotificationToDB() called: " + v);
            var fileHelper = new FileHelper();
            var transDbPath = fileHelper.GetLocalFilePath("Transaction.db");
            using (var db = new SQLiteConnection(transDbPath))
            {
                db.Execute("INSERT INTO NotificationLog VALUES ( " + v + ", 1)");
                db.Commit();
            }
        }
        private void DbChangeonMasterTable(string masterDbPath)
        {
            using (var db = new SQLiteConnection(masterDbPath))
            {
                try
                {
                    var traitValueData = db.Query<Entities.Master.TraitValue>("SELECT * FROM TraitValue");

                    db.Execute("DROP TABLE TraitValue");
                    db.Execute("CREATE TABLE [TraitValue](  "
                                + " [TraitValueID]	int ( 1 , 1 ) NOT NULL, [TraitID]	int NOT NULL, [TraitValueCode]	nvarchar ( 10 ) NOT NULL, [TraitValueName]	nvarchar ( 50 ),"
                                + "[SortingOrder]	int, [MTSeq]	int NOT NULL, [MTStat]	nchar ( 3 ), PRIMARY KEY([TraitID],[TraitValueID]))"
                                );
                    if (traitValueData != null) db.InsertAll(traitValueData);

                }
                catch (Exception)
                {

                }
            }
        }

        private void CopyDatabaseIfNotExists(string dbPath, string dbFileName)
        {
            //File.Delete(dbPath);
            if (!File.Exists(dbPath))
            {
                using (var br = new BinaryReader(Application.Context.Assets.Open(dbFileName)))
                {
                    using (var bw = new BinaryWriter(new FileStream(dbPath, FileMode.Create)))
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
    }
}