using TrialApp.Common;
using TrialApp.Droid;

[assembly: Xamarin.Forms.Dependency(typeof(AndroidDeviceInfo))]

namespace TrialApp.Droid
{
    public class AndroidDeviceInfo : IDevice
    {
        public string GetIdentifier()
        {
            return Android.OS.Build.Serial;
        }
    }
}