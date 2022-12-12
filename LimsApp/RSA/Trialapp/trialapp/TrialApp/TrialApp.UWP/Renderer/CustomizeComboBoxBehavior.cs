using TrialApp.Services;
using TrialApp.UWP.Renderer;
using Xamarin.Forms;
using Xamarin.Forms.Platform.UWP;
using Windows.UI.Xaml;
using Syncfusion.XForms.UWP.ComboBox;

[assembly: Dependency(typeof(CustomizeComboBoxBehavior))]
namespace TrialApp.UWP.Renderer
{
    internal class CustomizeComboBoxBehavior : ICustomizeComboBoxBehavior
    {
        public void GetRender(Syncfusion.XForms.ComboBox.SfComboBox comboBox)
        {
            var comboBoxRenderer = (Syncfusion.XForms.UWP.ComboBox.SfComboBoxRenderer)Platform.GetRenderer(comboBox);
            comboBoxRenderer.Control.Loaded += ComboBoxRenderer_Loaded;
            comboBoxRenderer = null;
        }

        public void UnHook(Syncfusion.XForms.ComboBox.SfComboBox comboBox)
        {
            var comboBoxRenderer = (SfComboBoxRenderer)Platform.GetRenderer(comboBox);
            comboBoxRenderer.Control.Loaded -= ComboBoxRenderer_Loaded;
            comboBoxRenderer = null;
        }

        private void ComboBoxRenderer_Loaded(object sender, RoutedEventArgs e)
        {
            Syncfusion.XForms.UWP.ComboBox.SfComboBox sfComboBox = sender as Syncfusion.XForms.UWP.ComboBox.SfComboBox;
            if (!sfComboBox.IsSuggestionOpen)
            {
                sfComboBox.ShowSuggestionsOnFocus = true;
                sfComboBox.Focus(FocusState.Keyboard);
                sfComboBox.Focus(FocusState.Pointer);
            }

            sfComboBox = null;
        }
    }
}
