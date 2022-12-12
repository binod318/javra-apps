using System;
using TrialApp.Entities.Transaction;
using TrialApp.Services;
using TrialApp.ViewModels;
using Xamarin.Forms;

namespace TrialApp.Views
{
    public partial class VarietyPage : ContentPage
    {
        private VarietyPageViewModel vm;
        public VarietyPage(int ezid, string trialName, string cropCode)
        {
            InitializeComponent();
            vm = new VarietyPageViewModel(ezid, trialName, cropCode);
            BindingContext = vm;
            vm.Navigation = Navigation;
        }

        //private async void VarietyListView_OnItemTapped(object sender, ItemTappedEventArgs e)
        //{
        //    var varList = vm.VarietyList;
        //    if (e.Item is VarietyData stackedItem)
        //    {
        //        var id = stackedItem.VarietyId;
        //        var crop = stackedItem.Crop;
        //        await App.MainNavigation.PushAsync(new ObservationPage(id, crop, varList, vm.TrialEZID));
        //    }
        //}

        private async void TraitFirst_OnSelectedIndexChanged(object sender, EventArgs e)
        {
            if (TraitFirst.SelectedIndex < 0)
                return;
            await vm.LoadObservationData(vm.TraitSelectedFirst.TraitID.ToString(), string.Empty);
            VarietyListView.ItemsSource = null;
            VarietyListView.ItemsSource = vm.VarietyList;
        }
        private async void TraitSecond_OnSelectedIndexChanged(object sender, EventArgs e)
        {
            if (TraitSecond.SelectedIndex < 0)
                return;
            await vm.LoadObservationData(string.Empty, vm.TraitSelectedSecond.TraitID.ToString());
            VarietyListView.ItemsSource = null;
            VarietyListView.ItemsSource = vm.VarietyList;
        }

        protected override void OnAppearing()
        {
            base.OnAppearing();
            vm.LoadVarietyPageViewModel(vm.TrialEZID, vm.TrialName, trialList => { VarietyListView.ItemsSource = trialList; });
        }

        private void AddVariety_Clicked(object sender, EventArgs e)
        {
            AddVarietyPopup.IsVisible = true;
        }

        private async void BtnAddVarietyToTrial_Clicked(object sender, EventArgs e)
        {
            var _trialEntryAppService = new TrialEntryAppService();
            //Check if Variety exists with same fieldnumber of name for same Trial
            var data = await vm.CheckTrialEntry();

            if (!string.IsNullOrWhiteSpace(data))
            {
                vm.ConfirmationColor = Color.Red;
                vm.ConfirmationMessage = data;
            }
            else
            {
                var guid = Guid.NewGuid();
                var trialEntry = new TrialEntryApp
                {
                    CropCode = vm.CropCode,
                    EZID = guid.ToString(),
                    VarietyName = vm.VarietyName,
                    NewRecord = true,
                    Modified = false,
                    FieldNumber = vm.ConsecutiveNumber
                };
                var relationShip = new Relationship
                {
                    EZID1 = vm.TrialEZID,
                    EZID2 = guid.ToString(),
                    EntityTypeCode1 = "TRI",
                    EntityTypeCode2 = "TRL"
                };
                if (await _trialEntryAppService.AddVariety(trialEntry, relationShip) > 0)
                {
                    vm.VarietyName = "";
                    vm.ConsecutiveNumber = null;
                    AddVarietyPopup.IsVisible = false;

                    DependencyService.Get<IMessage>().LongTime("New variety added.");

                    //Display newly added variety in grid
                    OnAppearing();
                }
                else
                {
                    vm.ConfirmationColor = Color.Red;
                    vm.ConfirmationMessage = "Unable to add new variety.";
                }
            }
        }

        private void LblClosePopup_Tapped(object sender, MR.Gestures.TapEventArgs e)
        {
            AddVarietyPopup.IsVisible = false;
            vm.VarietyName = "";
            vm.ConsecutiveNumber = null;
            vm.ConfirmationColor = Color.Green;
            vm.ConfirmationMessage = "";
        }
        private async void RowGrid_LongPressing(object sender, MR.Gestures.LongPressEventArgs e)
        {
            var trialEntryAppService = new TrialEntryAppService();
            var grid = sender as MR.Gestures.Grid;
            var varietyId = (grid.Children[4] as Label)?.Text;

            var isNewRecord = await vm.CheckIsNewRecordAsync(varietyId);
            var hasObservationData = await vm.CheckHasObeservationDataAsync(varietyId);


            if (App.ReleaseHideVariety && (!isNewRecord || hasObservationData) )
            {
                var value = await DisplayAlert("Hide variety", "Are you sure you want to hide this variety?\nOnce hidden you won't be able to unhide the variety from the app.", "YES", "NO");
                if (value)
                {
                    if (await trialEntryAppService.HideVarietyAsync(varietyId, vm.TrialEZID))
                    {
                        OnAppearing();
                    }
                }
            }
            else
            {
                var value = await DisplayAlert("Delete variety", "Do you really want to delete this variety?", "YES", "NO");
                if (value)
                {

                    if (await vm.DeleteTrialEntry(varietyId))
                    {
                        //delete variety logic
                        await trialEntryAppService.DeleteVarietyAsync(varietyId);

                        //Remove deleted variety from grid
                        OnAppearing();
                    }
                    else
                        await DisplayAlert("Information", "Cannot delete this variety. This is not a new variety or already has observation data !", "OK");
                }
            }

           
        }

        private async void RowGrid_Tapped(object sender, MR.Gestures.TapEventArgs e)
        {
            var varList = vm.VarietyList;
            var grid = sender as MR.Gestures.Grid;
            var varietyId = (grid.Children[4] as Label)?.Text;
            var crop = (grid.Children[5] as Label)?.Text;
            try
            {
                await App.MainNavigation.PushAsync(new ObservationPage(varietyId, crop, varList, vm.TrialEZID));
            }
            catch (Exception ex)
            {

                throw;
            }
            
        }

        private void EntryNumber_Completed(object sender, EventArgs e)
        {
            EntryVarietyName.Focus();
        }

        private async void ToolbarItem_Clicked(object sender, EventArgs e)
        {
            await vm.ShowImages(vm.TrialEZID.ToString());
        }
    }

    public class VarietyData : ObservableViewModel
    {
        private string _varietyId;
        private string _fieldNumber;
        private string _varietyName;
        private string _crop;
        private string _obsvalueTrait1;
        private string _obsvalueTrait2;

        public string VarietyId
        {
            get
            {
                return _varietyId;
            }
            set
            {
                _varietyId = value;
                OnPropertyChanged();
            }
        }
        public string FieldNumber
        {
            get
            {
                return _fieldNumber;
            }
            set
            {
                _fieldNumber = value;
                OnPropertyChanged();
            }
        }
        public string VarietyName
        {
            get
            {
                return _varietyName;
            }
            set
            {
                _varietyName = value;
                OnPropertyChanged();
            }
        }
        public string Crop
        {
            get
            {
                return _crop;
            }
            set
            {
                _crop = value;
                OnPropertyChanged();
            }
        }
        public string ObsvalueTrait1
        {
            get
            {
                return _obsvalueTrait1;
            }
            set
            {
                _obsvalueTrait1 = value;
                OnPropertyChanged();
            }
        }
        public string ObsvalueTrait2
        {
            get
            {
                return _obsvalueTrait2;
            }
            set
            {
                _obsvalueTrait2 = value;
                OnPropertyChanged();
            }
        }
    }
}
