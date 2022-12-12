using System;
using System.Linq;
using TrialApp.Entities.Master;
using TrialApp.ViewModels;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;

namespace TrialApp.Views
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
	public partial class TrialPropertiesPage : ContentPage
	{
        private TrialPropertiesPageViewModel vm;
        
        public TrialPropertiesPage (int ezid, string crop)
		{
            InitializeComponent();
            vm = new TrialPropertiesPageViewModel(ezid, crop);
            vm.Navigation = this.Navigation;
            vm.LoadFieldsset(crop);
            BindingContext = vm;
        }

        protected override async void OnAppearing()
        {
            base.OnAppearing();
            vm.LoadTrialName();
            await vm.LoadStatusset();
        }
        
        private async void PropertysetPicker_OnSelectedIndexChanged(object sender, EventArgs e)
        {
            var picker = sender as Picker;
            var value = (picker.SelectedItem as FieldSetPair).Id;

            if (PropertysetPicker.SelectedItem != null)
            {
                vm.SelectedFieldset = value;
                if (vm.SelectedFieldset > 0)
                {
                    TrialPropertiesUserControl.UnFocusEx -= vm.Entry_Unfocused;
                    TrialPropertiesUserControl.SelectedIndexChangedEx -= vm.Picker_SelectedIndexChanged;
                    TrialPropertiesUserControl.DateSelectedEx -= vm.DateData_DateSelected;
                    TrialPropertiesUserControl.FocusEx -= vm.DateEntry_Focused;
                    TrialPropertiesUserControl.ClickedEx -= vm.Today_Clicked;
                    TrialPropertiesUserControl.DatePickerUnFocusedEx -= vm.DatePicker_UnFocusedEX;
                    TrialPropertiesUserControl.RevertClickedEx -= vm.Revert_Clicked;
                    TrialPropertiesUserControl.EntryTextChangedEx -= vm.EntryTextChanged;
                    TrialPropertiesUserControl.lv_ItemTapped -= LvItemTapped;

                    await vm.LoadProperties(value);

                    TrialPropertiesUserControl.UnFocusEx += vm.Entry_Unfocused;
                    TrialPropertiesUserControl.SelectedIndexChangedEx += vm.Picker_SelectedIndexChanged;
                    TrialPropertiesUserControl.DateSelectedEx += vm.DateData_DateSelected;
                    TrialPropertiesUserControl.FocusEx += vm.DateEntry_Focused;
                    TrialPropertiesUserControl.ClickedEx += vm.Today_Clicked;
                    TrialPropertiesUserControl.DatePickerUnFocusedEx += vm.DatePicker_UnFocusedEX;
                    TrialPropertiesUserControl.RevertClickedEx += vm.Revert_Clicked;
                    TrialPropertiesUserControl.EntryTextChangedEx += vm.EntryTextChanged;
                    if (TrialPropertiesUserControl.lv_ItemTapped?.GetInvocationList()?.Length > 0)
                        return;
                    TrialPropertiesUserControl.lv_ItemTapped += LvItemTapped;
                }
                else
                    vm.TraitList = null;
            }
            else
            {
                vm.SelectedFieldset = null;
            }
        }

        public void LvItemTapped(object sender, EventArgs e)
        {
            try
            {
                var obj = ((sender as Grid)?.Children.ToList());
                if (obj == null) return;

                var left = 0;
                var top = 0;
                var traitname = (obj[1] as Label)?.Text;
                var datatype = (obj[2] as Label)?.Text;
                var minvalue = (obj[3] as Label)?.Text;
                var maxvalue = (obj[4] as Label)?.Text;
                var description = (obj[5] as Label)?.Text;

                PopupGrid.RowDefinitions.Clear();
                PopupGrid.Children.Clear();

                //Trait name
                PopupGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Auto) });
                PopupGrid.Children.Add(new Label { Text = "Prop. name", FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) }, left, top);
                left++;
                PopupGrid.Children.Add(new Label { Text = ":", FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) }, left, top);
                left++;
                PopupGrid.Children.Add(new Label { Text = traitname, FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) }, left, top);

                if ((datatype?.ToLower() == "i" || datatype?.ToLower() == "a") && !string.IsNullOrEmpty(minvalue))
                {
                    //Min value
                    left = 0;
                    top++;
                    PopupGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Auto) });
                    PopupGrid.Children.Add(new Label { Text = "Min value", FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) }, left, top);
                    left++;
                    PopupGrid.Children.Add(new Label { Text = ":", FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) }, left, top);
                    left++;
                    PopupGrid.Children.Add(new Label { Text = minvalue, FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) }, left, top);

                    //Max value
                    left = 0;
                    top++;
                    PopupGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Auto) });
                    PopupGrid.Children.Add(new Label { Text = "Max value", FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) }, left, top);
                    left++;
                    PopupGrid.Children.Add(new Label { Text = ":", FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) }, left, top);
                    left++;
                    PopupGrid.Children.Add(new Label { Text = maxvalue, FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) }, left, top);
                }

                //Description
                left = 0;
                top++;
                PopupGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Auto) });
                PopupGrid.Children.Add(new Label { Text = "Description", FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) }, left, top);
                left++;
                PopupGrid.Children.Add(new Label { Text = ":", FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) }, left, top);
                left++;
                PopupGrid.Children.Add(new Label { Text = description, FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) }, left, top);

                TraitInfoPopup.IsVisible = true;

            }
            catch (Exception)
            {
            }
        }

        public async void GPS_Click(object sender, EventArgs e)
        {
            await App.MainNavigation.PushAsync(new LocationPage(vm.Trial));
        }

        private void Button_Clicked(object sender, EventArgs e)
        {
            TraitInfoPopup.IsVisible = false;
        }

        private void Picker_SelectedIndexChanged(object sender, EventArgs e)
        {
            var picker = sender as Picker;
            var value = (picker.SelectedItem as TraitValue)?.TraitValueCode;
            if (value != null && vm.InitialStatus != value)
            {
                if (("CRE,OPEN,OBS").Contains(value))
                {
                    lblErrorStatus.IsVisible = true;
                    lblErrorStatus.Text = "You cannot change trial status to '" + value + "', please select another!";

                    vm.SelectedStatus = vm.StatusSetList.FirstOrDefault(o => o.TraitValueCode == vm.InitialStatus);
                }
                else
                {
                    lblErrorStatus.IsVisible = false;
                    vm.Picker_SelectedIndexChanged1(sender, e);
                    vm.InitialStatus = value;
                }
            }
        }
    }
}