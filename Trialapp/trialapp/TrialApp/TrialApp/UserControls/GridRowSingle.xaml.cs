using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;
using Xamarin.Forms.Xaml;

namespace TrialApp.UserControls
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class GridRowSingle : ContentView
    {
        public GridRowSingle()
        {
            InitializeComponent();

            if (Device.RuntimePlatform == Device.iOS)
            {
                RowGrid.HeightRequest = 36;
            }
            //RowGrid.HeightRequest = Device.RuntimePlatform == Device.Android ? 80 : 70;
        }
    }
}