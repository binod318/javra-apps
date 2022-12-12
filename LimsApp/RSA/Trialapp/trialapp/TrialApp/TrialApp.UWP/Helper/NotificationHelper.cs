using TrialApp.UWP.Helper;
using TrialApp.ViewModels.Interfaces;
using Xamarin.Forms;

[assembly: Dependency(typeof(NotificationHelper))]
namespace TrialApp.UWP.Helper
{
    public class NotificationHelper : INotificationHelper
    {
        public void UpdateToken(string userName)
        {
            
        }
    }
}
