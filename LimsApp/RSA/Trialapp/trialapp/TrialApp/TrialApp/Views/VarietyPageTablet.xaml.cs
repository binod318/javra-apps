using Azure.Storage.Blobs;
using Plugin.Media;
using Plugin.Media.Abstractions;
using Stormlion.PhotoBrowser;
using Syncfusion.SfDataGrid.XForms;
using Syncfusion.SfDataGrid.XForms.Renderers;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Dynamic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using TrialApp.Common.Extensions;
using TrialApp.Controls;
using TrialApp.Entities.Master;
using TrialApp.Entities.Transaction;
using TrialApp.Services;
using TrialApp.ViewModels;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;

namespace TrialApp.Views
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class VarietyPageTablet : ContentPage
    {
        private int trialEzid;
        private VarietyPageTabletViewModel vm;
        private string trialEntryEzid = "";
        private List<Entities.Master.Trait> traitsOnGrid;
        private static MediaFile phototoUpload;
        public VarietyPageTablet(int ezid, string trialName, string cropCode)
        {
            trialEzid = ezid;
            InitializeComponent();
            vm = new VarietyPageTabletViewModel(ezid, trialName, cropCode)
            {

                filtertextchanged = OnFilterChanged
            };
            vm.IsBusy = true;
            BindingContext = vm;
            DisableUpdateMode();
            traitsOnGrid = new List<Entities.Master.Trait>();
            DataGrid.GridStyle = new CustomGridStyle();
            DataGrid.CellRenderers.Remove("TextView");
            DataGrid.CellRenderers.Add("TextView", new CustomTextViewRenderer(this.DataGrid));
            DataGrid.CellRenderers.Remove("Numeric");
            DataGrid.CellRenderers.Add("Numeric", new CustomNumericViewRenderer(this.DataGrid));
            DataGrid.CellRenderers.Remove("DateTime");
            DataGrid.CellRenderers.Add("DateTime", new CustomDateTimeViewRenderer(this.DataGrid));
            DataGrid.CellRenderers.Remove("ComboBox");
            DataGrid.CellRenderers.Add("ComboBox", new CustomComboboxViewRenderer(this.DataGrid));

            DataGrid.CellRenderers.Remove("Picker");
            DataGrid.CellRenderers.Add("Picker", new CustomPickerViewRenderer(this.DataGrid));

        }

        protected async override void OnAppearing()
        {
            base.OnAppearing();
            if (!vm.IsPageLoaded)
            {
                await Task.Delay(1);
                vm.LoadFieldSetAsync();
                await vm.LoadGridDataAsync();
                DataGrid.ItemsSource = vm.VarietyDetailList;
                TraitsetPicker.ItemsSource = vm.FieldSet;
                FixedColumnPicker.SelectedIndex = 0;
                await vm.GetAllTraitsAsync(vm.CropCode);
                await LoadDefaultTraitSet();
                await SetBusyFalse();
                vm.IsBusy = false;
                WebserviceTasks.CellNotValidated = false;

                //By default sort column by fieldnumber
                DataGrid.SortColumnDescriptions.Add(new SortColumnDescription() { ColumnName = "FieldNumber" });
                vm.IsPageLoaded = true;
            }
        }

        private async Task SetBusyFalse()
        {
            await Task.Delay(1);
            vm.IsBusy = false;
        }

        protected async override void OnDisappearing()
        {
            //fire endedit for last cell 
            try
            {
                if (this.DataGrid.AllowEditing)
                    this.DataGrid.EndEdit();
            }
            catch
            {
            }

            if (vm.DataObservation.Count > 0)
            {
                var action = await DisplayAlert("Save changes?", "Do you want to save changes before leaving?", "Yes", "No");
                if (action)
                {
                    if (await vm.SaveToDB())
                    {
                        if (vm.TrialDetail.StatusCode != 30)
                        {
                            var _trialService = new TrialService();
                            _trialService.UpdateTrialStatus(vm.TrialEZID);

                            MessagingCenter.Send(this, "ReloadTrial", 1);
                        }
                        vm.OldObservation.Clear();
                        await Application.Current.MainPage.DisplayAlert("Info", "Observation data saved successfully", "OK");
                    }
                    else
                        await Application.Current.MainPage.DisplayAlert("Error", "Observation data couldn't be saved for the data: " + vm.DataObservation.Serialize().ToString(), "OK");
                }
            }

            await vm.SaveDefaultTraits(DataGrid.Columns);

            base.OnDisappearing();
        }

        private async Task LoadDefaultTraitSet()
        {
            //load local traits defined per trial, Only if this column doesn't exist then go for existing logic
            var traits = await vm.GetDefaultTraitsPerTrial(vm.TrialEZID);

            if (traits.Any())
            {
                await LoadColumnswithDataonGrid(traits);

            }
            else
            {
                var defaultTS = vm.TrialDetail.DefaultTraitSetID.ToString();

                if (defaultTS == "0")
                {
                    var defaultTraitSet = await vm.GetDefaultTraitSet(vm.CropCode);
                    if (defaultTraitSet != null)
                    {
                        defaultTS = defaultTraitSet.Fieldset;
                    }
                }

                if (defaultTS != "0")
                    TraitsetPicker.SelectedItem = vm.FieldSet.FirstOrDefault(x => x.FieldSetID == defaultTS);
            }
        }

        private async Task LoadColumnswithDataonGrid(List<Entities.Master.Trait> traits)
        {
            vm.TraitsInFieldset = traits;
            //service which will fetch all trait from database for selected fieldset id and create syncfusion column list in viewmodel.
            vm.FieldSetTraitCollumns = vm.GenerateColumns(traits);
            //add columns 
            foreach (var _columns in vm.FieldSetTraitCollumns)
            {
                var available = DataGrid.Columns.FirstOrDefault(x => x.MappingName == _columns.MappingName);
                if (available == null)
                    DataGrid.Columns.Add(_columns);
            }

            //Move Resistance columns to end
            MoveResistanceColumns();

            traitsOnGrid = traits;
            //load data now
            await vm.LoadDataOfSelectedTraits(traits);
        }

        protected override void OnSizeAllocated(double width, double height)
        {
            base.OnSizeAllocated(width, height); //must be called

            //Landscape
            if (width >= height)
            {
                VarietySearchBar.IsVisible = true;
            }
            //Portrait
            else
            {
                VarietySearchBar.IsVisible = false;
            }
        }

        private void hamburgerButton_Clicked(object sender, System.EventArgs e)
        {
            navigationDrawer.ToggleDrawer();
        }

        private void FixedColumnPicker_SelectedIndexChanged(object sender, System.EventArgs e)
        {
            DataGrid.FrozenColumnsCount = FixedColumnPicker.SelectedIndex + 2;
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
                    AddVarietyPopup.IsVisible = false;

                    //Display newly added variety in grid
                    vm.IndexedEzids[guid.ToString()] = vm.IndexedEzids.Count - 1;
                    dynamic item = new ExpandoObject();
                    item.VarietyName = vm.VarietyName;
                    item.FieldNumber = vm.ConsecutiveNumber;
                    item.EZID = guid.ToString();

                    //add all the columns for this new row to dictionary
                    var cols = vm.VarietyDetailList.FirstOrDefault() as IDictionary<string, object>;

                    if (cols != null)
                    {
                        foreach (var rr in cols)
                        {
                            if (!(item as IDictionary<string, object>).ContainsKey(rr.Key))
                                ((IDictionary<string, object>)item).Add(rr.Key, null);
                        }
                    }
                    else //if there is no row
                    {
                        foreach (var col in DataGrid.Columns)
                        {
                            if (!(item as IDictionary<string, object>).ContainsKey(col.MappingName))
                                ((IDictionary<string, object>)item).Add(col.MappingName, null);
                        }
                    }

                    vm.VarietyDetailList.Add(item);
                    vm.VarietyName = "";
                    vm.ConsecutiveNumber = null;
                    DataGrid.View.Refresh();

                    DependencyService.Get<IMessage>().LongTime("New variety added.");
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

        private async void TraitsetPicker_SelectedIndexChanged(object sender, EventArgs e)
        {
            var selectedVal = TraitsetPicker.SelectedItem as FieldSet;
            if (selectedVal != null)
            {
                vm.IsBusy = true;
                navigationDrawer.IsOpen = false;
                await Task.Delay(1);

                DataGrid.QueryCellStyle -= DataGrid_QueryCellStyle;
                //first remove columns if any trait columns is found
                foreach (var _columns in vm.FieldSetTraitCollumns)
                {
                    DataGrid.Columns.Remove(_columns);
                }
                DataGrid.QueryCellStyle += DataGrid_QueryCellStyle;

                var Traits = vm.GetTraitsInFieldSet(selectedVal.FieldSetID.ToInt32());
                vm.FieldSetTraitCollumns.Clear();
                //service which will fetch all trait from database for selected fieldset id and create syncfusion column list in viewmodel.
                vm.FieldSetTraitCollumns = vm.GenerateColumns(Traits);
                //add columns 
                foreach (var _columns in vm.FieldSetTraitCollumns)
                {
                    var available = DataGrid.Columns.FirstOrDefault(x => x.MappingName == _columns.MappingName);
                    if (available == null)
                        DataGrid.Columns.Add(_columns);
                }

                //Move Resistance columns to end
                MoveResistanceColumns();
                traitsOnGrid = vm.TraitsInFieldset;
                //load data now
                await vm.LoadDataOfSelectedTraits(vm.TraitsInFieldset);

                vm.IsBusy = false;
            }
        }

        private void MoveResistanceColumns()
        {
            var totalcolumns = DataGrid.Columns.Count();

            var resistColIndex = DataGrid.Columns.IndexOf(DataGrid.Columns.FirstOrDefault(o => o.MappingName == "ResistanceHR"));
            DataGrid.Columns.Move(resistColIndex, totalcolumns - 1);
            DataGrid.Columns.Move(resistColIndex, totalcolumns - 1);
            DataGrid.Columns.Move(resistColIndex, totalcolumns - 1);
        }

        private void btnChooseColumn_Clicked(object sender, EventArgs e)
        {
            ChooseColumnPopup.IsVisible = true;
            vm.CheckSelectedTraits();
            AllTraitsListView.ItemsSource = vm.TraitAll;
            SearchTraits.Text = "";
        }

        private void SearchTrait_OnTextChanged(object sender, TextChangedEventArgs e)
        {
            if (string.IsNullOrWhiteSpace(e.NewTextValue))
                AllTraitsListView.ItemsSource = vm.TraitAll;
            else
                AllTraitsListView.ItemsSource = vm.TraitAll.Where(x => x.ColumnLabel.ToLowerInvariant().Contains(e.NewTextValue.ToLowerInvariant()));
        }

        private void LblCloseChooseColumnPopup_Tapped(object sender, MR.Gestures.TapEventArgs e)
        {
            ChooseColumnPopup.IsVisible = false;
            SearchTraits.Text = "";
        }

        private async void bntChooseColOk_Clicked(object sender, EventArgs e)
        {
            vm.IsBusy = true;
            ChooseColumnPopup.IsVisible = false;
            navigationDrawer.IsOpen = false;
            await Task.Delay(1);

            var selectedTraits = vm.TraitAll.Where(x => x.Selected).ToList();


            vm.TraitsInFieldset = (from x in selectedTraits
                                   join y in vm.TraitsInFieldset on x.TraitID equals y.TraitID
                                   select y).ToList();

            DataGrid.QueryCellStyle -= DataGrid_QueryCellStyle;
            //first remove column for selected fieldset of grid from grid because there may be a chance where column from fieldset can be unselected
            foreach (var _columns in vm.FieldSetTraitCollumns)
            {
                DataGrid.Columns.Remove(_columns);
            }
            DataGrid.QueryCellStyle += DataGrid_QueryCellStyle;
            traitsOnGrid.Clear();
            //now get list of traits
            vm.FieldSetTraitCollumns = (from x in vm.FieldSetTraitCollumns
                                        join y in vm.TraitsInFieldset on x.MappingName equals y.TraitID.ToText()
                                        select x).ToList();
            //now add grid column in grid
            foreach (var _columns in vm.FieldSetTraitCollumns)
            {
                DataGrid.Columns.Add(_columns);
            }
            foreach (var t in vm.TraitsInFieldset)
            {
                traitsOnGrid.Add(t);
            }
            var excludetraitList = (from x in selectedTraits
                                    join y in vm.TraitsInFieldset on x.TraitID equals y.TraitID
                                    select x).ToList();

            vm.TraitsInChooseColumn = (selectedTraits.Except(excludetraitList).Select(x => new Entities.Master.Trait
            {
                BaseUnitImp = x.BaseUnitImp,
                BaseUnitMet = x.BaseUnitMet,
                ColumnLabel = x.ColumnLabel,
                DataType = x.DataType,
                Description = x.Description,
                DisplayFormat = x.DisplayFormat,
                Editor = x.Editor,
                ListOfValues = x.ListOfValues,
                MaxValue = x.MaxValue,
                MinValue = x.MinValue,
                Property = x.Property,
                ShowSum = x.ShowSum,
                TraitName = x.TraitName,
                TraitID = x.TraitID,
                TraitTypeID = x.TraitTypeID,
                Updatable = x.Updatable

            })).ToList();

            //remove some columns 
            foreach (var _columns in vm.ChooseColumnTraitCollumns)
            {
                DataGrid.Columns.Remove(_columns);
            }

            vm.ChooseColumnTraitCollumns = vm.GenerateColumns(vm.TraitsInChooseColumn);
            //add columns 
            foreach (var _columns in vm.ChooseColumnTraitCollumns)
            {
                DataGrid.Columns.Insert(2, _columns); //Add choos column selected columns to first
            }
            foreach (var t in vm.TraitsInChooseColumn)
            {
                traitsOnGrid.Add(t);
            }
            //Move Resistance columns to end
            MoveResistanceColumns();
            //load data now
            await vm.LoadDataOfSelectedTraits(vm.TraitsInChooseColumn);

            navigationDrawer.IsOpen = false;
            await SetBusyFalse();
            SearchTraits.Text = "";
        }

        private void btnChoosecolCancel_Clicked(object sender, EventArgs e)
        {
            ChooseColumnPopup.IsVisible = false;
            navigationDrawer.ToggleDrawer();

        }

        private void CancleButton_Clicked(object sender, EventArgs e)
        {
            vm.HistoryGridVisible = false;
            DisableUpdateMode();
            DataGrid.View.Refresh();
        }

        private async void HistoryGrid_SelectionChanged(object sender, GridSelectionChangedEventArgs e)
        {
            if (historyGrid.CurrentItem != null)
            {
                var rowdata = historyGrid.CurrentItem as ObservationApp;
                if (historyGrid.SelectedIndex == 1)
                    //load data now
                    await vm.LoadDataOfSelectedTraitSet("Latest_Obs");
                // await databinding.dataBinding(listTriat, MainDataGridView, "", "Latest_Obs");
                else
                    await vm.LoadDataOfSelectedTraitSet(rowdata.DateCreated + "|" + rowdata.UserIDCreated);
                vm.HistoryGridVisible = false;
                vm.ShowNormalObs = true;
                vm.HistoryDateVal = rowdata.UserIDCreated + ":" + rowdata.DateCreated;
            }
        }

        private async void HistoryButton_Clicked(object sender, EventArgs e)
        {
            historyGrid.ItemsSource = vm.TraitsInFieldset.Count > 0 ? await vm.GetHistoryList(vm.TraitsInFieldset.Select(l => l.TraitID).ToList()) : null;
            vm.HistoryGridVisible = true;
            vm.ShowUpdate = false;
            vm.ShowGallery = false;
            vm.ShowCamera = false;
            vm.ShowHamburger = false;
            vm.ShowNewTrial = false;
            vm.ShowAdd = false;
            vm.ShowNormalObs = true;
            vm.ShowHistory = false;
        }

        private void Label_Tapped(object sender, MR.Gestures.TapEventArgs e)
        {
            vm.HistoryGridVisible = false;
            DisableUpdateMode();
            DataGrid.View.Refresh();
        }

        private void TraitInfo_Clicked(object sender, EventArgs e)
        {
            try
            {
                vm.TraitInfoPopupHeight = 300;
                var trait = vm.TraitsInCrop.Where(x => x.TraitID.ToText() == vm.SelectedColumnName).FirstOrDefault();
                if (trait == null) return;

                var left = 0;
                var top = 0;
                var traitname = trait.TraitName;
                var datatype = trait.DataType.ToUpper();
                var minvalue = trait.MinValue.ToString();
                var maxvalue = trait.MaxValue.ToString();
                var description = trait.Description;

                PopupGrid.RowDefinitions.Clear();
                PopupGrid.Children.Clear();

                //Trait name
                PopupGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Auto) });
                PopupGrid.Children.Add(new Label { Text = "Trait name", TextColor = Color.Black, FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) + 2 }, left, top);
                top++;
                PopupGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Auto) });
                PopupGrid.Children.Add(new Label { Text = traitname, TextColor = Color.FromHex("#555"), FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) - 1, Margin = new Thickness(0, 0, 0, 10) }, left, top);
                top++;

                if ((datatype?.ToLower() == "i" || datatype?.ToLower() == "a") && !string.IsNullOrEmpty(minvalue))
                {
                    //Min value
                    PopupGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Auto) });
                    PopupGrid.Children.Add(new Label { Text = "Min value", TextColor = Color.Black, FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) + 2 }, left, top);
                    top++;
                    PopupGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Auto) });
                    PopupGrid.Children.Add(new Label { Text = minvalue, TextColor = Color.FromHex("#555"), FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) - 1, Margin = new Thickness(0, 0, 0, 10) }, left, top);
                    top++;

                    //Max value
                    PopupGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Auto) });
                    PopupGrid.Children.Add(new Label { Text = "Max value", TextColor = Color.Black, FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) + 2 }, left, top);
                    top++;
                    PopupGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Auto) });
                    PopupGrid.Children.Add(new Label { Text = maxvalue, TextColor = Color.FromHex("#555"), FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) - 1, Margin = new Thickness(0, 0, 0, 10) }, left, top);
                    top++;

                    vm.TraitInfoPopupHeight = 400;
                }

                ////Description
                PopupGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Auto) });
                PopupGrid.Children.Add(new Label { Text = "Description", TextColor = Color.Black, FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) + 2 }, left, top);
                top++;
                PopupGrid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Auto) });
                PopupGrid.Children.Add(new Label { Text = description, TextColor = Color.FromHex("#555"), FontSize = Device.GetNamedSize(NamedSize.Medium, typeof(Label)) - 1, Margin = new Thickness(0, 0, 0, 10) }, left, top);
                top++;

                vm.TraitInfoVisible = true;

            }
            catch (Exception)
            {
            }
        }

        private void Update_Clicked(object sender, EventArgs e)
        {
            EnableUpdateMode();
        }

        private async void Save_Clicked(object sender, EventArgs e)
        {
            //fire endedit for last cell 
            try
            {
                this.DataGrid.EndEdit();
            }
            catch
            {
            }

            if (vm.DataObservation.Count == 0)
                DisableUpdateMode();
            else
            {
                if (await vm.SaveToDB())
                {
                    var _trialService = new TrialService();
                    _trialService.UpdateTrialStatus(vm.TrialEZID);
                    vm.DataObservation.Clear();
                    vm.OldObservation.Clear();
                    await DisplayAlert("Info", "Observation data saved successfully", "OK");

                    DisableUpdateMode();
                    DataGrid.View.Refresh();
                }
                else
                    await DisplayAlert("Error", "Observation data couldn't be saved for the data: " + vm.DataObservation.Serialize().ToString(), "OK");

            }
        }

        private async void Cancel_Clicked(object sender, EventArgs e)
        {
            //Commit changes from last cell : avoid breaking so put it on try catch block
            try
            {
                this.DataGrid.EndEdit();
            }
            catch
            {
            }

            if (vm.DataObservation.Count > 0)
            {
                var action = await DisplayAlert("Revert?", "Are you sure to revert changes?", "Yes", "No");
                if (action)
                {
                    vm.DataObservation.Clear();
                    DisableUpdateMode();

                    //Reset data
                    foreach (var data in vm.OldObservation)
                    {
                        var item = vm.VarietyDetailList.Where(x => x.EZID == data.EZID).FirstOrDefault() as IDictionary<string, object>;
                        if (data.DataType.ToText().ToLower() == "d")
                        {
                            var dateVal = new DateTime();
                            if (DateTime.TryParse(data.ObsValue, out dateVal))
                                item[data.TraitID.ToText()] = dateVal;
                        }
                        else
                            item[data.TraitID.ToString()] = data.ObsValue == "" ? null : data.ObsValue;

                        //Remove cell coloring
                        var ObsData = vm.ModifiedObsList.LastOrDefault(o => o.EZID == data.EZID && o.TraitID == data.TraitID);
                        vm.ModifiedObsList.Remove(ObsData);
                    }

                    DataGrid.View.Refresh();
                }
            }
            else
                DisableUpdateMode();
        }

        private void DataGrid_CurrentCellActivating(object sender, CurrentCellActivatingEventArgs e)
        {
            if (WebserviceTasks.CellNotValidated)
            {
                DataGrid.CurrentCellBeginEdit -= DataGrid_CurrentCellBeginEdit;
                DataGrid.CurrentCellEndEdit -= DataGrid_CurrentCellEndEdit;

                DataGrid.BeginEdit(e.PreviousRowColumnIndex.RowIndex, e.PreviousRowColumnIndex.ColumnIndex);

                DataGrid.CurrentCellBeginEdit += DataGrid_CurrentCellBeginEdit;
                DataGrid.CurrentCellEndEdit += DataGrid_CurrentCellEndEdit;
                e.Cancel = true;
            }
        }

        private async void DataGrid_CurrentCellBeginEdit(object sender, GridCurrentCellBeginEditEventArgs e)
        {
            vm.SelectedCellValue = null;
            vm.LastSelectedColumn = vm.SelectedColumnName;
            vm.SelectedColumnName = e.Column.MappingName;
            vm.LastSelectedRowindex = vm.SelectedRowindex;
            vm.SelectedRowindex = e.RowColumnIndex.RowIndex;

            var rowdata = DataGrid.SelectedItem;
            vm.SelectedCellOldValue = DataGrid.GetCellValue(rowdata, vm.SelectedColumnName).ToText();

            var columninfo = DataGrid.Columns[e.RowColumnIndex.ColumnIndex];
            var trait = vm.TraitsInCrop.Where(x => x.TraitID.ToText() == columninfo.MappingName).FirstOrDefault();

            if (trait != null && trait.Editor)
            {
                var unit = UnitOfMeasure.SystemUoM == "Imperial" ? trait.BaseUnitImp ?? "" : trait.BaseUnitMet ?? "";
                unit = string.IsNullOrEmpty(unit) ? "" : " (" + unit + ") ";
                var columnLabel = trait.ColumnLabel + unit;

                vm.TraitEditorPopupVisible = true;
                vm.EditorReadOnly = false;
                vm.EditorColumnLabel = columnLabel;
                vm.TraitEditorText = vm.SelectedCellOldValue;

                //needs time to render control
                await Task.Delay(200);
                TraitEditor.Focus();
            }
        }

        private void CustomeDatePicker_SelectionChanged(object sender, Syncfusion.SfPicker.XForms.SelectionChangedEventArgs e)
        {

        }

        private void DataGrid_CurrentCellDropDownSelectionChanged(object sender, CurrentCellDropDownSelectionChangedEventArgs e)
        {
            ////fire endcall event for gridpicker control
            ////this.DataGrid.EndEdit();
            //var rowdata = DataGrid.SelectedItem;
            //var oldvalue = DataGrid.GetCellValue(rowdata, vm.SelectedColumnName).ToText();

            //if (e.SelectedItem is TraitValue item)
            //{
            //    var newVal = item.TraitValueCode;
            //    vm.SelectedCellValue = newVal;

            //    CreateObservationData(oldvalue, newVal);
            //}

            ////go to next cell
            //await NavigateNextCell(e.RowColumnIndex.RowIndex, e.RowColumnIndex.ColumnIndex);
        }

        private async void DataGrid_CurrentCellEndEdit(object sender, GridCurrentCellEndEditEventArgs e)
        {
            try
            {
                WebserviceTasks.CellNotValidated = false;
                var colindex = e.RowColumnIndex.ColumnIndex;
                var rowindex = e.RowColumnIndex.RowIndex;
                var oldValuePicker = vm.SelectedCellOldValue;
                vm.SelectedCellValue = e.NewValue.ToText();
                bool isNullEntry = false;
                var columninfo = DataGrid.Columns[e.RowColumnIndex.ColumnIndex];
                var trait = vm.TraitsInCrop.Where(x => x.TraitID.ToText() == columninfo.MappingName).FirstOrDefault();


                if (trait.ListOfValues)
                {
                    //Strange behaviour for combobox
                    var oldvalue = e.NewValue.ToText();
                    var newvalue = e.OldValue.ToText();
                    // vm.SelectedCellValue = newvalue;
                    if (newvalue == "" && (trait.DataType.ToLower() == "i" || trait.DataType.ToLower() == "a"))
                        isNullEntry = true;
                    CreateObservationData(oldvalue, newvalue, isNullEntry);
                }
                else if (trait.Editor)
                {
                    //Strange behaviour for combobox
                    var oldvalue = e.NewValue.ToText();
                    var newvalue = e.OldValue.ToText();

                    ////sometimes new value is not reflected
                    //if (e.OldValue == null)
                    //    newvalue = vm.TraitEditorText;

                    vm.SelectedCellValue = newvalue;

                    CreateObservationData(oldvalue, newvalue, isNullEntry);
                }
                else if (trait.DataType.ToText().ToLower() == "d")
                {
                    var selectedItem = DataGrid.SelectedItem as IDictionary<string, object>;
                    if (selectedItem != null)
                    {
                        var value = selectedItem[vm.SelectedColumnName];
                        if (!string.IsNullOrWhiteSpace(value.ToText()))
                            CreateObservationData(vm.SelectedCellOldValue, value.ToText(), isNullEntry);
                    }
                }
                else
                {
                    var validationMessge = vm.ValidateTrait(trait, vm.SelectedCellValue);
                    if (!string.IsNullOrWhiteSpace(validationMessge))
                    {
                        //error message display logic and make current cell focus and cancel changed value
                        // var colName = columninfo.HeaderText;
                        // validationMessge =  validationMessge;
                        e.Cancel = true;
                        //await Application.Current.MainPage.DisplayAlert("Validation", validationMessge, "OK");
                        DependencyService.Get<IMessage>().LongTime(validationMessge);

                        WebserviceTasks.CellNotValidated = true;
                        await NavigateNextCell(1, 0);

                        return;
                    }
                    else
                    {
                        CreateObservationData(e.OldValue.ToText(), vm.SelectedCellValue, isNullEntry);
                    }
                }

                //leave focus on current cell before focusing on next cell
                //DataGrid.CurrentCellEndEdit -= DataGrid_CurrentCellEndEdit;
                //this.DataGrid.EndEdit();
                //var grid = sender as SfDataGrid;
                //var row = grid.GetRowGenerator().Items.FirstOrDefault(x => x.IsEditing);
                //await Task.Delay(200);
                //row.UpdateRow();
                //DataGrid.CurrentCellEndEdit += DataGrid_CurrentCellEndEdit;

                //go to next cell
                if (WebserviceTasks.KeyboardNextClicked)
                {
                    WebserviceTasks.KeyboardNextClicked = false;
                    await NavigateNextCell(rowindex, colindex);
                }
            }
            catch (Exception)
            {

            }

        }

        private async Task NavigateNextCell(int rowindex, int colindex)
        {
            if (vm.UpdateModeText.ToLower() == "horizontal")
            {
                colindex++;
                DataGrid.ScrollToColumnIndex(colindex, true, ScrollToPosition.MakeVisible); // Bring cell to view first
            }
            else
            {
                rowindex++;
                DataGrid.ScrollToRowIndex(rowindex, true, ScrollToPosition.MakeVisible); // Bring cell to view first
            }

            // To load combobox/date picker there should be delay
            await Task.Delay(400);
            DataGrid.BeginEdit(rowindex, colindex);
        }


        private void CreateObservationData(string oldvalue, string newvalue, bool isNullEntry)
        {
            var row = DataGrid.SelectedItem as IDictionary<string, object>;
            var ezid = row["EZID"].ToString();

            var trait = vm.TraitAll.FirstOrDefault(o => o.TraitID.ToString() == vm.SelectedColumnName);

            if (string.Equals(oldvalue, newvalue)) return;

            //Create Old ObservationList
            if (!vm.OldObservation.Any(o => o.EZID == ezid && o.TraitID == trait.TraitID))
                vm.OldObservation.Add(new ObservationAppHistory
                {
                    EZID = ezid,
                    TraitID = trait.TraitID,
                    ObsValue = oldvalue,
                    DataType = trait.DataType
                });


            var observation = new ObservationAppLookup()
            {
                EZID = ezid,
                TraitID = trait.TraitID,
                //DateCreated = string.IsNullOrEmpty(vm.ObsDateVal) ? DateTime.UtcNow.Date.ToString("yyyy-MM-dd") : vm.ObsDateVal,
                DateCreated = string.IsNullOrEmpty(vm.ObsDateVal) ? DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss") : vm.ObsDateVal,
                DateUpdated = string.IsNullOrEmpty(vm.ObsDateVal) ? DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss") : vm.ObsDateVal,
                UserIDCreated = "user",
                UserIDUpdated = "user",
                Modified = true,
                UoMCode = trait.UoMCode,
                IsNullEntry = isNullEntry
            };

            //fill observation value
            switch (trait.DataType.ToLower())
            {
                case "c":
                    observation.ObsValueChar = newvalue;
                    break;

                case "i":
                    int.TryParse(newvalue, out int intval);
                    observation.ObsValueInt = intval;
                    break;

                case "a":
                    decimal.TryParse(newvalue, out decimal decval);
                    observation.ObsValueDec = decval;
                    break;

                case "d":
                    DateTime.TryParse(newvalue, out DateTime dateval);
                    observation.ObsValueDate = dateval.ToString("yyyy-MM-ddTHH:mm:ss");
                    break;

                default:
                    break;
            }

            vm.DataObservation.Add(observation);
            vm.ModifiedObsList.Add(observation); //For cell colouring
        }

        private void EnableUpdateMode()
        {
            EnableUpdateModeToolbars();
            //vm.ShowUpdateNav = true;
            vm.RowindexBeforeUpdate = DataGrid.SelectedIndex;

            DataGrid.AllowEditing = true;
            DataGrid.NavigationMode = NavigationMode.Cell;
            DataGrid.SelectionMode = Syncfusion.SfDataGrid.XForms.SelectionMode.Single;
            DataGrid.EditorSelectionBehavior = EditorSelectionBehavior.SelectAll;
            //Clear selection using selection controller
            DataGrid.SelectionController.DataGrid.ClearSelection();
        }

        private void EnableUpdateModeToolbars()
        {
            vm.ShowObsDatePicker = true;
            vm.ShowObsDate = true;
            vm.ShowNewTrial = false;
            vm.ShowHistory = false;
            vm.ShowAdd = false;
            vm.ShowUpdate = false;
            vm.ShowGallery = false;
            vm.ShowCamera = false;
            vm.ShowHamburger = false;
            vm.ShowUpdateMode = true;
            vm.ShowInfo = true;
            vm.ShowSave = true;
            vm.ShowCancel = true;
        }

        private void DisableUpdateMode()
        {
            DisableUpdateModeToolbars();

            DataGrid.AllowEditing = false;
            DataGrid.NavigationMode = NavigationMode.Row;
            DataGrid.SelectedIndex = vm.RowindexBeforeUpdate;
        }

        private void DisableUpdateModeToolbars()
        {
            vm.ShowNewTrial = true;
            vm.ShowHistory = true;
            vm.ShowAdd = true;
            vm.ShowUpdate = true;
            vm.ShowGallery = true;

            //only show camera when row is selected
            if (vm.RowindexBeforeUpdate != 0)
                vm.ShowCamera = true;
            else
                vm.ShowCamera = false;

            vm.ShowHamburger = true;
            vm.ShowUpdateMode = false;
            vm.ShowInfo = false;
            vm.ShowSave = false;
            vm.ShowCancel = false;
            vm.ShowNormalObs = false;
            vm.ShowObsDate = false;
            vm.ShowObsDatePicker = false;
        }

        private void ObsDate_Clicked(object sender, EventArgs e)
        {
            //fire endedit for last cell 
            try
            {
                this.DataGrid.EndEdit();
            }
            catch
            {
            }
            ObsDatePicker.Focus();
        }

        private async void Normal_Clicked(object sender, EventArgs e)
        {
            vm.HistoryGridVisible = false;
            DisableUpdateMode();

            var list = new List<Entities.Master.Trait>();
            list.AddRange(vm.TraitsInFieldset);
            list.AddRange(vm.TraitsInChooseColumn);
            traitsOnGrid = list;
            await vm.LoadDataOfSelectedTraits(list);
        }

        private void UpdateNav_Clicked(object sender, EventArgs e)
        {

        }

        private async void ObsDatePicker_DateSelected(object sender, DateChangedEventArgs e)
        {
            vm.ObsDateVal = (e.NewDate).Date.ToString("yyyy-MM-dd");
            if (vm.DataObservation.Count > 0 && Convert.ToDateTime(e.NewDate).Date != DateTime.Today.Date)
            {
                var action = await DisplayAlert("ObservationDate?", "Change Observation Date to current selected date.", "Yes", "No");
                if (action)
                {
                    vm.ObsDateVal = (e.NewDate).Date.ToString("yyyy-MM-dd");
                    vm.UpdateObservationDate();
                }
            }
        }

        private async void DataGrid_GridLongPressed(object sender, GridLongPressedEventArgs e)
        {
            var selectedRow = e.RowData as IDictionary<string, object>;
            var trialEntryAppService = new TrialEntryAppService();
            if (selectedRow != null)
            {
                var varietyId = selectedRow["EZID"].ToText();

                var isNewRecord = await vm.CheckIsNewRecordAsync(varietyId);
                var hasObservationData = await vm.CheckHasObeservationDataAsync(varietyId);

                if (App.ReleaseHideVariety && (!isNewRecord || hasObservationData))
                {
                    var value = (await DisplayAlert("Hide variety", "Are you sure you want to hide this variety?\nOnce hidden you won't be able to unhide the variety from the app.", "YES", "NO"));
                    if (value)
                    {
                        if (await trialEntryAppService.HideVarietyAsync(varietyId, vm.TrialEZID))
                        {
                            DataGrid.SelectedItem = null;
                            vm.VarietyDetailList.Remove(selectedRow);
                        }
                    }
                }
                else
                {
                    var value = await DisplayAlert("Delete variety", "Do you really want to delete this variety?", "YES", "NO");
                    if (value)
                    {
                        //var grid = sender as MR.Gestures.Grid;
                        //var varietyId = (grid.Children[4] as Label)?.Text;


                        if (await vm.DeleteTrialEntry(varietyId))
                        {
                            //delete variety logic
                            if (await trialEntryAppService.DeleteVarietyAsync(varietyId))
                            {
                                //Remove deleted variety from grid
                                DataGrid.SelectedItem = null;
                                vm.VarietyDetailList.Remove(selectedRow);
                            }
                        }
                        else
                            await DisplayAlert("Information", "Cannot delete this variety. This is not a new variety or already has observation data !", "OK");
                    }
                }
            }
        }

            private void TraitInfoPopupOk_Clicked(object sender, EventArgs e)
            {
                vm.TraitInfoVisible = false;
            }

            private void BtnDefaultTraitSet_Clicked(object sender, EventArgs e)
            {
                var selectedItem = TraitsetPicker.SelectedItem as FieldSet;
                if (selectedItem != null)
                {
                    int.TryParse(selectedItem.FieldSetID, out int fieldSetID);
                    vm.SaveDefaultTraitSet(vm.CropCode, fieldSetID);

                    DependencyService.Get<IMessage>().LongTime("Default traitset saved for crop " + vm.CropCode);
                }

            }

            private void FixedRowPicker_SelectedIndexChanged(object sender, EventArgs e)
            {
                int.TryParse((string)FixedRowPicker.SelectedItem, out int value);
                DataGrid.FrozenRowsCount = value;
            }

            private void DataGrid_QueryCellStyle(object sender, QueryCellStyleEventArgs e)
            {
                if (vm.ShowNormalObs)
                {
                    if (e.Style.BackgroundColor != Color.Green && e.CellValue == null)
                    {
                        e.Style.ForegroundColor = Color.Transparent;
                        e.Style.CellStylePreference = StylePreference.Selection;
                    }
                    e.Handled = true;
                }
                else
                {
                    var colname = e.Column.MappingName;

                    //only if there is value and trait column
                    if (int.TryParse(colname, out int traitId) && vm.ModifiedObsList != null)
                    {
                        var row = e.RowData as IDictionary<string, object>;
                        var ezid = row["EZID"].ToString();
                        if (vm.ModifiedObsList.Where(o => o.EZID == ezid && o.TraitID == traitId).Any())
                        {
                            e.Style.BackgroundColor = Color.Green;
                            e.Style.ForegroundColor = Color.White;
                            e.Style.CellStylePreference = StylePreference.StyleAndSelection;
                            e.Handled = true;
                        }
                        else
                        {
                            var trait = vm.TraitAll.FirstOrDefault(o => o.TraitID == traitId);
                            if (trait.DataType.ToLower() == "d" && e.CellValue != null)
                            {
                                e.Style.ForegroundColor = Color.Transparent;
                                e.Style.CellStylePreference = StylePreference.StyleAndSelection;

                                e.Handled = true;
                            }

                            //if ((trait.DataType.ToLower() == "i" || trait.DataType.ToLower() == "a") && e.CellValue == null)
                            //{
                            //    e.Style.ForegroundColor = Color.Transparent;
                            //    e.Style.CellStylePreference = StylePreference.StyleAndSelection;

                            //    e.Handled = true;
                            //}
                        }

                    }
                    if (e.Style.BackgroundColor != Color.Green && e.CellValue == null)
                    {
                        e.Style.ForegroundColor = Color.Transparent;
                        e.Style.CellStylePreference = StylePreference.StyleAndSelection;

                        e.Handled = true;
                    }
                }
            }

            private void DataGrid_QueryRowStyle(object sender, QueryRowStyleEventArgs e)
            {
                var row = e.RowData as IDictionary<string, object>;
                var ezid = row["EZID"]?.ToString();

                if (!int.TryParse(ezid, out int id))
                {
                    e.Style.BackgroundColor = Color.FromHex("#FFFFCE94");
                    e.Style.ConditionalStylingPreference = StylePreference.StyleAndSelection;
                    e.Handled = true;
                }

            }

            private void UpdateMode_Clicked(object sender, EventArgs e)
            {
                if (!(sender is HideableToolbarItem control)) return;
                if (control.Text.ToLower() == "horizontal")
                {
                    vm.UpdateModeIcon = ImageSource.FromFile("Assets/verticle.png");
                    vm.UpdateModeText = "Verticle";
                }
                else
                {
                    vm.UpdateModeIcon = ImageSource.FromFile("Assets/horizontal.png");
                    vm.UpdateModeText = "Horizontal";
                }
            }

            private void VarietySearchBar_Unfocused(object sender, FocusEventArgs e)
            {
                var searchbar = sender as SearchBar;
                var text = searchbar.Text;

                if (!(vm.VarietyDetailList.Where(x => x.FieldNumber == text || x.VarietyName == text).FirstOrDefault() is IDictionary<string, object> dt)) return;
                var ezid = dt["EZID"].ToText();
                var rowindex = vm.IndexedEzids.FirstOrDefault(x => x.Key == ezid).Value;

                this.DataGrid.SelectedIndex = rowindex + 1;
                this.DataGrid.ScrollToRowIndex(rowindex + 1);
            }

            private void EntryNumber_Completed(object sender, EventArgs e)
            {
                EntryVarietyName.Focus();
            }

            private void EntryVarietyName_Completed(object sender, EventArgs e)
            {
                EntryVarietyName.Unfocus();
            }


            //Filter

            void OnFilterTextChanged(object sender, TextChangedEventArgs e)
            {
                if (e.NewTextValue == null)
                    vm.FilterText = "";
                else
                    vm.FilterText = e.NewTextValue;
            }

            void OnFilterChanged()
            {
                if (DataGrid.View != null)
                {
                    this.DataGrid.View.Filter = vm.FilerRecords;
                    this.DataGrid.View.RefreshFilter();
                }
            }

            private void LblClosePopupTE_Tapped(object sender, MR.Gestures.TapEventArgs e)
            {
                TraitEditor.Unfocus();
                DataGrid.CancelEdit();
                vm.TraitEditorPopupVisible = false;
            }

            private void TraitEditorPopupOk_Clicked(object sender, EventArgs e)
            {
                if (!vm.EditorReadOnly)
                {
                    var selectedItem = DataGrid.CurrentItem as IDictionary<string, object>;
                    var oldValue = selectedItem[vm.SelectedColumnName];

                    selectedItem[vm.SelectedColumnName] = vm.TraitEditorText;
                    WebserviceTasks.KeyboardNextClicked = true;

                    DataGrid.EndEdit();
                    //DataGrid.View.Refresh();
                }
                vm.TraitEditorText = "";
                vm.TraitEditorPopupVisible = false;
            }

            private void DataGrid_GridTapped(object sender, GridTappedEventArgs e)
            {
                if (!DataGrid.AllowEditing)
                {
                    var rowdata = e.RowData;
                    var columninfo = DataGrid.Columns[e.RowColumnIndex.ColumnIndex];
                    var value = DataGrid.GetCellValue(rowdata, columninfo.MappingName).ToText();
                    var trait = vm.TraitsInCrop.Where(x => x.TraitID.ToText() == columninfo.MappingName).FirstOrDefault();

                    if (trait.Editor)
                    {
                        var unit = UnitOfMeasure.SystemUoM == "Imperial" ? trait.BaseUnitImp ?? "" : trait.BaseUnitMet ?? "";
                        unit = string.IsNullOrEmpty(unit) ? "" : " (" + unit + ") ";
                        var columnLabel = trait.ColumnLabel + unit;

                        vm.TraitEditorPopupVisible = true;
                        vm.EditorReadOnly = true;
                        vm.EditorColumnLabel = columnLabel;
                        vm.TraitEditorText = value;
                    }
                }
            }

            private async void Picture_Clicked(object sender, EventArgs e)
            {
                var selectedItem = DataGrid.SelectedItem as IDictionary<string, object>;
                if (selectedItem == null)
                {
                    await DisplayAlert("Alert", "No trial entry selected.", "Ok");
                    return;
                }

                PhotoUploadPopup.IsVisible = true;
            }

            private void downloadButton_Clicked(object sender, EventArgs e)
            {
                //try
                //{
                //    PhotoUploadPopup.IsVisible = false;
                //    var resultSegment = containerClient.GetBlobs(prefix: $"{trialEzid.ToString()}/");
                //    foreach (var blobPage in resultSegment)
                //    {
                //        var blockBlobImageClient = containerClient.GetBlobClient(blobPage.Name);
                //        //var imgStream = new MemoryStream();
                //        //var tt =  blockBlobImageClient.DownloadTo(imgStream);
                //        // using (var fs = new FileStream(Environment.GetFolderPath(Environment.SpecialFolder.Personal), FileAccess.ReadWrite))
                //        var path = Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.Personal), blobPage.Name.Split('/')[1]);
                //        using (var fileStream = System.IO.File.Create(path))
                //        {
                //            blockBlobImageClient.DownloadTo(fileStream);
                //            ShowImages.Children.Add(
                //            new Image
                //            {
                //                HeightRequest = 150,
                //                WidthRequest = 300,
                //                Source = path
                //            });
                //        }
                //        //var path = "Xamarin/" + blobPage.Name.Split('/')[1];
                //        //if (!File.Exists(path))
                //        //    File.Create(path,10000,FileOptions.None);
                //        //using (var fileStream = File.OpenWrite(path))
                //        //{
                //        //    blockBlobImageClient.DownloadTo(fileStream);

                //        // }
                //    }
                //    showImagePopup.IsVisible = true;
                //}
                //catch (Exception ec)
                //{
                //}
            }
            private void DataGrid_SelectionChanged(object sender, GridSelectionChangedEventArgs e)
            {
                //Display camera only on display mode
                if (!DataGrid.AllowEditing)
                {
                    vm.ShowHamburger = false;
                    vm.ShowCamera = true;
                    vm.ShowHamburger = true;
                }

                var selectedItem = DataGrid.CurrentItem as IDictionary<string, object>;
                if (selectedItem != null)
                {
                    trialEntryEzid = selectedItem["EZID"].ToText();
                }
            }

            private async void Gallery_Clicked(object sender, EventArgs e)
            {

                await vm.ShowImages(trialEzid.ToString());
            }

            private async void LblCamera_Tapped(object sender, MR.Gestures.TapEventArgs e)
            {
                try
                {

                    var selectedItem = DataGrid.SelectedItem as IDictionary<string, object>;
                    var fieldnumber = selectedItem["FieldNumber"].ToText();
                    var varietyName = selectedItem["VarietyName"].ToText();

                    //var tempPath = Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.Personal), "tempTrialImg.jpg");
                    PhotoUploadPopup.IsVisible = false;
                    vm.PictureLocation = "";
                    TraitListForImage.IsVisible = false;
                    TraitListForImage.SelectedIndexChanged -= TraitListForImage_SelectedIndexChanged;
                    TraitListForImage.SelectedItem = null;
                    TraitListForImage.SelectedIndexChanged += TraitListForImage_SelectedIndexChanged;
                    //var guid = Guid.NewGuid(); 
                    var guid = DateTime.Now.ToString("yyyyMMddHHmmssfff");
                    var fileName = guid + "_" + fieldnumber.Trim().Replace(" ", "-") + "_" + varietyName.Trim().Replace(" ", "-") + ".jpg";
                    var path = Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.Personal), "TrialAppPictures", trialEzid.ToString(), trialEntryEzid);
                    //var path = Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.Personal), "tempTrialImg.jpg");
                    var photo = await CrossMedia.Current.TakePhotoAsync(new StoreCameraMediaOptions()
                    {
                        DefaultCamera = CameraDevice.Rear,
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
                            TraitListForImage.IsVisible = true;
                            //if (!traitsOnGrid.Exists(x => x.TraitName.ToText() == "No Trait"))
                            //{
                            //    //traitsOnGrid.Add(new Entities.Master.Trait
                            //    //{
                            //    //    ColumnLabel = "No Trait",
                            //    //    TraitName = "No Trait"
                            //    //});
                            //    TraitListForImage.ItemsSource = null;
                            //    TraitListForImage.ItemsSource = traitsOnGrid;
                            //}
                            TraitListForImage.ItemsSource = null;
                            TraitListForImage.ItemsSource = traitsOnGrid;
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
                //PhotoUploadPopup.IsVisible = false;
                //TraitListForImage.IsVisible = false;
                //TraitListForImage.SelectedIndexChanged -= TraitListForImage_SelectedIndexChanged;
                //TraitListForImage.SelectedItem = null;
                //TraitListForImage.SelectedIndexChanged += TraitListForImage_SelectedIndexChanged;
                //await vm.UploadPhotoFromGalleryAsync();


                PhotoUploadPopup.IsVisible = false;
                TraitListForImage.SelectedIndexChanged -= TraitListForImage_SelectedIndexChanged;
                TraitListForImage.SelectedItem = null;
                TraitListForImage.SelectedIndexChanged += TraitListForImage_SelectedIndexChanged;
                await vm.UploadPhotoFromGalleryAsync();
                if (vm.ImagePrevPopup)
                {
                    TraitListForImage.IsVisible = true;
                    //if (!traitsOnGrid.Exists(x => x.TraitName.ToText() == "No Trait"))
                    //{
                    //    traitsOnGrid.Add(new Entities.Master.Trait
                    //    {
                    //        ColumnLabel = "No Trait",
                    //        TraitName = "No Trait"
                    //    });
                    //    TraitListForImage.ItemsSource = null;
                    //    TraitListForImage.ItemsSource = traitsOnGrid;
                    //}
                    TraitListForImage.ItemsSource = null;
                    TraitListForImage.ItemsSource = traitsOnGrid;
                    TraitListForImage.Focus();
                }

            }

            private void CloseAddImage_Tapped(object sender, MR.Gestures.TapEventArgs e)
            {
                PhotoUploadPopup.IsVisible = false;
            }

            private async void btnConfirm_Clicked(object sender, EventArgs e)
            {
                if (TraitListForImage.SelectedItem == null)
                {
                    await DisplayAlert("Error", "Please select trait before saving picture!", "OK");
                    TraitListForImage.Focus();
                    return;
                }

                var selectedItem = DataGrid.SelectedItem as IDictionary<string, object>;
                var selectedTraitID = "";
                var selectedTraitName = "";

                var fieldnumber = selectedItem["FieldNumber"].ToText();
                var varietyName = selectedItem["VarietyName"].ToText();

                var selectedpickerItem = TraitListForImage.SelectedItem as Entities.Master.Trait;
                if (selectedItem != null)
                {
                    selectedTraitID = selectedpickerItem.TraitID.ToText();
                    selectedTraitName = selectedpickerItem.ColumnLabel;
                }
                await vm.UploadPictureConfirmed(trialEzid, trialEntryEzid, fieldnumber.Trim().Replace(" ", "-"), varietyName.Trim().Replace(" ", "-"), selectedTraitID, selectedTraitName.Replace("%", ""));

            }

            private void btnNo_clicked(object sender, EventArgs e)
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

            private async void TraitListForImage_SelectedIndexChanged(object sender, EventArgs e)
            {
                //var selectedItem = DataGrid.SelectedItem as IDictionary<string, object>;
                //var selectedTraitID = "";
                //var selectedTraitName = "";
                //var picker = sender as Picker;

                //var fieldnumber = selectedItem["FieldNumber"].ToText();
                //var varietyName = selectedItem["VarietyName"].ToText();

                //var selectedpickerItem = picker.SelectedItem as Entities.Master.Trait;
                //if (selectedItem != null && selectedpickerItem.TraitName.ToText().ToLower() != "no trait")
                //{
                //    selectedTraitID = selectedpickerItem.TraitID.ToText();
                //    selectedTraitName = selectedpickerItem.ColumnLabel;
                //}
                //await vm.UploadPictureConfirmed(trialEzid, trialEntryEzid, fieldnumber.Trim().Replace(" ", "-"), varietyName.Trim().Replace(" ", "-"), selectedTraitID, selectedTraitName);

                btnConfirm.IsVisible = true;
            }
        }

        internal class CustomTextViewRenderer : GridCellTextViewRenderer
        {
            SfDataGrid grid;
            private bool commitcellCalled;

            public CustomTextViewRenderer(SfDataGrid dataGrid)
            {
                grid = dataGrid;
            }

            protected override SfEntry OnCreateEditUIView()
            {
                var view = new CustomSfEntry(grid);
                return view;
            }

            public async override void CommitCellValue(bool isNewValue)
            {
                var newValue = this.GetControlValue();

                if (commitcellCalled && newValue == null) return;
                commitcellCalled = true;

                var selectedItem = this.grid.SelectedItem as IDictionary<string, object>;
                var bindingContext = this.grid.BindingContext as VarietyPageTabletViewModel;

                var dataColumn = (this.CurrentCellElement as GridCell).DataColumn;

                //For editor type trait updated value is present in view model
                var trait = bindingContext.TraitAll.FirstOrDefault(o => o.TraitID.ToString() == bindingContext.SelectedColumnName);
                if (trait.Editor)
                    newValue = bindingContext.TraitEditorText;

                selectedItem[bindingContext.SelectedColumnName] = newValue;

                await Task.Delay(100);
                this.UpdateCellValue(dataColumn);
                this.RefreshDisplayValue(dataColumn);
            }

            protected override void OnUpdateCellValue(DataColumnBase dataColumn)
            {
                var bindingContext = this.grid.BindingContext as VarietyPageTabletViewModel;
                var cellValue = SfDataGridHelpers.GetCellValue(this.grid, dataColumn.RowData, bindingContext.SelectedColumnName);
                base.OnUpdateCellValue(dataColumn);
            }

            internal class CustomSfEntry : SfEntry
            {
                SfDataGrid dataGrid;
                public CustomSfEntry(SfDataGrid sfDataGrid)
                {
                    dataGrid = sfDataGrid;
                    this.ReturnType = ReturnType.Next;
                    this.Completed += CustomSfEntry_Completed;
                    this.Focused += CustomSfEntry_Focused;
                    this.Unfocused += CustomSfEntry_Unfocused;
                }

                private void CustomSfEntry_Unfocused(object sender, FocusEventArgs e)
                {
                }

                private void CustomSfEntry_Focused(object sender, FocusEventArgs e)
                {
                    try
                    {
                        var entry = sender as SfEntry;
                        var selectedItem = this.dataGrid.SelectedItem as IDictionary<string, object>;
                        var bindingContext = this.dataGrid.BindingContext as VarietyPageTabletViewModel;
                        var value = selectedItem[bindingContext.SelectedColumnName];
                        if (!string.IsNullOrWhiteSpace(value.ToText()))
                        {
                            entry.Text = value.ToText();
                            entry.SelectionLength = entry.Text.Length;
                        }
                    }
                    catch
                    {

                    }

                }

                private void CustomSfEntry_Completed(object sender, EventArgs e)
                {
                    try
                    {
                        WebserviceTasks.KeyboardNextClicked = true;
                        this.dataGrid.EndEdit();
                    }
                    catch
                    {

                    }

                }
            }
        }

        internal class CustomNumericViewRenderer : GridCellNumericRenderer
        {
            SfDataGrid grid;
            private bool commitcellCalled;
            public CustomNumericViewRenderer(SfDataGrid dataGrid)
            {
                grid = dataGrid;
            }

            protected override SfNumericTextBoxExt OnCreateEditUIView()
            {
                var view = new CustomSfEntry(grid);
                return view;

            }

            public override void OnInitializeDisplayView(DataColumnBase dataColumn, SfLabel view)
            {
                base.OnInitializeDisplayView(dataColumn, view);
                if (view == null)
                    return;
                //handle default value 0 for numeric data column
                var cellValue = dataColumn.CellValue;
                if (cellValue == null)
                    view.Text = "";
                else if (cellValue == DBNull.Value)
                    view.Text = "";
            }
            //public override object GetControlValue()
            //{
            //    try
            //    {
            //        if (textBox.Value == null || textBox.Value == DBNull.Value)
            //        {
            //            textBox.Value = "";
            //        }

            //        return base.GetControlValue();
            //    }
            //    catch (Exception) { return null; }

            //}
            public async override void CommitCellValue(bool isNewValue)
            {
                var newValue = this.GetControlValue();

                if (commitcellCalled && newValue == null) return;
                commitcellCalled = true;

                var selectedItem = this.grid.SelectedItem as IDictionary<string, object>;
                var bindingContext = this.grid.BindingContext as VarietyPageTabletViewModel;

                var dataColumn = (this.CurrentCellElement as GridCell).DataColumn;
                selectedItem[bindingContext.SelectedColumnName] = newValue;

                await Task.Delay(500);
                this.UpdateCellValue(dataColumn);
                this.RefreshDisplayValue(dataColumn);
            }

            protected override void OnUpdateCellValue(DataColumnBase dataColumn)
            {
                var bindingContext = this.grid.BindingContext as VarietyPageTabletViewModel;
                var cellValue = SfDataGridHelpers.GetCellValue(this.grid, dataColumn.RowData, bindingContext.SelectedColumnName);
                base.OnUpdateCellValue(dataColumn);
            }

            internal class CustomSfEntry : SfNumericTextBoxExt
            {
                SfDataGrid dataGrid;
                public CustomSfEntry(SfDataGrid sfDataGrid)
                {
                    dataGrid = sfDataGrid;
                    this.ReturnType = ReturnType.Next;
                    this.Completed += CustomSfEntry_Completed;
                    this.Focused += CustomSfEntry_Focused;
                    this.SelectAllOnFocus = true;
                }

                private void CustomSfEntry_Focused(object sender, FocusEventArgs e)
                {
                    try
                    {
                        var entry = sender as CustomSfEntry;
                        var selectedItem = this.dataGrid.SelectedItem as IDictionary<string, object>;
                        if (selectedItem != null)
                        {
                            var bindingContext = this.dataGrid.BindingContext as VarietyPageTabletViewModel;
                            var value = selectedItem[bindingContext.SelectedColumnName];
                            if (!string.IsNullOrWhiteSpace(value.ToText()))
                            {
                                entry.Value = value;
                            }
                        }

                    }
                    catch
                    {

                    }


                }

                private void CustomSfEntry_Completed(object sender, EventArgs e)
                {
                    try
                    {
                        WebserviceTasks.KeyboardNextClicked = true;
                        this.dataGrid.EndEdit();
                    }
                    catch
                    {

                    }

                }
            }
        }

        internal class CustomDateTimeViewRenderer : GridCellDateTimeRenderer
        {
            SfDataGrid grid;
            public CustomDateTimeViewRenderer(SfDataGrid dataGrid)
            {
                grid = dataGrid;
            }

            protected override SfLabel OnCreateDisplayUIView()
            {
                return base.OnCreateDisplayUIView();
            }
            protected override SfDatePicker OnCreateEditUIView()
            {
                var view = new CustomDateTimeControl(grid);
                return view;
            }

            internal class CustomDateTimeControl : SfDatePicker
            {
                SfDataGrid dataGrid;
                private string cellValue;
                private readonly Color defaultColor;
                private Dictionary<string, string> dateValueList;
                private string customKey;
                private bool focusedCalled;

                public CustomDateTimeControl(SfDataGrid sfDataGrid)
                {
                    dataGrid = sfDataGrid;
                    this.DateSelected += CustomDateTimeControl_DateSelected;
                    this.Focused += CustomDateTimeControl_Focused;
                    this.Unfocused += CustomDateTimeControl_Unfocused;
                    this.FontSize = 16;
                    dateValueList = new Dictionary<string, string>();
                    focusedCalled = false;
                    defaultColor = this.TextColor;
                }

                private void CustomDateTimeControl_Unfocused(object sender, FocusEventArgs e)
                {
                    var picker = sender as SfDatePicker;
                    focusedCalled = false;

                    if (string.IsNullOrEmpty(dateValueList[customKey].ToText()))
                    {
                        picker.TextColor = Color.Transparent;
                    }
                    else
                    {
                        picker.TextColor = defaultColor;
                    }
                }

                private void CustomDateTimeControl_Focused(object sender, FocusEventArgs e)
                {
                    var picker = sender as SfDatePicker;

                    var selectedItem = dataGrid.CurrentItem as IDictionary<string, object>;
                    if (selectedItem != null)
                    {
                        var bindingContext = this.dataGrid.BindingContext as VarietyPageTabletViewModel;
                        var value = selectedItem[bindingContext.SelectedColumnName];
                        var ezid = selectedItem["EZID"].ToText();

                        cellValue = value.ToText();
                        customKey = ezid + "-" + bindingContext.SelectedColumnName;

                        if (!dateValueList.ContainsKey(customKey))
                            dateValueList[customKey] = cellValue;

                        if (string.IsNullOrWhiteSpace(value.ToText()))
                        {

                        }
                        else
                        {
                            DateTime dt;
                            if (DateTime.TryParse(value.ToText(), out dt))
                            {
                                picker.DateSelected -= CustomDateTimeControl_DateSelected;
                                picker.Date = dt;
                                picker.DateSelected += CustomDateTimeControl_DateSelected;
                            }
                        }
                    }

                    focusedCalled = true;
                }

                private void CustomDateTimeControl_DateSelected(object sender, DateChangedEventArgs e)
                {
                    if (!focusedCalled) return;

                    var picker = sender as Syncfusion.SfDataGrid.XForms.Renderers.SfDatePicker;
                    var selectedItem = dataGrid.CurrentItem as IDictionary<string, object>;
                    if (selectedItem != null)
                    {
                        var bindingContext = this.dataGrid.BindingContext as VarietyPageTabletViewModel;

                        selectedItem[bindingContext.SelectedColumnName] = picker.Date;
                        cellValue = picker.Date.ToString();

                        dateValueList[customKey] = cellValue;

                        try
                        {
                            WebserviceTasks.KeyboardNextClicked = true;
                            dataGrid.EndEdit();
                        }
                        catch
                        {
                        }
                    }

                    focusedCalled = false;
                }
            }
        }

        internal class CustomComboboxViewRenderer : GridCellComboBoxRenderer
        {
            SfDataGrid grid;

            public CustomComboboxViewRenderer(SfDataGrid dataGrid)
            {
                grid = dataGrid;
            }

            protected override SfLabel OnCreateDisplayUIView()
            {
                return base.OnCreateDisplayUIView();
            }
            protected override GridComboBox OnCreateEditUIView()
            {
                var view = new CustomComboboxControl(grid);
                return view;
            }

            public async override void CommitCellValue(bool isNewValue)
            {
                var newValue = (this.CurrentCellElement as GridCell).CellValue;
                var selectedItem = this.grid.SelectedItem as IDictionary<string, object>;
                var bindingContext = this.grid.BindingContext as VarietyPageTabletViewModel;

                var dataColumn = (this.CurrentCellElement as GridCell).DataColumn;
                if (!string.IsNullOrEmpty(bindingContext.SelectedColumnName))
                    selectedItem[bindingContext.SelectedColumnName] = newValue;

                await Task.Delay(100);
                this.UpdateCellValue(dataColumn);
                this.RefreshDisplayValue(dataColumn);

            }

            protected override void OnUpdateCellValue(DataColumnBase dataColumn)
            {
                var bindingContext = this.grid.BindingContext as VarietyPageTabletViewModel;
                //var cellValue = SfDataGridHelpers.GetCellValue(this.grid, dataColumn.RowData, bindingContext.SelectedColumnName);
                base.OnUpdateCellValue(dataColumn);
            }

            internal class CustomComboboxControl : GridComboBox
            {
                SfDataGrid dataGrid;
                private string comboValue;
                //private bool dropdownOpened;
                //private bool cancelTriggered;
                private bool valueSelected;

                public CustomComboboxControl(SfDataGrid sfDataGrid)
                {
                    dataGrid = sfDataGrid;
                    this.DropDownOpen += CustomComboboxControl_DropDownOpen;
                    this.DropDownClosed += CustomComboboxControl_DropDownClosed;
                    this.SelectionChanging += CustomComboboxControl_SelectionChanging;
                    this.BindingContextChanged += CustomComboboxControl_BindingContextChanged;
                    this.EnableAutoSize = true;
                    this.DropDownWidth = 100;
                    this.MinimumHeightRequest = 300;
                    this.DisplayMemberPath = "TraitValueName";
                    this.SelectedValuePath = "TraitValueCode";
                    this.DropDownButtonSettings.Height = 0;
                    this.DropDownButtonSettings.Width = 0;
                    this.PopupDelay = 100;
                    this.IsEditableMode = true;

                    //Open Dropdown
                    Device.BeginInvokeOnMainThread(async () =>
                    {
                        await OpenDropdown(this);
                    });
                }

                private void CustomComboboxControl_DropDownOpen(object sender, EventArgs e)
                {
                    var comboBox = sender as GridComboBox;
                    var bindingContext = this.dataGrid.BindingContext as VarietyPageTabletViewModel;
                    var currentCol = bindingContext.SelectedColumnName;
                    var currentRow = bindingContext.SelectedRowindex;

                    comboBox.ClassId = currentRow + "-" + currentCol;

                    //dropdownOpened = true;
                }

                public async Task OpenDropdown(GridComboBox comboBox)
                {
                    await Task.Delay(200);
                    comboBox.IsDropDownOpen = true;
                }

                /// <summary>
                /// Calls when cell focus is changed. Used to open dropdown 
                /// </summary>
                /// <param name="sender"></param>
                /// <param name="e"></param>
                private async void CustomComboboxControl_BindingContextChanged(object sender, EventArgs e)
                {
                    var comboBox = sender as GridComboBox;
                    var bindingContext = this.dataGrid.BindingContext as VarietyPageTabletViewModel;
                    var currentCol = bindingContext.SelectedColumnName;
                    var lastCol = bindingContext.LastSelectedColumn;
                    var currentRow = bindingContext.SelectedRowindex;
                    var LastRow = bindingContext.LastSelectedRowindex;

                    if (comboBox.ClassId != currentRow + "-" + currentCol)
                    {
                        await OpenDropdown(comboBox);
                    }

                    //if(!string.IsNullOrEmpty(lastCol) && (currentCol != lastCol || currentRow != LastRow))
                    //{
                    //    if (!dropdownOpened && !cancelTriggered)
                    //        await OpenDropdown(comboBox);

                    //    cancelTriggered = false;
                    //}
                }




                /// <summary>
                /// SelectionChanged event is not alwasy firing somehow. So we track selectedvalue from here and 
                /// save on dropdown close
                /// </summary>
                /// <param name="sender"></param>
                /// <param name="e"></param>
                private void CustomComboboxControl_SelectionChanging(object sender, Syncfusion.XForms.ComboBox.SelectionChangingEventArgs e)
                {
                    var selectedValue = e.Value as TraitValue;
                    var newvalue = selectedValue.TraitValueCode;

                    var selectedItem = dataGrid.CurrentItem as IDictionary<string, object>;
                    var bindingContext = this.dataGrid.BindingContext as VarietyPageTabletViewModel;

                    var oldvalue = selectedItem[bindingContext.SelectedColumnName].ToText();

                    if (oldvalue != newvalue)
                    {
                        comboValue = newvalue;
                        valueSelected = true;
                    }
                    else
                        valueSelected = false;
                }

                private void CustomComboboxControl_DropDownClosed(object sender, EventArgs e)
                {
                    //dropdownOpened = false;

                    //if (!string.IsNullOrEmpty(comboValue))
                    if (valueSelected)
                    {
                        var comboBox = sender as GridComboBox;
                        var selectedItem = dataGrid.CurrentItem as IDictionary<string, object>;
                        if (selectedItem != null)
                        {
                            var bindingContext = this.dataGrid.BindingContext as VarietyPageTabletViewModel;

                            selectedItem[bindingContext.SelectedColumnName] = comboValue;
                            WebserviceTasks.KeyboardNextClicked = true;
                            comboValue = "";
                            dataGrid.EndEdit();
                        }

                        //cancelTriggered = false;
                        valueSelected = false;
                    }
                    else
                    {
                        //cancelTriggered = true;
                        dataGrid.CancelEdit();
                    }
                }
            }
        }

        internal class CustomPickerViewRenderer : GridCellPickerRenderer
        {
            SfDataGrid grid;

            public CustomPickerViewRenderer(SfDataGrid dataGrid)
            {
                grid = dataGrid;
            }

            protected override SfLabel OnCreateDisplayUIView()
            {
                return base.OnCreateDisplayUIView();
            }
            protected override GridPicker OnCreateEditUIView()
            {
                var view = new CustomPickerControl(grid);
                return view;
            }

            public async override void CommitCellValue(bool isNewValue)
            {
                var newValue = (this.CurrentCellElement as GridCell).CellValue;
                var selectedItem = this.grid.SelectedItem as IDictionary<string, object>;
                var bindingContext = this.grid.BindingContext as VarietyPageTabletViewModel;

                var dataColumn = (this.CurrentCellElement as GridCell).DataColumn;
                //if (!string.IsNullOrEmpty(bindingContext.SelectedColumnName))
                //    selectedItem[bindingContext.SelectedColumnName] = newValue;

                await Task.Delay(300);
                this.UpdateCellValue(dataColumn);
                this.RefreshDisplayValue(dataColumn);
            }

            protected override void OnUpdateCellValue(DataColumnBase dataColumn)
            {
                var bindingContext = this.grid.BindingContext as VarietyPageTabletViewModel;
                //var cellValue = SfDataGridHelpers.GetCellValue(this.grid, dataColumn.RowData, bindingContext.SelectedColumnName);
                base.OnUpdateCellValue(dataColumn);
            }

            internal class CustomPickerControl : GridPicker
            {
                SfDataGrid dataGrid;
                private string comboValue;

                public CustomPickerControl(SfDataGrid sfDataGrid)
                {
                    dataGrid = sfDataGrid;
                    this.DisplayMemberPath = "TraitValueName";
                    this.ValueMemberPath = "TraitValueCode";
                    this.Focused += CustomPickerControl_Focused;
                    this.Unfocused += CustomPickerControl_Unfocused;
                }

                private void CustomPickerControl_Unfocused(object sender, FocusEventArgs e)
                {
                    if (WebserviceTasks.KeyboardNextClicked)
                    {
                        var picker = sender as GridPicker;
                        var selectedItem = dataGrid.CurrentItem as IDictionary<string, object>;
                        if (selectedItem != null)
                        {
                            var bindingContext = this.dataGrid.BindingContext as VarietyPageTabletViewModel;
                            selectedItem[bindingContext.SelectedColumnName] = picker.SelectedItem.ToText();
                        }

                        dataGrid.EndEdit();
                    }
                    else
                    {
                        dataGrid.CancelEdit();
                    }

                    this.SelectedIndexChanged -= CustomPickerControl_SelectedIndexChanged;
                }

                private async void CustomPickerControl_Focused(object sender, FocusEventArgs e)
                {
                    var picker = sender as GridPicker;
                    var selectedItem = dataGrid.CurrentItem as IDictionary<string, object>;
                    if (selectedItem != null)
                    {
                        var bindingContext = this.dataGrid.BindingContext as VarietyPageTabletViewModel;

                        var value = selectedItem[bindingContext.SelectedColumnName].ToText();

                        if (!string.IsNullOrEmpty(value))
                        {
                            var source = picker.ItemsSource as IList<TraitValue>;
                            var selectedVal = source.FirstOrDefault(o => o.TraitValueCode == value);

                            picker.SelectedItem = selectedVal;
                            await Task.Delay(100);
                        }
                    }

                    this.SelectedIndexChanged += CustomPickerControl_SelectedIndexChanged;
                }

                private void CustomPickerControl_SelectedIndexChanged(object sender, EventArgs e)
                {
                    WebserviceTasks.KeyboardNextClicked = true;
                }
            }
        }
    }