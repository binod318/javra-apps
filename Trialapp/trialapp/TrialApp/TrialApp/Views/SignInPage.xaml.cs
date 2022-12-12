using TrialApp.ViewModels;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;

namespace TrialApp.Views
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
	public partial class SignInPage : ContentPage
	{
        private readonly SignInPageViewModel _vm;

        public SignInPage ()
		{
			InitializeComponent ();
            _vm = new SignInPageViewModel();
            _vm.Navigation = this.Navigation;
            BindingContext = _vm;
        }
	}
}