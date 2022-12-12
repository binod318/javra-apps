using Syncfusion.SfNavigationDrawer.XForms.UWP;
using Syncfusion.SfDataGrid.XForms.UWP;
using System.Reflection;
using System;
using System.Collections.Generic;
using Windows.ApplicationModel;
using Windows.ApplicationModel.Activation;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Navigation;
using TrialApp.Services;
using System.Globalization;
using TrialApp.Entities.Transaction;
using Syncfusion.SfCarousel.XForms.UWP;
using FFImageLoading.Forms.Platform;
using Windows.System;
using Syncfusion.ListView.XForms.UWP;
using Syncfusion.XForms.UWP.Buttons;
using System.Linq;
using Windows.Globalization.DateTimeFormatting;
using Windows.Globalization;

namespace TrialApp.UWP
{
    /// <summary>
    /// Provides application-specific behavior to supplement the default Application class.
    /// </summary>
    sealed partial class App : Application
    {
        /// <summary>
        /// Initializes the singleton application object.  This is the first line of authored code
        /// executed, and as such is the logical equivalent of main() or WinMain().
        /// </summary>
        public App()
        {
            this.InitializeComponent();
            this.Suspending += OnSuspending;
        }

        /// <summary>
        /// Invoked when the application is launched normally by the end user.  Other entry points
        /// will be used such as when the application is launched to open a specific file.
        /// </summary>
        /// <param name="e">Details about the launch request and process.</param>
        protected override void OnLaunched(LaunchActivatedEventArgs e)
        {
            Frame rootFrame = Window.Current.Content as Frame;

            // Do not repeat app initialization when the Window already has content,
            // just ensure that the window is active
            if (rootFrame == null)
            {
                // Create a Frame to act as the navigation context and navigate to the first page
                rootFrame = new Frame();

                rootFrame.NavigationFailed += OnNavigationFailed;

                //  Display an extended splash screen if app was not previously running.
                if (e.PreviousExecutionState != ApplicationExecutionState.Running)
                {
                    bool loadState = (e.PreviousExecutionState == ApplicationExecutionState.Terminated);
                    ExtendedSplash extendedSplash = new ExtendedSplash(e.SplashScreen, loadState);
                    rootFrame.Content = extendedSplash;
                    Window.Current.Content = rootFrame;
                }
                //cacheimage
                CachedImageRenderer.Init();
                //RG plugin                
                Rg.Plugins.Popup.Popup.Init();

                // Mr.Gesture
                MR.Gestures.UWP.Settings.LicenseKey = GetMrGestureKey(GetAppName());

                //SYncfusion datagrid
                Syncfusion.Licensing.SyncfusionLicenseProvider.RegisterLicense("NTg3MTY0QDMxMzkyZTM0MmUzMGxYWDVWLzNnUHpOQ3VUSFVnMXViNlMyYkV2NzN6K0Jvc1B6N0o5THhxaDA9");
                
                List<Assembly> assembliesToInclude = new List<Assembly>();

                //Syncfusion navigation drawer
                assembliesToInclude.Add(typeof(SfNavigationDrawerRenderer).GetTypeInfo().Assembly);

                //Syncfusion datagrid
                assembliesToInclude.Add(typeof(SfDataGridRenderer).GetTypeInfo().Assembly);

                //syncfusion listview
                assembliesToInclude.Add(typeof(SfListViewRenderer).GetTypeInfo().Assembly);

                //syncfusion checkbox
                assembliesToInclude.Add(typeof(SfCheckBoxRenderer).GetTypeInfo().Assembly);



                //Popup 
               // assembliesToInclude.Add(typeof(Rg.Plugins.Popup.Popup).GetTypeInfo().Assembly);

                Rg.Plugins.Popup.Popup.GetExtraAssemblies().ToList().ForEach(assembly => assembliesToInclude.Add(assembly));

                //Map
                assembliesToInclude.Add(typeof(Xamarin.Forms.Maps.UWP.MapRenderer).GetTypeInfo().Assembly);

                //carousel
                assembliesToInclude.Add(typeof(SfCarouselRenderer).GetTypeInfo().Assembly);

                assembliesToInclude.Add(new[] { typeof(MR.Gestures.ContentPage).Assembly }[0]);
                //Xamarin forms initialize with additional assemblies
                Xamarin.Forms.Forms.Init(e, assembliesToInclude);

                //Set endpoint
                WebserviceTasks.SetDefaults(AppConstants.Appname);

                //Blob storage
                AppConstants.SetSecureStorage();
                
                

                var culture = GetCurrentCulture();
                ApplicationLanguages.PrimaryLanguageOverride = culture.Name;  
                CultureInfo.DefaultThreadCurrentCulture = culture;
                CultureInfo.DefaultThreadCurrentUICulture = culture;
                UnitOfMeasure.SystemUoM = culture.Name.Contains("-US") ? "Imperial" : "Metric";
                // Set the current activity so the AuthService knows where to start.
                //MSAuthService.ParentWindow = CrossCurrentActivity.Current.Activity;
                TrialApp.App.AADAppID = AppConstants.Appname;
                TrialApp.App.ClientID = AppConstants.ClientID;
                TrialApp.App.RedirectURI = AppConstants.RedirectURI;
                TrialApp.App.IsAADLogin = Convert.ToBoolean(AppConstants.IsAADLogin);
                //TrialApp.App.RedirectURI = $"msauth://{AppConstants.Appname}/{AppConstants.SignatureHash}";
                TrialApp.App.ServiceAccName = AppConstants.ServiceAccName;
                TrialApp.App.ServiceAccPswrd = AppConstants.ServiceAccPswrd;

                if (e.PreviousExecutionState == ApplicationExecutionState.Terminated)
                {
                    //TODO: Load state from previously suspended application
                }

                // Place the frame in the current Window
                Window.Current.Content = rootFrame;
            }

            if (rootFrame.Content == null)
            {
                // When the navigation stack isn't restored navigate to the first page,
                // configuring the new page by passing required information as a navigation
                // parameter
                rootFrame.Navigate(typeof(MainPage), e.Arguments);
            }
            // Ensure the current window is active
            Window.Current.Activate();
        }

        private CultureInfo GetCurrentCulture()
        {
            var cultureName = new DateTimeFormatter("longdate", new[] { "US" }).ResolvedLanguage;

            return new CultureInfo(cultureName);
        }

        private string GetAppName()
        {
            var list = AppDiagnosticInfo.RequestInfoAsync().GetAwaiter().GetResult();
            foreach (var info in list)
            {
                string name = info.AppInfo.DisplayInfo.DisplayName;
                if (!string.IsNullOrEmpty(name))
                    return name;
            }
            return "";
        }

        /// <summary>
        /// Invoked when Navigation to a certain page fails
        /// </summary>
        /// <param name="sender">The Frame which failed navigation</param>
        /// <param name="e">Details about the navigation failure</param>
        void OnNavigationFailed(object sender, NavigationFailedEventArgs e)
        {
            throw new Exception("Failed to load Page " + e.SourcePageType.FullName);
        }
        private string GetMrGestureKey(string v)
        {
            if (v == "TrialAppTest")
                return "MKKT-8LTS-WNVK-646E-LKY2-H8ZE-PXK6-7Q23-4BUE-VQ99-C7WB-D54J-XHJ4";
            else if (v == "TrialAppAccept")
                return "9D3D-EM78-SNBR-SH6B-VUY3-QCEG-2CDA-NKYQ-UPP4-B3UD-338L-2NNM-WYEA";
            return "KS76-ADY5-PWBZ-H9TX-VHXY-LMGE-42LG-DSYB-LW25-TBZ8-RWW2-VPWP-MTQF";
        }
        /// <summary>
        /// Invoked when application execution is being suspended.  Application state is saved
        /// without knowing whether the application will be terminated or resumed with the contents
        /// of memory still intact.
        /// </summary>
        /// <param name="sender">The source of the suspend request.</param>
        /// <param name="e">Details about the suspend request.</param>
        private void OnSuspending(object sender, SuspendingEventArgs e)
        {
            var deferral = e.SuspendingOperation.GetDeferral();
            //TODO: Save application state and stop any background activity
            deferral.Complete();
        }
    }
}
