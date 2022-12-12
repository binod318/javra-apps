
using TrialApp.Common;
using TrialApp.iOS;

[assembly: Xamarin.Forms.Dependency(typeof(IOSDevice))]
namespace TrialApp.iOS
{
    public class IOSDevice : IDevice
    {
        public string GetIdentifier()
        {
            return UIKit.UIDevice.CurrentDevice.IdentifierForVendor.AsString();
        }
    }
}
