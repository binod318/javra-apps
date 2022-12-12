using Plugin.Media;
using Plugin.Media.Abstractions;
using Syncfusion.SfDataGrid.XForms;
using System;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using TrialApp.Common.Extensions;
using TrialApp.Entities.Transaction;
using TrialApp.ViewModels;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;

namespace TrialApp.Views
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class ObservationPage : ContentPage
    {
        private ObservationPageViewModel vm;
        private VarietyBaseViewModel vmV;
        

        public ObservationPage(string id, string crop, List<VarietyData> varList, int trialEzid)
        {
            InitializeComponent();
            vm = new ObservationPageViewModel();
            //vmV = new VarietyBaseViewModel();
            vm.LoadObservationViewModel(id, crop, varList, trialEzid);
            vm.LoadFieldsset();
            SelectDefaultFieldset();
            BindingContext = vm;
            vm.ObservationDate = DateTime.Now;
            ObsDatePicker.MaximumDate = DateTime.Now;
        }

        private async void FieldsetPicker_OnSelectedIndexChanged(object sender, EventArgs e)
        {
            vm.IsBusy = true;
            await Task.Delay(10);
            var picker = sender as Picker;
            var value = (picker.SelectedItem as FieldSetPair).Id;
            if (value == 0)
                vm.ReorderVisible = false;
            else
                vm.ReorderVisible = true;

            if (FieldsetPicker.SelectedItem != null)
            {
                vm.SelectedFieldset = value;
                if (vm.SelectedFieldset > 0)
                {
                    ObservationUserControl.UnFocusEx -= vm.Entry_Unfocused;
                    ObservationUserControl.SelectedIndexChangedEx -= vm.Picker_SelectedIndexChanged;
                    ObservationUserControl.DateSelectedEx -= vm.DateData_DateSelected;
                    ObservationUserControl.FocusEx -= vm.DateEntry_Focused;
                    ObservationUserControl.ClickedEx -= vm.Today_Clicked;
                    ObservationUserControl.DatePickerUnFocusedEx -= vm.DatePicker_UnFocusedEX;
                    ObservationUserControl.RevertClickedEx -= vm.Revert_Clicked;
                    ObservationUserControl.EntryTextChangedEx -= vm.EntryTextChanged;
                    ObservationUserControl.lv_ItemTapped -= LvItemTapped;
                    ObservationUserControl.lv_LongPressed -= LvLongPressed;

                    
                    await vm.FetchFieldsetTraits(value);
                    await vm.LoadTraits(true);

                    ObservationUserControl.UnFocusEx += vm.Entry_Unfocused;
                    ObservationUserControl.SelectedIndexChangedEx += vm.Picker_SelectedIndexChanged;
                    ObservationUserControl.DateSelectedEx += vm.DateData_DateSelected;
                    ObservationUserControl.FocusEx += vm.DateEntry_Focused;
                    ObservationUserControl.ClickedEx += vm.Today_Clicked;
                    ObservationUserControl.DatePickerUnFocusedEx += vm.DatePicker_UnFocusedEX;
                    ObservationUserControl.RevertClickedEx += vm.Revert_Clicked;
                    ObservationUserControl.EntryTextChangedEx += vm.EntryTextChanged;
                    ObservationUserControl.lv_LongPressed += LvLongPressed;
                    if (ObservationUserControl.lv_ItemTapped?.GetInvocationList()?.Length > 0)
                        return;
                    ObservationUserControl.lv_ItemTapped += LvItemTapped;
                }
                else
                {
                    vm.TraitList = null;
                }
            }
            else
            {
                vm.SelectedFieldset = null;
            }

            vm.IsBusy = false;
        }

        private async void SelectDefaultFieldset()
        {
            vm.IsBusy = true;
            await Task.Delay(10);

            var fieldsetId = await vm.GetDefaultTraitsPerTrials();

            if(fieldsetId == 0) //old logic
                vm.SelectDefaultFS();
            else
            {
                ObservationUserControl.UnFocusEx -= vm.Entry_Unfocused;
                ObservationUserControl.SelectedIndexChangedEx -= vm.Picker_SelectedIndexChanged;
                ObservationUserControl.DateSelectedEx -= vm.DateData_DateSelected;
                ObservationUserControl.FocusEx -= vm.DateEntry_Focused;
                ObservationUserControl.ClickedEx -= vm.Today_Clicked;
                ObservationUserControl.DatePickerUnFocusedEx -= vm.DatePicker_UnFocusedEX;
                ObservationUserControl.RevertClickedEx -= vm.Revert_Clicked;
                ObservationUserControl.EntryTextChangedEx -= vm.EntryTextChanged;
                ObservationUserControl.lv_ItemTapped -= LvItemTapped;
                ObservationUserControl.lv_LongPressed -= LvLongPressed;

                FieldsetPicker.SelectedIndexChanged -= FieldsetPicker_OnSelectedIndexChanged;

                //convert fieldsetId to index
                var tt = vm.TraitSetList.FirstOrDefault(x => x.Id == fieldsetId);
                var index = vm.TraitSetList.IndexOf(tt);
                vm.PickerSelectedIndex = index;

                vm.SelectedFieldset = fieldsetId;
                await vm.FetchFieldsetTraits(fieldsetId);
                await vm.LoadTraits(false);
                vm.ReorderVisible = true;

                FieldsetPicker.SelectedIndexChanged += FieldsetPicker_OnSelectedIndexChanged;

                ObservationUserControl.UnFocusEx += vm.Entry_Unfocused;
                ObservationUserControl.SelectedIndexChangedEx += vm.Picker_SelectedIndexChanged;
                ObservationUserControl.DateSelectedEx += vm.DateData_DateSelected;
                ObservationUserControl.FocusEx += vm.DateEntry_Focused;
                ObservationUserControl.ClickedEx += vm.Today_Clicked;
                ObservationUserControl.DatePickerUnFocusedEx += vm.DatePicker_UnFocusedEX;
                ObservationUserControl.RevertClickedEx += vm.Revert_Clicked;
                ObservationUserControl.EntryTextChangedEx += vm.EntryTextChanged;
                ObservationUserControl.lv_LongPressed += LvLongPressed;
                if (ObservationUserControl.lv_ItemTapped?.GetInvocationList()?.Length > 0)
                    return;
                ObservationUserControl.lv_ItemTapped += LvItemTapped;
            }

            vm.IsBusy = false;
        }

        public void LvItemTapped(object sender, EventArgs e)
        {
            try
            {
                vm.TraitInfoPopupHeight = 300;
                //var obj = ((sender as Grid)?.Children.ToList());
                var obj = ((sender as StackLayout)?.Children.ToList());
                if (obj == null) return;

                var left = 0;
                var top = 0;
                var traitname = (obj[1] as Label)?.Text;
                var datatype = (obj[2] as Label)?.Text;
                var minvalue = (obj[3] as Label)?.Text;
                var maxvalue = (obj[4] as Label)?.Text;
                var description = (obj[5] as Label)?.Text;

                TraitInfoPopupGrid.RowDefinitions.Clear();
                TraitInfoPopupGrid.Children.Clear();

                //Trait name
                TraitInfoPopupGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Auto) });
                TraitInfoPopupGrid.Children.Add(new Label { Text = "Trait name", TextColor = Color.Black, FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) + 2 }, left, top);
                top++;
                TraitInfoPopupGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Auto) });
                TraitInfoPopupGrid.Children.Add(new Label { Text = traitname, TextColor = Color.FromHex("#555"), FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) - 1, Margin = new Thickness(0, 0, 0, 10) }, left, top);
                top++;

                if ((datatype?.ToLower() == "i" || datatype?.ToLower() == "a") && !string.IsNullOrEmpty(minvalue))
                {
                    //Min value
                    TraitInfoPopupGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Auto) });
                    TraitInfoPopupGrid.Children.Add(new Label { Text = "Min value", TextColor = Color.Black, FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) + 2 }, left, top);
                    top++;
                    TraitInfoPopupGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Auto) });
                    TraitInfoPopupGrid.Children.Add(new Label { Text = minvalue, TextColor = Color.FromHex("#555"), FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) - 1, Margin = new Thickness(0, 0, 0, 10) }, left, top);
                    top++;

                    //Max value
                    TraitInfoPopupGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Auto) });
                    TraitInfoPopupGrid.Children.Add(new Label { Text = "Max value", TextColor = Color.Black, FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) + 2 }, left, top);
                    top++;
                    TraitInfoPopupGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Auto) });
                    TraitInfoPopupGrid.Children.Add(new Label { Text = maxvalue, TextColor = Color.FromHex("#555"), FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) - 1, Margin = new Thickness(0, 0, 0, 10) }, left, top);
                    top++;

                    vm.TraitInfoPopupHeight = 400;
                }

                ////Description
                TraitInfoPopupGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Auto) });
                TraitInfoPopupGrid.Children.Add(new Label { Text = "Description", TextColor = Color.Black, FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) + 2 }, left, top);
                top++;
                TraitInfoPopupGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Auto) });
                TraitInfoPopupGrid.Children.Add(new Label { Text = description, TextColor = Color.FromHex("#555"), FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) - 1, Margin = new Thickness(0, 0, 0, 10) }, left, top);
                top++;

                TraitInfoPopup.IsVisible = true;

            }
            catch (Exception)
            {

            }
        }
        
        private void ToggleResistance_Clicked(object sender, EventArgs e)
        {
            vm.ResistanceStackVisible = !vm.ResistanceStackVisible;
            vm.ToggleResistanceIcon = vm.ResistanceStackVisible ? ImageSource.FromFile("Assets/hideresist.png") : ImageSource.FromFile("Assets/showresist.png");
        }

        private void Button_Clicked(object sender, EventArgs e)
        {
            // var row = (int)((BindableObject)sender).GetValue(Grid.RowProperty);
            //var item = PopupGrid;
            TraitInfoPopup.IsVisible = false;
            HistorydataPopup.IsVisible = false;
            ObservationUserControl.IsEnabled = true;
            vm.PrevObsVisibleBase = true;
        }

        private async void LvLongPressed(object sender, MR.Gestures.LongPressEventArgs e)
        {
            var obj = sender as MR.Gestures.Grid;
            var trait = obj.LongPressingCommandParameter as TrialApp.ViewModels.Trait;
            if (trait == null) return;
            vm.TraitName = trait.TraitName;
            // To cancel single press event for picker/date/entry that hits after long press : should be enabled after close
            ObservationUserControl.IsEnabled = false;
            await vm.GetHistoryObservation(vm.EzId, trait.TraitID, trait.DataType);
            HistorydataPopup.IsVisible = true;
        }

        private void Camera_Clicked(object sender, EventArgs e)
        {
            PhotoUploadPopup.IsVisible = true;
        }

        private async void LblCamera_Tapped(object sender, MR.Gestures.TapEventArgs e)
        {
            try
            {                
                PhotoUploadPopup.IsVisible = false;
                TraitListForImage.SelectedIndexChanged -= TraitListForImage_SelectedIndexChanged;
                TraitListForImage.SelectedItem = null;
                TraitListForImage.SelectedIndexChanged += TraitListForImage_SelectedIndexChanged;
                vm.PictureLocation = "";
                //var guid = Guid.NewGuid(); 
                var guid = DateTime.Now.ToString("yyyyMMddHHmmssfff");
                var fileName = guid + "_" + vm.FieldNumber.Trim().Replace(" ", "-") + "_" + vm.Variety.Trim().Replace(" ", "-") + ".jpg";
                var path = Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.Personal), "TrialAppPictures", vm.TrialEzId.ToString(), vm.EzId);
                //var path = Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.Personal), "tempTrialImg.jpg");
                var photo = await CrossMedia.Current.TakePhotoAsync(new StoreCameraMediaOptions()
                {
                    DefaultCamera = Plugin.Media.Abstractions.CameraDevice.Rear,
                    RotateImage = false,
                    SaveToAlbum = false,
                    Name = fileName,
                    SaveMetaData = true
                });
                if (!Directory.Exists(path))
                    Directory.CreateDirectory(path);
                if (photo != null)
                {
                    vm.PictureLocation = path + "/" + fileName;
                    File.Copy(photo.Path, vm.PictureLocation, true);
                    
                    File.Delete(photo.Path);
                    photo.Dispose();
                    await vm.UploadPhotoFromCameraAsync(vm.PictureLocation);
                    if (vm.ImagePrevPopup)
                    {
                        if (vm.TraitsOnControl.Any())
                        {
                            await vm.loadTraitPerCrop(vm.Crop);
                            //vm.TraitsOnControl.Add(new Trait
                            //{
                            //    ColumnLabel = "No Trait",
                            //    TraitName = "No Trait"
                            //});
                            TraitListForImage.ItemsSource = vm.TraitsOnControl;
                        }
                        TraitListForImage.Focus();
                    }
                }

            }
            catch (Exception ex)
            {
                await DisplayAlert("Error", ex.Message.ToString(), "Ok");
            }
        }

        private async void LblGallery_Tapped(object sender, MR.Gestures.TapEventArgs e)
        {
            PhotoUploadPopup.IsVisible = false;
            //TraitListForImage.IsVisible = false;
            TraitListForImage.SelectedIndexChanged -= TraitListForImage_SelectedIndexChanged;
            TraitListForImage.SelectedItem = null;
            TraitListForImage.SelectedIndexChanged += TraitListForImage_SelectedIndexChanged;
            await vm.UploadPhotoFromGalleryAsync();
            if(vm.ImagePrevPopup)
            {
                if (vm.TraitsOnControl.Any())
                {
                    await vm.loadTraitPerCrop(vm.Crop);
                    //vm.TraitsOnControl.Add(new Trait
                    //{
                    //    ColumnLabel = "No Trait",
                    //    TraitName = "No Trait"
                    //});
                    TraitListForImage.ItemsSource = vm.TraitsOnControl;
                }
                TraitListForImage.Focus();
            }
        }

        private void CloseAddImage_Tapped(object sender, MR.Gestures.TapEventArgs e)
        {
            PhotoUploadPopup.IsVisible = false;
        }

        private async void ImgReorder_Tapped(object sender, EventArgs e)
        {
            TraitReorderPopup.IsVisible = true;
            vm.LoadReOrderTraitList();
        }

        private async void BtnOkReorder_Clicked(object sender, EventArgs e)
        {
            vm.IsBusy = true;
            TraitReorderPopup.IsVisible = false;
            await Task.Delay(10);
            await vm.SaveDefaultTraits();
            vm.DefaultTraitlistPerTrial = null;
            await vm.LoadTraits(false);
            vm.IsBusy = false;
        }

        private void BtnCancelReorder_Clicked(object sender, EventArgs e)
        {
            TraitReorderPopup.IsVisible = false;
        }

        private async void BtnPreviewConfirm_Clicked(object sender, EventArgs e)
        {
            if (TraitListForImage.SelectedItem == null)
            {
                await DisplayAlert("Error", "Please select trait before saving picture!", "OK");
                TraitListForImage.Focus();
                return;
            }

            var selectedTraitID = "";
            var selectedTraitName = "";
            var selectedItem = TraitListForImage.SelectedItem as Trait;
            if (selectedItem != null)
            {
                selectedTraitID = selectedItem.TraitID.ToText();
                selectedTraitName = selectedItem.ColumnLabel;
            }
            await vm.UploadPictureConfirmed(vm.TrialEzId, vm.EzId, vm.FieldNumber.Trim().Replace(" ", "-"), vm.Variety.Trim().Replace(" ", "-"), selectedTraitID, selectedTraitName.Replace("%", ""));
        }

        private void BtnNo_Clicked(object sender, EventArgs e)
        {
            try
            {
                showImagePreviewPopup.IsVisible = false;
                if (File.Exists(vm.PictureLocation))
                {
                    File.Delete(vm.PictureLocation);
                }
                //File.Delete(Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.Personal), "tempTrialImg.jpg"));
            }
            catch
            {

            }
            
            
            
        }

        private void TraitListForImage_SelectedIndexChanged(object sender, EventArgs e)
        {
            btnConfirm.IsVisible = true;
        }

        private void LblClosePopupTE_Tapped(object sender, MR.Gestures.TapEventArgs e)
        {
            vm.TraitEditorPopupVisible = false;
            lblValidation.Text = "";
        }

        private async void TraitEditorPopupOk_Clicked(object sender, EventArgs e)
        {
            var validationResult = vm.Validation.validateTrait(vm.DataType, vm.Format, TraitEditor.Text);
            if (string.IsNullOrEmpty(validationResult))
            {
                var trait = vm.TraitList.FirstOrDefault(x => x.TraitID == vm.TraitEditorID);
                if (trait != null)
                {
                    trait.ValueBeforeChanged = trait.ObsValue;
                    var observation = new ObservationAppLookup
                    {
                        EZID = vm.EzId,
                        TraitID = trait.TraitID,
                        DateCreated = ObsDatePicker.Date.ToString("yyyy-MM-ddT00:00:00"),//DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss"),
                        DateUpdated = ObsDatePicker.Date.ToString("yyyy-MM-ddT00:00:00"),//DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss"),
                        UserIDCreated = "user",
                        UserIDUpdated = "user",
                        Modified = true,
                        UoMCode = trait.UoMCode
                    };
                    
                    observation = vm.ObservationWithCorrVal(observation, vm.DataType.ToLower(), TraitEditor.Text);

                    //Inserts or update based on property/trait and data in database
                    await vm.InsertOrUpdateObservation(trait, observation);

                    await vm.UpdateCumulatedData(trait.TraitID);
                    vm.TrialService.UpdateTrialStatus(vm.TrialEzId);
                    trait.ValidationErrorVisible = false;
                    if (trait.ObsvalueInitial != TraitEditor.Text)
                    {
                        trait.RevertVisible = true;
                        trait.ChangedValueVisible = true;
                    }
                    else
                    {
                        trait.RevertVisible = false;
                        trait.ChangedValueVisible = false;
                    }

                    vm.TraitEditorPopupVisible = false;                   
                    trait.ObsValue = TraitEditor.Text;
                    lblValidation.Text = "";
                    trait.ChangedValueVisible = true;
                }


            }
            else
            {
                lblValidation.Text = "Validation Failed";

            }
        }

        private void TraitEditor_TextChanged(object sender, TextChangedEventArgs e)
        {
            if (!TraitEditor.IsFocused)
                TraitEditor.Focus();
        }

        //private void Clock_Clicked(object sender, EventArgs e)
        //{
        //    ObsDatePicker.IsVisible = true;
        //}

        private void ObsDatePicker_DateSelected(object sender, DateChangedEventArgs e)
        {
            vm.ObservationDate = e.NewDate;
            //ObsDatePicker.IsVisible = false;
        }

        private async void PrevObsCalendar_Clicked(object sender, EventArgs e)
        {
            //historyGrid.ItemsSource = vm.HistoryObservations;
            HistorydataPopup.IsVisible = true;

        }

        private async void ShowPrevObs_Clicked(object sender, EventArgs e)
        {
            vm.PrevObsVisibleBase = !vm.PrevObsVisibleBase;
            await vm.UpdateUserControl();

        }

        private async void HistoryGrid_SelectionChanged(object sender, GridSelectionChangedEventArgs e)
        {
            //if (historyGrid.CurrentItem != null)
            //{
            //    vm.PreviousObsFilter = historyGrid.CurrentItem as ObservationAppHistory;
                
              //  vm.PrevObsSelected = DateTime.Parse(vm.PreviousObsFilter.DateCreated).ToString("dd-M-yy") + " " + vm.PreviousObsFilter.UserIDCreated;
            //}
            HistorydataPopup.IsVisible = false;
        }
        private void Label_Tapped(object sender, MR.Gestures.TapEventArgs e)
        {
            HistorydataPopup.IsVisible = false;
        }

        void CheckBox_CheckedChanged(System.Object sender, Xamarin.Forms.CheckedChangedEventArgs e)
        {
            var checkbox = (CheckBox)sender;
            var ob = checkbox.BindingContext as ObservationAppHistory;

            if (ob != null)
            {
                if (ob.IsChecked)
                 vm.PreviousObsFilter = ob;
                  
            }

        }
        private void TapGestureRecognizer_Tapped(object sender, EventArgs e)
        {
            foreach (var i in vm.HistoryObservations)
            {
                if (i.Equals((sender as Label).BindingContext as ObservationAppHistory))
                {
                    i.IsChecked = true;
                }
                else
                {
                    i.IsChecked = false;
                }
            }
        }
    }
}