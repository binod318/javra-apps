using Foundation;
using TrialApp.Helper;
using TrialApp.iOS.Helper;
using UIKit;
using Xamarin.Forms;

[assembly: Dependency(typeof(LocSettings))]
namespace TrialApp.iOS.Helper
{
    class LocSettings : ILocSettings
    {
        public void OpenLocationSettings()
        {
            UIApplication.SharedApplication.OpenUrl(new NSUrl("App-Prefs:root=Privacy&path=LOCATION"));
        }

        public void OpenApplicationSettings()
        {
        }

    }
}