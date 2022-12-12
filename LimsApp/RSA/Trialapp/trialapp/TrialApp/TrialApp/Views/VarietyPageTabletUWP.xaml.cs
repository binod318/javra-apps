using Azure.Storage.Blobs;
//using MR.Gestures;
using Plugin.Media;
using Plugin.Media.Abstractions;
using Stormlion.PhotoBrowser;
using Syncfusion.SfDataGrid.XForms;
using Syncfusion.SfDataGrid.XForms.Renderers;
using Syncfusion.XForms.ComboBox;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Data;
using System.Diagnostics;
using System.Dynamic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using TrialApp.Common.Extensions;
using TrialApp.Controls;
using TrialApp.Entities.Master;
using TrialApp.Entities.Transaction;
using TrialApp.Helper;
using TrialApp.Models;
using TrialApp.Services;
using TrialApp.ViewModels;
using Xamarin.Essentials;
using Xamarin.Forms;
using Xamarin.Forms.Internals;
using Xamarin.Forms.Xaml;

namespace TrialApp.Views
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class VarietyPageTabletUWP : ContentPage
    {
        private int trialEzid;
        bool disposeContent = false;
        private VarietyPageTabletViewModel vm;
        private Image imgControl;
        private bool fromOldobsDate = false;
        private DateTime oldObsValue = DateTime.Now;
        private List<Entities.Master.Trait> traitsOnGrid;
        private string trialEntryEzid = "";
        //private static MediaFile phototoUpload;        
        public VarietyPageTabletUWP(int ezid, string trialName, string cropCode)
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

            //To handle keydown
            DataGrid.SelectionController = new CustomSelectionController(DataGrid);

            //Add different renderer
            DataGrid.GridStyle = new CustomGridStyle();
            traitsOnGrid = new List<Entities.Master.Trait>();
            //numberic column renderer
            DataGrid.CellRenderers.Remove("Numeric");
            DataGrid.CellRenderers.Add("Numeric", new CustomNumericViewRendererUWP());
            DataGrid.CellRenderers.Remove("ComboBox");
            DataGrid.CellRenderers.Add("ComboBox", new CustomComboBoxRenderer());
            this.DataGrid.SelectionController = new GridSelectionControllerExt(DataGrid);

            //this.DataGrid.CellRenderers["Numeric"] = new CustomNumericViewRendererUWP(this.DataGrid);

        }
        protected async override void OnAppearing()
        {
            disposeContent = false;
            base.OnAppearing();
            if (!vm.IsPageLoaded)
            {

                await Task.Delay(1);
                vm.LoadFieldSetAsync();
                await vm.LoadGridDataAsync();

                DataGrid.ItemsSource = vm.DataTableCollection;

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

        protected override bool OnBackButtonPressed()
        {
            if (navigationDrawer.ContentView != null)
            {
                navigationDrawer.ContentView = null;
            }
            disposeContent = true;
            return base.OnBackButtonPressed();
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
                var action = !await DisplayAlert("Save changes?", "Do you want to save changes before leaving?", "No", "Yes");
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

            if (disposeContent)
            {
                //free up memory used by this page
                DataGrid.Dispose();
                AllTraitsListView.Dispose();
                this.Content = null;
            }
        }

        private async Task LoadDefaultTraitSet()
        {
            //load local traits defined per trial, Only if this column doesn't exist then go for existing logic
            var traits = await vm.GetDefaultTraitsPerTrial(vm.TrialEZID);

            if (traits.Any())
            {
                await LoadColumnswithDataonGrid(traits);
            }
            //select default traitset
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
            {
                if (traits.Any())
                    TraitsetPicker.SelectedIndexChanged -= TraitsetPicker_SelectedIndexChanged;
                TraitsetPicker.SelectedItem = vm.FieldSet.FirstOrDefault(x => x.FieldSetID == defaultTS);
                if (traits.Any())
                    TraitsetPicker.SelectedIndexChanged += TraitsetPicker_SelectedIndexChanged;
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
                vm.ConfirmationMessage = "";
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

                    //binodg
                    vm.DynamicObjToDT(vm.VarietyDetailList);

                    // DataGrid.View.Refresh();

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

        private void SearchTrait_OnTextChanged(object sender, Xamarin.Forms.TextChangedEventArgs e)
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

            traitsOnGrid.Clear();
            //first remove column for selected fieldset of grid from grid because there may be a chance where column from fieldset can be unselected
            foreach (var _columns in vm.FieldSetTraitCollumns)
            {
                DataGrid.Columns.Remove(_columns);
            }
            DataGrid.QueryCellStyle += DataGrid_QueryCellStyle;

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
            foreach (var t in vm.TraitsInChooseColumn)
            {
                traitsOnGrid.Add(t);
            }

            //add columns 
            foreach (var _columns in vm.ChooseColumnTraitCollumns)
            {
                DataGrid.Columns.Insert(2, _columns); //Add choos column selected columns to first
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
                    foreach (var data in vm.DataObservation)
                    {
                        var item = vm.VarietyDetailList.Where(x => x.EZID == data.EZID).FirstOrDefault() as IDictionary<string, object>;
                        if (!string.IsNullOrEmpty(data.ObsValueDate))
                        {
                            var dateVal = new DateTime();
                            if (DateTime.TryParse(data.ObsValueDate, out dateVal))
                                item[data.TraitID.ToText()] = dateVal;

                        }
                        else if (!string.IsNullOrEmpty(data.ObsValueChar))
                            item[data.TraitID.ToString()] = data.ObsValueChar;
                        else if (data.ObsValueDecImp != null)
                            item[data.TraitID.ToString()] = data.ObsValueDecImp;
                        else if (data.ObsValueDecMet != null)
                            item[data.TraitID.ToString()] = data.ObsValueDecMet;
                        else if (data.ObsValueInt != null)
                            item[data.TraitID.ToString()] = data.ObsValueInt;
                        else
                            item[data.TraitID.ToString()] = null;
                    }
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
                var action = !(await DisplayAlert("Revert?", "Are you sure to revert changes?", "No", "Yes"));
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
                    vm.DynamicObjToDT(vm.VarietyDetailList);
                    DataGrid.View.Refresh();
                }
            }
            else
                DisableUpdateMode();
        }

        private async void DataGrid_CurrentCellActivating(object sender, CurrentCellActivatingEventArgs e)
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

            await Task.Delay(200);
        }

        private async void DataGrid_CurrentCellBeginEdit(object sender, GridCurrentCellBeginEditEventArgs e)
        {
            vm.SelectedCellValue = null;
            vm.LastSelectedColumn = vm.SelectedColumnName;
            vm.SelectedColumnName = e.Column.MappingName;
            vm.LastSelectedRowindex = vm.SelectedRowindex;
            vm.SelectedRowindex = e.RowColumnIndex.RowIndex;

            vm.SelectedItem = DataGrid.SelectedItem;
            vm.SelectedCellOldValue = DataGrid.GetCellValue(vm.SelectedItem, vm.SelectedColumnName).ToText();

            var columninfo = DataGrid.Columns[e.RowColumnIndex.ColumnIndex];
            var trait = vm.TraitsInCrop.Where(x => x.TraitID.ToText() == columninfo.MappingName).FirstOrDefault();

            //editor functionality
            if (trait != null && trait.Editor)
            {
                e.Cancel = true;
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

            await Task.Delay(200);
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
                    if (e.NewValue == null)
                        return;
                    var oldvalue = e.OldValue.ToText();
                    var newvalue = e.NewValue.ToText();
                    if (newvalue == "" && (trait.DataType.ToLower() == "i" || trait.DataType.ToLower() == "a"))
                        isNullEntry = true;
                    CreateObservationData(oldvalue, newvalue, isNullEntry);
                }
                //editor functionality needs to be added later
                else if (trait.Editor)
                {
                    //var oldvalue = e.OldValue.ToText();
                    //var newvalue = vm.TraitEditorText;

                    //vm.SelectedCellValue = newvalue;
                    //var selectedItem = DataGrid.SelectedItem as DataRowView;
                    //if (selectedItem != null)
                    //{
                    //    //selectedItem.Row[vm.SelectedColumnName] = newvalue;


                    //    //selectedItem.Row.BeginEdit();
                    //    selectedItem[vm.SelectedColumnName] = newvalue;
                    //    //selectedItem.Row.EndEdit();
                    //    CreateObservationData(vm.SelectedCellOldValue, newvalue);
                    //}
                }
                else if (trait.DataType.ToText().ToLower() == "d")
                {
                    var selectedItem = DataGrid.SelectedItem as DataRowView;
                    if (selectedItem != null)
                    {
                        selectedItem[vm.SelectedColumnName] = vm.SelectedCellValue;

                        //also update VarietyDetailist because we are creating DataTable from VarietyDetailist
                        foreach (IDictionary<string, object> item in vm.VarietyDetailList)
                        {
                            if (item.Keys.Contains("EZID") && item.Values.Contains(selectedItem.Row.ItemArray[0]))
                            {
                                item[vm.SelectedColumnName] = vm.SelectedCellValue;
                                break;
                            }
                        }

                        if (!string.IsNullOrWhiteSpace(vm.SelectedCellValue))
                            CreateObservationData(vm.SelectedCellOldValue, vm.SelectedCellValue, isNullEntry);
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

                await NavigateNextCell(rowindex, colindex);
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
                await DataGrid.ScrollToColumnIndex(colindex, true, ScrollToPosition.MakeVisible); // Bring cell to view first
            }
            else
            {
                rowindex++;
                await DataGrid.ScrollToRowIndex(rowindex, true, ScrollToPosition.MakeVisible); // Bring cell to view first
            }

            // To load combobox/date picker there should be delay
            await Task.Delay(400);
            DataGrid.BeginEdit(rowindex, colindex);
        }


        private void CreateObservationData(string oldvalue, string newvalue, bool isNullEntry)
        {
            var ezid = "";
            var row = DataGrid.SelectedItem as DataRowView;
            if (row == null) return;
            ezid = row.Row["EZID"].ToText();

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
            DataGrid.NavigationMode = Syncfusion.SfDataGrid.XForms.NavigationMode.Cell;
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
            DataGrid.NavigationMode = Syncfusion.SfDataGrid.XForms.NavigationMode.Row;
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
            if (vm.RowindexBeforeUpdate > 0)
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

        //private void ObsDate_Clicked(object sender, EventArgs e)
        //{
        //    //fire endedit for last cell 
        //    try
        //    {
        //        this.DataGrid.EndEdit();
        //    }
        //    catch
        //    {
        //    }
        //    ObsDatePicker.Focus();
        //}

        private async void Normal_Clicked(object sender, EventArgs e)
        {
            vm.HistoryGridVisible = false;
            DisableUpdateMode();

            var list = new List<Entities.Master.Trait>();
            list.AddRange(vm.TraitsInFieldset);
            list.AddRange(vm.TraitsInChooseColumn);
            traitsOnGrid = list;
            await vm.LoadDataOfSelectedTraits(list);
            DataGrid.NavigationMode = Syncfusion.SfDataGrid.XForms.NavigationMode.Row;

        }

        private void UpdateNav_Clicked(object sender, EventArgs e)
        {

        }

        private async void ObsDatePicker_DateSelected(object sender, DateChangedEventArgs e)
        {
            vm.ObsDateVal = (e.NewDate).Date.ToString("yyyy-MM-dd");
            if (fromOldobsDate)
            {
                fromOldobsDate = false;
            }
            else
            {
                if (vm.DataObservation.Count > 0 && Convert.ToDateTime(e.NewDate).Date != DateTime.Today.Date)
                {
                    var action = !await DisplayAlert("ObservationDate?", "Change Observation Date to current selected date.", "No", "Yes");
                    if (action)
                    {
                        vm.ObsDateVal = (e.NewDate).Date.ToString("yyyy-MM-dd");
                        vm.UpdateObservationDate();
                        oldObsValue = ObsDatePicker.Date;
                    }
                    else
                    {
                        fromOldobsDate = true;
                        ObsDatePicker.Date = oldObsValue;
                    }

                }
                else
                    oldObsValue = ObsDatePicker.Date;

            }
        }

        private async void DataGrid_GridLongPressed(object sender, GridLongPressedEventArgs e)
        {
            var selectedRow = e.RowData as DataRowView;

            if (selectedRow != null)
            {

                var trialEntryAppService = new TrialEntryAppService();
                var varietyId = selectedRow["EZID"].ToText();


                var isNewRecord = await vm.CheckIsNewRecordAsync(varietyId);
                var hasObservationData = await vm.CheckHasObeservationDataAsync(varietyId);
            
                if (App.ReleaseHideVariety && (!isNewRecord || hasObservationData))
                {
                    var value = !await DisplayAlert("Hide variety", "Are you sure you want to hide this variety?\nOnce hidden you won't be able to unhide the variety from the app.", "NO", "YES");
                    if (value)
                    {
                        if (await trialEntryAppService.HideVarietyAsync(varietyId, vm.TrialEZID))
                        {
                            DataGrid.SelectedItem = null;
                            DataGrid.View.Remove(selectedRow);
                            DataGrid.View.Refresh();
                        }
                    }
                }
                else
                {
                    var value = !(await DisplayAlert("Delete variety", "Do you really want to delete this variety?", "NO", "YES"));
                    if (value)
                    {
                        if (await vm.DeleteTrialEntry(varietyId))
                        {
                            //delete variety logic
                            if (await trialEntryAppService.DeleteVarietyAsync(varietyId))
                            {
                                //Remove deleted variety from grid
                                DataGrid.SelectedItem = null;
                                vm.VarietyDetailList.Remove(selectedRow);
                                DataGrid.View.Remove(selectedRow);
                                DataGrid.View.Refresh();

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
                e.Handled = true;
            }
            else
            {
                var colname = e.Column.MappingName;

                //only if there is value and trait column
                if (int.TryParse(colname, out int traitId) && vm.ModifiedObsList != null)
                {
                    var ezid = "";
                    var row = e.RowData as System.Data.DataRowView;

                    if (row != null && row.Row.RowState != System.Data.DataRowState.Detached)
                        ezid = row.Row.ItemArray[0]?.ToString();

                    if (vm.ModifiedObsList.Where(o => o.EZID == ezid && o.TraitID == traitId).Any())
                    {
                        e.Style.BackgroundColor = Color.Green;
                        e.Style.ForegroundColor = Color.White;
                        e.Style.CellStylePreference = StylePreference.StyleAndSelection;
                        e.Handled = true;
                    }
                    //else
                    //{
                    //    var trait = vm.TraitAll.FirstOrDefault(o => o.TraitID == traitId);
                    //    if (trait.DataType.ToLower() == "d" && e.CellValue != null)
                    //    {
                    //        e.Style.ForegroundColor = Color.Transparent;
                    //        e.Style.CellStylePreference = StylePreference.StyleAndSelection;

                    //        e.Handled = true;
                    //    }

                    //}
                }
            }
        }

        private void DataGrid_QueryRowStyle(object sender, QueryRowStyleEventArgs e)
        {
            var ezid = "";

            var row = e.RowData as System.Data.DataRowView;
            if (row != null && row.Row.RowState != System.Data.DataRowState.Detached)
                ezid = row.Row.ItemArray[0]?.ToString();


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
            DataGrid.NavigationMode = Syncfusion.SfDataGrid.XForms.NavigationMode.Cell;
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

        public async void OnFilterTextChanged(object sender, Xamarin.Forms.TextChangedEventArgs e)
        {
            //Since datatable doesn't support view filter, we created custom filter
            vm.IsBusy = true;
            await Task.Delay(10);

            if (string.IsNullOrWhiteSpace(e.NewTextValue))
            {
                vm.DynamicObjToDT(vm.VarietyDetailList);
            }
            else
            {
                var list = new ObservableCollection<dynamic>();
                var comparer = StringComparer.OrdinalIgnoreCase;
                foreach (IDictionary<string, object> item in vm.VarietyDetailList)
                {
                    //Make case insensitive
                    if (item.Values.Contains(e.NewTextValue, new CaseInsensitiveEqualityComparer()))
                        list.Add(item);
                }

                vm.DynamicObjToDT(list);
            }

            vm.IsBusy = false;
            await Task.Delay(1);
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
                //var ezid = "";

                var row = vm.SelectedItem as System.Data.DataRowView;

                //logic missing
                row[vm.SelectedColumnName] = vm.TraitEditorText;

                WebserviceTasks.KeyboardNextClicked = true;
                CreateObservationData(vm.SelectedCellOldValue, vm.TraitEditorText, false);

                //DataGrid.EndEdit();
            }
            vm.TraitEditorText = "";
            vm.TraitEditorPopupVisible = false;
            //DataGrid.View.Refresh();
            //this is used instead of complete refresh just to update cell style.
            DataGrid.BeginEdit(vm.SelectedRowindex, vm.SelectedColumnIndex);
            DataGrid.EndEdit();
        }

        private void DataGrid_GridTapped(object sender, GridTappedEventArgs e)
        {
            if (!DataGrid.AllowEditing)
            {
                var rowdata = e.RowData;
                var columninfo = DataGrid.Columns[e.RowColumnIndex.ColumnIndex];
                var value = DataGrid.GetCellValue(rowdata, columninfo.MappingName).ToText();
                var trait = vm.TraitsInCrop.Where(x => x.TraitID.ToText() == columninfo.MappingName).FirstOrDefault();

                if (trait != null && trait.Editor)
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

            var selectedItem = DataGrid.SelectedItem as System.Data.DataRowView;
            if (selectedItem == null)
            {
                await DisplayAlert("Alert", "No trial entry selected.", "Ok");
                return;
            }

            PhotoUploadPopup.IsVisible = true;
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


            var selectedItem = DataGrid.CurrentItem as System.Data.DataRowView;
            if (selectedItem != null)
            {
                trialEntryEzid = selectedItem.Row.ItemArray[0]?.ToText();
            }


        }

        private async void Gallery_Clicked(object sender, EventArgs e)
        {

            await vm.ShowImages(trialEzid.ToString());
            if (vm.TrialImages.Any())
            {
                carousel.ItemsSource = vm.TrialImages;
                PictureViewerPopUp.IsVisible = true;
                carousel.SelectedIndex = vm.TrialImages.Count - 1;
                carousel.SelectedIndex = 0;
            }
        }

        private async void LblCamera_Tapped(object sender, MR.Gestures.TapEventArgs e)
        {
            try
            {
                var fieldnumber = "";
                var varietyName = "";

                var selectedItem = DataGrid.SelectedItem as DataRowView;
                fieldnumber = selectedItem["FieldNumber"].ToText();
                varietyName = selectedItem["VarietyName"].ToText();
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
                var path = "";
                if (Device.RuntimePlatform == Device.UWP)
                {
                    path = Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.CommonApplicationData), "TrialAppPictures", trialEzid.ToString(), trialEntryEzid);
                }
                else
                {
                    path = Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.Personal), "TrialAppPictures", trialEzid.ToString(), trialEntryEzid);

                }
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
                    vm.PictureLocation = Path.Combine(path, fileName);
                    File.Copy(photo.Path, vm.PictureLocation, true);

                    File.Delete(photo.Path);
                    photo.Dispose();
                    await vm.UploadPhotoFromCameraAsync(vm.PictureLocation);
                    if (vm.ImagePrevPopup)
                    {

                        imgControl = new Image
                        {

                            HeightRequest = 400,
                            WidthRequest = 600,
                            Aspect = Aspect.AspectFit,
                            Source = ImageSource.FromFile(vm.PictureLocation)
                        };
                        Grid.SetRowSpan(imgControl, 2);
                        Grid.SetRow(imgControl, 0);
                        PrevGrid.Children.Add(imgControl);


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

            }
            catch (Exception ex)
            {
                await DisplayAlert("Error", ex.Message.ToString(), "Ok");
            }
        }

        private async Task FlushPrevieImage()
        {
            if (imgControl == null) return;
            imgControl.Source = null;
            PrevGrid.Children.Remove(imgControl);
            imgControl = null;
        }
        private async void LblGallery_Tapped(object sender, MR.Gestures.TapEventArgs e)
        {
            await FlushPrevieImage();
            PhotoUploadPopup.IsVisible = false;
            TraitListForImage.IsVisible = false;
            TraitListForImage.SelectedIndexChanged -= TraitListForImage_SelectedIndexChanged;
            TraitListForImage.SelectedItem = null;
            TraitListForImage.SelectedIndexChanged += TraitListForImage_SelectedIndexChanged;
            await vm.UploadPhotoFromGalleryAsync();
            if (vm.ImagePrevPopup)
            {
                imgControl = new Image
                {

                    HeightRequest = 400,
                    WidthRequest = 600,
                    Aspect = Aspect.AspectFit,
                    Source = ImageSource.FromFile(vm.PictureLocation)
                };
                Grid.SetRowSpan(imgControl, 2);
                Grid.SetRow(imgControl, 0);
                PrevGrid.Children.Add(imgControl);
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


        private async void CloseAddImage_Tapped(object sender, MR.Gestures.TapEventArgs e)
        {

            await FlushPrevieImage();
            PhotoUploadPopup.IsVisible = false;
        }

        private async void btnConfirm_Clicked(object sender, EventArgs e)
        {


            var selectedItem = DataGrid.SelectedItem as DataRowView;
            var selectedTraitID = "";
            var selectedTraitName = "";

            var fieldnumber = selectedItem["FieldNumber"].ToText();
            var varietyName = selectedItem["VarietyName"].ToText();

            var selectedpickerItem = TraitListForImage.SelectedItem as Entities.Master.Trait;
            if (selectedpickerItem == null)
            {
                await Application.Current.MainPage.DisplayAlert("Error!", "Please select a Trait from the dropdown", "OK");
                return;
            }
            if (selectedpickerItem != null)
            {
                selectedTraitID = selectedpickerItem.TraitID.ToText();
                selectedTraitName = selectedpickerItem.ColumnLabel;
            }
            await FlushPrevieImage();
            await vm.UploadPictureConfirmed(trialEzid, trialEntryEzid, fieldnumber.Trim().Replace(" ", "-"), varietyName.Trim().Replace(" ", "-"), selectedTraitID, selectedTraitName.Replace("%", ""));


        }

        private async void btnNo_clicked(object sender, EventArgs e)
        {
            try
            {
                showImagePreviewPopup.IsVisible = false;
                await FlushPrevieImage();
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

        private void VarietySearchBar_SearchButtonPressed(object sender, EventArgs e)
        {
            var searchbar = sender as SearchBar;
            var text = searchbar.Text;

            if (!(vm.VarietyDetailList.Where(x => x.FieldNumber == text || x.VarietyName == text).FirstOrDefault() is IDictionary<string, object> dt)) return;
            var ezid = dt["EZID"].ToText();
            var rowindex = vm.IndexedEzids.FirstOrDefault(x => x.Key == ezid).Value;

            this.DataGrid.SelectedIndex = rowindex + 1;
            this.DataGrid.ScrollToRowIndex(rowindex + 1);
        }

        private void PictureCloseLabel_Tapped(object sender, MR.Gestures.TapEventArgs e)
        {
            PictureViewerPopUp.IsVisible = false;
        }

        private async void DeleteImage_clicked(object sender, EventArgs e)
        {
            if (vm.SelectedTrialImage.FromBlob)
            {
                await Application.Current.MainPage.DisplayAlert("Error!", "Unable to delete this photo. This photo is already uploaded to server.", "OK");
                return;
            }
            else
            {
                vm.TrialImages.Remove(vm.SelectedTrialImage);
                await vm.DeleteTrialImageAsync();
                carousel.SelectedIndex = 0;
            }

        }
        private void carousel_SelectionChanged(object sender, Syncfusion.SfCarousel.XForms.SelectionChangedEventArgs e)
        {
            vm.SelectedTrialImage = e.SelectedItem as TrialImage;
            vm.TrialImages.ForEach(x => x.Deletevisible = false);
            vm.SelectedTrialImage.Deletevisible = true;
        }

        private void GridObsDate_Tapped(object sender, EventArgs e)
        {
            try
            {
                this.DataGrid.EndEdit();
            }
            catch
            {
            }
            ObsDatePicker.Focus();
        }

        private void ObsDatePicker_Focused(object sender, FocusEventArgs e)
        {
            oldObsValue = ObsDatePicker.Date;
        }
    }



    internal class CustomNumericViewRendererUWP : GridCellNumericRenderer
    {
        SfNumericTextBoxExt textBox;

        public override void OnInitializeDisplayView(DataColumnBase dataColumn, SfLabel view)
        {
            base.OnInitializeDisplayView(dataColumn, view);

            //handle default value 0 for numeric data column
            var cellValue = dataColumn.CellValue;
            if (cellValue == null)
                view.Text = "";
            else if (cellValue == DBNull.Value)
                view.Text = "";
        }
        protected override void SetFocus(View view, bool needToFocus)
        {
            base.SetFocus(view, needToFocus);
        }

        public CustomNumericViewRendererUWP()
        {
        }

        public override object GetControlValue()
        {
            try
            {
                if (textBox.Value == null || textBox.Value == DBNull.Value)
                {
                    textBox.Value = "";
                }

                return base.GetControlValue();
            }
            catch (Exception) { return null; }

        }

        protected override SfNumericTextBoxExt OnCreateEditUIView()
        {
            textBox = new SfNumericTextBoxExt();
            return textBox;
        }

    }

    //Inherits the GridSelectionController Class
    public class GridSelectionControllerExt : GridSelectionController
    {
        public GridSelectionControllerExt(SfDataGrid datagrid)
          : base(datagrid)
        {
        }
        protected override void ProcessKeyDown(string keyCode, bool isCtrlKeyPressed, bool isShiftKeyPressed)
        {
            base.ProcessKeyDown(keyCode, isCtrlKeyPressed, isShiftKeyPressed);
        }
    }



    public class CustomComboBoxRenderer : GridCellComboBoxRenderer
    {
        protected override void OnEnteredEditMode(DataColumnBase dataColumn, View currentRendererElement)
        {
            base.OnEnteredEditMode(dataColumn, currentRendererElement);
            DependencyService.Get<ICustomizeComboBoxBehavior>().GetRender(currentRendererElement as SfComboBox);
        }

        protected override void UnwireEditUIElement(GridComboBox editElement)
        {
            DependencyService.Get<ICustomizeComboBoxBehavior>().UnHook(editElement as SfComboBox);
            base.UnwireEditUIElement(editElement);
        }
    }
}