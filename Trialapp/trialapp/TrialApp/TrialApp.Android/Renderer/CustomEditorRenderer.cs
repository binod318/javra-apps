using Android.Content;
using Android.Views.InputMethods;
using TrialApp.Controls;
using TrialApp.Droid.Renderer;
using Xamarin.Forms;
using Xamarin.Forms.Platform.Android;

[assembly: ExportRenderer(typeof(CustomEditor), typeof(CustomEditorRenderer))]
namespace TrialApp.Droid.Renderer
{
    class CustomEditorRenderer : EditorRenderer
    {
        public CustomEditorRenderer(Context context) : base(context)
        {
            AutoPackage = false;
        }

        protected override void OnElementChanged(ElementChangedEventArgs<Editor> e)
        {
            base.OnElementChanged(e);
            
            if (Control != null)
                Control.ImeOptions = (ImeAction)ImeFlags.NoExtractUi;

        }
    }
}