using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TrialApp.Helper;

//[assembly: Xamarin.Forms.Dependency(typeof(ILocSettings))]
namespace TrialApp.Helper
{
   public interface ILocSettings
    {
        void OpenLocationSettings();
        void OpenApplicationSettings();
    }
}
