using Xamarin.Forms;

namespace TrialApp.Common
{
    public class DeviceInfo
    {
        public static string GetUniqueDeviceID()
        {
            return DependencyService.Get<IDevice>().GetIdentifier();
        }
    }
}
