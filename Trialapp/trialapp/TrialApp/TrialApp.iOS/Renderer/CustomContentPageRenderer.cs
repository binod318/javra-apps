using Foundation;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using TrialApp.iOS.Renderer;
using UIKit;
using Xamarin.Forms;
using Xamarin.Forms.Platform.iOS;

[assembly: ExportRenderer(typeof(ContentPage), typeof(CustomContentPageRenderer))]

namespace TrialApp.iOS.Renderer
{
    public class CustomContentPageRenderer:PageRenderer
    {
        public override void ViewDidAppear(bool animated)
        {
            View.EndEditing(true);//Solved the problem with this line of code
            base.ViewDidAppear(animated);
        }
    }
}