using Android.Content;
using Android.Text.Method;
using Android.Views.InputMethods;
using TrialApp.Controls;
using TrialApp.Droid;
using Xamarin.Forms;
using Xamarin.Forms.Platform.Android;

[assembly: ExportRenderer(typeof(CustomEntry), typeof(CustomEntryRenderer))]
namespace TrialApp.Droid
{
    class CustomEntryRenderer : EntryRenderer
    {
        protected override void OnElementChanged(ElementChangedEventArgs<Entry> e)
        {
            base.OnElementChanged(e);

            if (e.NewElement != null && e.NewElement.Keyboard == Keyboard.Numeric)
            {
                Control.KeyListener = DigitsKeyListener.GetInstance("0123456789,.");
            }

            if (e.NewElement != null && e.NewElement.Keyboard == Keyboard.Telephone)
            {
                this.Control.SetRawInputType(Android.Text.InputTypes.ClassNumber);
            }

            if (Control != null)
            {
                Control.ImeOptions = (ImeAction)ImeFlags.NoExtractUi; // set keyboard size according to UI
            }
        }

        public CustomEntryRenderer(Context context) : base(context)
        {
            AutoPackage = false;
        }

    }
}