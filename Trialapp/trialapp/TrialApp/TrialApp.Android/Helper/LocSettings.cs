using Android.Content;
using Android.Locations;
using Xamarin.Forms;
using TrialApp.Droid.Helper;
using TrialApp.Helper;

[assembly: Dependency(typeof(LocSettings))]
namespace TrialApp.Droid.Helper
{
    public class LocSettings : ILocSettings
    {
        static Context _context;

        public static void Init(Context context)
        {
            _context = context;
        }

        public void OpenLocationSettings()
        {
            if (_context != null)
            {
                LocationManager LM = (LocationManager)_context.GetSystemService(Context.LocationService);

                if (LM.IsProviderEnabled(LocationManager.GpsProvider) == false)
                    _context.StartActivity(new Intent(Android.Provider.Settings.ActionLocationSourceSettings));
                else
                    _context.StartActivity(new Intent(
                        Android.Provider.Settings.ActionApplicationDetailsSettings,
                        Android.Net.Uri.Parse("package:" + Android.App.Application.Context.PackageName)));
            }
        }

        public void OpenApplicationSettings()
        {
            _context.StartActivity(new Intent(
                Android.Provider.Settings.ActionApplicationDetailsSettings,
                Android.Net.Uri.Parse("package:" + Android.App.Application.Context.PackageName)));
        }
    }
}