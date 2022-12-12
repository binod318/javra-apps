using Model;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using TrialApp.ViewModels;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;

namespace TrialApp.Views
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class FilterPage : ContentPage
    {
        private readonly FilterPageViewModel vm;
        bool eventRaised = false;

        public FilterPage(List<Entities.Transaction.TrialLookUp> allTrials)
        {
            InitializeComponent();
            vm = new FilterPageViewModel(allTrials);
            BindingContext = vm;
            vm.Navigation = this.Navigation;
            //New changes after old code stopped working
            FilterTrialTypePicker.CallbackEx += CallbackFromPopup;
            FilterCropPicker.CallbackEx += CallbackFromPopup;
            FilterCropSegmentPicker.CallbackEx += CallbackFromPopup;
            FilterTrialRegionpPicker.CallbackEx += CallbackFromPopup;
            FilterCountryPicker.CallbackEx += CallbackFromPopup;
            Property1MultiPicker.CallbackEx += CallbackFromPopup;
            Property2MultiPicker.CallbackEx += CallbackFromPopup;
            Property3MultiPicker.CallbackEx += CallbackFromPopup;
        }

        private void CallbackFromPopup(object sender, object e)
        {
            var data = e as object[];
            var source = data[0] as string;
            var items = data[1] as ObservableCollection<MyType>;

            switch(source)
            {
                case "TrialType":
                    vm.TrialTypeSelected = items;
                    break;

                case "Crop":
                    vm.CropSelected = items;
                    break;

                case "CropSegment":
                    vm.CropSegmentSelected = items;
                    break;

                case "TrialRegion":
                    vm.TrialRegionSelected = items;
                    break;

                case "Country":
                    vm.CountrySelected = items;
                    break;

                case "Property1":
                    vm.SelectedPropertyAttribute1 = items;
                    break;

                case "Property2":
                    vm.SelectedPropertyAttribute2 = items;
                    break;

                case "Property3":
                    vm.SelectedPropertyAttribute3 = items;
                    break;

                default:
                    break;
            }
        }

        protected override async void OnAppearing()
        {
            base.OnAppearing();
            await vm.LoadFilterProperties();
            await vm.LoadAllFilterData();
        }

        private void FilterSwitch_OnToggled(object sender, ToggledEventArgs e)
        {
            if (!(sender is Switch value)) return;
            vm.DisableFilter = value.IsToggled;
            var toggleValue = value.IsToggled ? "1" : "0";
            vm.ToggleFilterSetting(toggleValue);
        }

        private void entry_Textchanged(object sender, TextChangedEventArgs e)
        {
            var entry = sender as Entry;
            vm.ReloadFilter(entry.StyleId, trialtypeEntry.Text, cropEntry.Text, cropsegmentEntry.Text, trialregionEntry.Text, countryEntry.Text);
        }

        private void FilterTrialTypePicker_Clicked(object sender, EventArgs e)
        {
            if (!eventRaised)
            {
                trialtypeEntry.TextChanged += entry_Textchanged;
                countryEntry.TextChanged += entry_Textchanged;
                cropEntry.TextChanged += entry_Textchanged;
                cropsegmentEntry.TextChanged += entry_Textchanged;
                trialregionEntry.TextChanged += entry_Textchanged;
                eventRaised = true;
            }
        }

        private void PropertyPicker_OnSelectedIndexChanged(object sender, EventArgs e)
        {
            if (!(sender is Picker data)) return;

            if (!(data.SelectedItem is TrialApp.Entities.Master.Trait selectedprop)) return;

            var property = Convert.ToInt32(data.ClassId);
            vm.LoadPropertyAttributes(selectedprop, property);
        }
    }
}
