using TrialApp.Common;
using TrialApp.UWP.Helper;
using Windows.Security.ExchangeActiveSyncProvisioning;
using Xamarin.Forms;

[assembly: Dependency(typeof(UWPDeviceInfo))]
namespace TrialApp.UWP.Helper
{
    public class UWPDeviceInfo : IDevice
    {
        public string GetIdentifier()
        {
            var deviceInformation = new EasClientDeviceInformation();
            return deviceInformation.Id.ToString();
        }
    }
}
