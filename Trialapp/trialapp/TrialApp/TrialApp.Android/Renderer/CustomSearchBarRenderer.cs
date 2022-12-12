using Android.Content;
using Android.Views;
using Android.Views.InputMethods;
using Android.Widget;
using TrialApp.Controls;
using TrialApp.Droid.Renderer;
using Xamarin.Forms;
using Xamarin.Forms.Platform.Android;

[assembly: ExportRenderer(typeof(CustomSearchBar), typeof(CustomSearchBarRenderer))]
namespace TrialApp.Droid.Renderer
{
    class CustomSearchBarRenderer : SearchBarRenderer
    {
        public CustomSearchBarRenderer(Context context) : base(context)
        {
            AutoPackage = false;
        }

        protected override void OnElementChanged(ElementChangedEventArgs<SearchBar> e)
        {
            base.OnElementChanged(e);
            if (e.OldElement == null)
            {
                AutoCompleteTextView textField = (AutoCompleteTextView)
                    (((Control.GetChildAt(0) as ViewGroup)
                        .GetChildAt(2) as ViewGroup)
                        .GetChildAt(1) as ViewGroup)
                        .GetChildAt(0);

                if (textField != null)
                    textField.ImeOptions = (ImeAction)ImeFlags.NoExtractUi; // Avoid full screen keyboard on Landscape mode
            }
            
            if(e.NewElement.ClassId == "VarietySearchBar")
            {
                var icon = Control?.FindViewById(Context.Resources.GetIdentifier("android:id/search_mag_icon", null, null));
                (icon as ImageView)?.SetColorFilter(Android.Graphics.Color.White);
            }
        }
    }
}