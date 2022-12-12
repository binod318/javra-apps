using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TrialApp.Helper;
using TrialApp.UWP.Helper;
using Xamarin.Forms;

[assembly: Dependency(typeof(LocSettings))]
namespace TrialApp.UWP.Helper
{
    public class LocSettings : ILocSettings
    {
        public async void OpenApplicationSettings()
        {
            //await OpenUrlAsync("ms-settings:appsfeatures-app");
            await OpenUrlAsync("ms-settings:privacy-location");
        }

        public async void OpenLocationSettings()
        {
            await OpenUrlAsync("ms-settings:privacy-location");
        }

        private async Task OpenUrlAsync(string url)
        {
            await Windows.System.Launcher.LaunchUriAsync(new Uri(url));

            // TODO: Remove the next two lines (this is a nasty hack, as calling LaunchUriAsync once does not work reliably)
            //await Task.Delay(500);
            //await Windows.System.Launcher.LaunchUriAsync(new Uri(url));
        }
    }
}
