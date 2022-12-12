using System.Linq;
using TrialApp.ViewModels;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;

namespace TrialApp.Views
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
	public partial class TransferPage : ContentPage
	{
        private TransferPageViewModel _tranferPageVm;
        public TransferPage()
        {
            InitializeComponent();
            _tranferPageVm = new TransferPageViewModel();
            _tranferPageVm.Navigation = Navigation;
            BindingContext = _tranferPageVm;
            //EntrySearch.TextChanged += _tranferPageVm.SearchTextChanged;
            MessagingCenter.Unsubscribe<TransferPageViewModel>(this, "Error");
            MessagingCenter.Subscribe<TransferPageViewModel>(this, "Error", (sender) =>
            {
                DisplayAlert("Error", "Some trials are not downloaded.", "Ok");

            });

            ////Picture download alert
            //MessagingCenter.Unsubscribe<TransferPageViewModel, int[]>(this, "PictureDownloadAlert");
            //MessagingCenter.Subscribe<TransferPageViewModel, int[]>(this, "PictureDownloadAlert", async (sender,value) =>
            //{
            //    var action = await DisplayAlert("Download Pictures", "Do you want to download the pictures so you can see them offline?", "Yes", "Cancel");
            //    if (action)
            //    {
            //        await _tranferPageVm.DownloadPicturesAsync(value);
            //        OnAppearing();
            //    }
            //    else
            //    {
            //        OnAppearing();
            //    }
            //});


        }

        protected async override void OnAppearing()
        {
            base.OnAppearing();
            await _tranferPageVm.ReloadList();

        }

        protected override void OnDisappearing()
        {
            base.OnDisappearing();

            if(_tranferPageVm.TrialsFromNotification.Any())
                _tranferPageVm._settingParametersService.DeleteNotificationLog(string.Join(",", _tranferPageVm.TrialsFromNotification.ToArray()));
        }

        private void SearchImage_Click(object sender, System.EventArgs e)
        {
            if (_tranferPageVm.SearchVisible)
                _tranferPageVm.SearchVisible = false;
            //_tranferPageVm.FilterData(_tranferPageVm.SearchText);
            else
            {
                _tranferPageVm.SearchVisible = true;
                //EntrySearch.Focus();
            }
        }

        private void CustomSearchBar_TextChanged(object sender, TextChangedEventArgs e)
        {
            var data = sender as SearchBar;
            _tranferPageVm.FilterData(data.Text);
        }
    }
}