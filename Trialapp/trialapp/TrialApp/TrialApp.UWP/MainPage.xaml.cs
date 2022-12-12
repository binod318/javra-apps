using Syncfusion.SfDataGrid.XForms.UWP;

namespace TrialApp.UWP
{
    public sealed partial class MainPage
    {
        public MainPage()
        {
            this.InitializeComponent();


            // To have WAM working you need to register the following redirect URI for your application
            string sid = Windows.Security.Authentication.Web.WebAuthenticationBroker.GetCurrentApplicationCallbackUri()
                .Host
                .ToUpper();
            string redirectUriWithWAM = $"ms-appx-web://microsoft.aad.brokerplugin/{sid}";
            AppConstants.RedirectURI = redirectUriWithWAM;
            //Syncfusion datagrid
            SfDataGridRenderer.Init();

            //Maps
            Xamarin.FormsMaps.Init(AppConstants.MapsAuthenticationKey);
            Windows.Services.Maps.MapService.ServiceToken = AppConstants.MapsAuthenticationKey;
            
            LoadApplication(new TrialApp.App());
        }

    }
}
