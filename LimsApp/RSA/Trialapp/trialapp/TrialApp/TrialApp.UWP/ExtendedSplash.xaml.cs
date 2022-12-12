using System;
using Windows.Foundation;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.ApplicationModel.Activation;
using Windows.UI.Core;
using Xamarin.Essentials;
using System.Threading.Tasks;
using Windows.Storage;
using System.IO;
using SQLite;

// The Blank Page item template is documented at https://go.microsoft.com/fwlink/?LinkId=234238

namespace TrialApp.UWP
{
    /// <summary>
    /// An empty page that can be used on its own or navigated to within a Frame.
    /// </summary>

    partial class ExtendedSplash : Page
    {
        internal Rect splashImageRect; // Rect to store splash screen image coordinates.
        private SplashScreen splash; // Variable to hold the splash screen object.
        internal bool dismissed = false; // Variable to track splash screen dismissal status.
        internal Frame rootFrame;
        private string currentVersion;

        // Define methods and constructor

        public ExtendedSplash(SplashScreen splashscreen, bool loadState)
        {
            InitializeComponent();

            // Current app version
            currentVersion = VersionTracking.CurrentVersion;

            // Listen for window resize events to reposition the extended splash screen image accordingly.
            // This ensures that the extended splash screen formats properly in response to window resizing.
            Window.Current.SizeChanged += new WindowSizeChangedEventHandler(ExtendedSplash_OnResize);

            splash = splashscreen;
            if (splash != null)
            {
                // Register an event handler to be executed when the splash screen has been dismissed.
                splash.Dismissed += new TypedEventHandler<SplashScreen, Object>(DismissedEventHandler);

                // Retrieve the window coordinates of the splash screen image.
                splashImageRect = splash.ImageLocation;
                PositionImage();

                PositionVersionText();

                // If applicable, include a method for positioning a progress control.
                PositionRing();

                Task.Run(async () =>
                    await DismissExtendedSplash()
                );
                
            }

            // Create a Frame to act as the navigation context
            rootFrame = new Frame();

            //copydatabase
            Task.Run(async () =>
            {
                await CopyDatabase();

                var transDbPath = Path.Combine(ApplicationData.Current.LocalFolder.Path, "Transaction.db");
                var masterDbPath = Path.Combine(ApplicationData.Current.LocalFolder.Path, "Master.db");

                //All db change script for transaction database 
                DbChangeonTransactionTable(transDbPath);

                //All db change script for master database 
                DbChangeonMasterTable(masterDbPath);
            });
        }

        void PositionImage()
        {
            extendedSplashImage.SetValue(Canvas.LeftProperty, splashImageRect.X);
            extendedSplashImage.SetValue(Canvas.TopProperty, splashImageRect.Y);
            extendedSplashImage.Height = splashImageRect.Height;
            extendedSplashImage.Width = splashImageRect.Width;
        }

        void PositionVersionText()
        {
            versionSplash.SetValue(Canvas.LeftProperty, splashImageRect.X + (splashImageRect.Width * 0.5) - (versionSplash.Width * 0.47));
            versionSplash.SetValue(Canvas.TopProperty, (splashImageRect.Y + splashImageRect.Height - (splashImageRect.Height * 0.3)));
            versionSplash.Padding = new Thickness(23,0,0,0);
            versionSplash.Text = "Version: " + currentVersion;

        }

        void PositionRing()
        {
            splashProgressRing.SetValue(Canvas.LeftProperty, splashImageRect.X + (splashImageRect.Width * 0.5) - (splashProgressRing.Width * 0.5));
            splashProgressRing.SetValue(Canvas.TopProperty, (splashImageRect.Y + splashImageRect.Height - (splashImageRect.Height * 0.1)));
        }

        void ExtendedSplash_OnResize(Object sender, WindowSizeChangedEventArgs e)
        {
            // Safely update the extended splash screen image coordinates. This function will be executed when a user resizes the window.
            if (splash != null)
            {
                // Update the coordinates of the splash screen image.
                splashImageRect = splash.ImageLocation;
                PositionImage();
                PositionVersionText();

                // If applicable, include a method for positioning a progress control.
                PositionRing();
            }
        }

        // Include code to be executed when the system has transitioned from the splash screen to the extended splash screen (application's first view).
        void DismissedEventHandler(SplashScreen sender, object e)
        {
            dismissed = true;

            // Complete app setup operations here...
        }

        async Task DismissExtendedSplash()
        {
            await Task.Delay(3000);

            await Windows.ApplicationModel.Core.CoreApplication.MainView.CoreWindow.Dispatcher.RunAsync(CoreDispatcherPriority.Normal, () => {
                rootFrame = new Frame();
                rootFrame.Content = new MainPage(); Window.Current.Content = rootFrame;
            });
        }


        private async Task CopyDatabase()
        {
            var fileHelper = new FileHelper();
            var transDbPath = fileHelper.GetLocalFilePath("Transaction.db");
            var masterDbPath = fileHelper.GetLocalFilePath("Master.db");
            try
            {
                try
                {
                    if(!File.Exists(masterDbPath))
                    {
                        var installedLocation = Windows.ApplicationModel.Package.Current.InstalledLocation;
                        var folder = await installedLocation.GetFolderAsync("Assets");
                        var databaseFile = await folder.GetFileAsync("Master.db");

                        //StorageFile databaseFile = await Package.Current.InstalledLocation.GetFileAsync("Transaction.db");
                        await databaseFile.CopyAsync(ApplicationData.Current.LocalFolder);
                    }
                    
                }
                catch
                {
                    throw new Exception("Unable to copy master database");
                }

                try
                {
                    if(!File.Exists(transDbPath))
                    {
                        var installedLocation = Windows.ApplicationModel.Package.Current.InstalledLocation;
                        var folder = await installedLocation.GetFolderAsync("Assets");
                        var databaseFile = await folder.GetFileAsync("Transaction.db");

                        await databaseFile.CopyAsync(ApplicationData.Current.LocalFolder);
                    }
                    
                }
                catch
                {
                   
                    throw new Exception("Unable to copy transaction database");
                }

                ////All db change script for transaction database 
                //DbChangeonTransactionTable(transDbPath);

                ////All db change script for master database 
                //DbChangeonMasterTable(masterDbPath);
            }
            catch (Exception e)
            {

            }
            
        }

        private void DbChangeonTransactionTable(string transDbPath)
        {
            using (var db = new SQLiteConnection(transDbPath))
            {
                try
                {
                    db.BeginTransaction();
                    // Add IsHidden field in TrialEntryApp table
                    bool avail = db.ExecuteScalar<bool>("SELECT CASE WHEN (select sql from sqlite_master where type = 'table' and name = 'TrialEntryApp' and sql like '%IsHidden%' ) IS NOT NULL THEN  1 ELSE 0  END");
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
            using (var db = new SQLiteConnection(masterDbPath))
            {
                try
                {
                    db.BeginTransaction();


                    db.Commit();
                }
                catch (Exception)
                {

                }
            }
        }
    }
}
