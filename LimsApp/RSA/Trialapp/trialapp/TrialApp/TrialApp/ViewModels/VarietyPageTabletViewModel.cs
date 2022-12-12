using Newtonsoft.Json;
using Syncfusion.Data.Extensions;
using Syncfusion.SfDataGrid.XForms;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Data;
using System.Dynamic;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using TrialApp.Common;
using TrialApp.Common.Extensions;
using TrialApp.Entities.Master;
using TrialApp.Entities.Transaction;
using TrialApp.Helper;
using TrialApp.Services;
using Xamarin.Forms;

namespace TrialApp.ViewModels
{
    public class VarietyPageTabletViewModel : VarietyBaseViewModel
    {
        protected ObservationAppService _observationAppService;
        protected DefaultTraitsPerTrialService _defaultTraitsPerTrialService;
        private DefaultFieldSetService defaultFieldSetService;
        private TrialService _trialService; 
        private double _traitInfoPopupHeight;

        public TraitFieldValidation Validation { get; set; }
        protected TraitValueService traitValueService;
        public ObservableCollection<dynamic> VarietyDetailList { get; set; }
        public List<FieldSet> FieldSet { get; set; }
        public List<Entities.Master.Trait> TraitsInFieldset { get; set; }
        public List<Entities.Master.Trait> TraitsInChooseColumn { get; set; }
        public List<GridColumn> FieldSetTraitCollumns { get; set; }
        public List<GridColumn> ChooseColumnTraitCollumns { get; set; }
        public Dictionary<string, int> IndexedEzids { get; set; }
        public ObservableCollection<TraitAll> TraitAll { get; set; }
        public List<Entities.Master.Trait> TraitsInCrop { get; set; }
        public List<ObservationAppHistory> OldObservation { get; set; }
        public List<ObservationAppLookup> DataObservation { get; set; }
        public string SelectedColumnName { get; set; }
        public string LastSelectedColumn { get; set; }
        public string SelectedCellValue { get; set; }
        public string SelectedCellOldValue { get; set; }
        public int LastSelectedRowindex { get; set; }
        public int SelectedRowindex { get; set; }
        public int RowindexBeforeUpdate { get; set; }
        public List<ObservationAppLookup> ModifiedObsList { get; set; } //Used for cell coloring
        public TrialLookUp TrialDetail { get; set; }
        public double TraitInfoPopupHeight
        {
            get { return _traitInfoPopupHeight; }
            set { _traitInfoPopupHeight = value; OnPropertyChanged(); }
        }
        public object SelectedItem { get; set; }
        public int SelectedColumnIndex { get; set; }

        public VarietyPageTabletViewModel(int ezid, string trialName, string cropCode)
        {
            TrialEZID = ezid;
            TrialName = trialName;
            CropCode = cropCode;
            VarietyDetailList = new ObservableCollection<dynamic>();
            FieldSet = new List<FieldSet>();
            TraitsInFieldset = new List<Entities.Master.Trait>();
            TraitsInChooseColumn = new List<Entities.Master.Trait>();
            FieldSetTraitCollumns = new List<GridColumn>();
            ChooseColumnTraitCollumns = new List<GridColumn>();
            IndexedEzids = new Dictionary<string, int>();
            TraitAll = new ObservableCollection<TraitAll>();
            _observationAppService = new ObservationAppService();
            defaultFieldSetService = new DefaultFieldSetService();
            _defaultTraitsPerTrialService = new DefaultTraitsPerTrialService();
            traitValueService = new TraitValueService();
            _trialService = new TrialService();
            TraitsInCrop = new List<Entities.Master.Trait>();
            DataObservation = new List<ObservationAppLookup>();
            OldObservation = new List<ObservationAppHistory>();
            Validation = new TraitFieldValidation();
            LoadTrialPropParams();
            UpdateModeIcon = ImageSource.FromFile("Assets/horizontal.png");
            UpdateModeText = "Horizontal";
            Device.BeginInvokeOnMainThread(async () =>
            {
                await GetModifiedObservation();
            });
        }

        public async Task<List<Entities.Master.Trait>> GetDefaultTraitsPerTrial(int ezid)
        {
            var traits = new List<Entities.Master.Trait>();
            var data = await _defaultTraitsPerTrialService.GetAsync(ezid);
            if (data.Any())
                traits = await _traitService.GetTraitsDetailAsync(string.Join(",", data.Select(o => o.TraitID)));

            var orderedTraits = from option in traits
                                 join type in data
                                 on option.TraitID equals type.TraitID
                                 orderby type.Order
                                 select option;

            return orderedTraits.ToList();
        }

        internal async Task SaveDefaultTraits(Columns columns)
        {
            var listTraits = new List<DefaultTraitsPerTrial>();
            int order = 1;

            //Save columns info before exit
            foreach (var column in columns)
            {
                // If trait
                if (int.TryParse(column.MappingName, out int id))
                {
                    listTraits.Add(new DefaultTraitsPerTrial { EZID = TrialEZID, TraitID = id, Order = order });

                    order++;
                }
            }

            if(listTraits.Any())
                await _defaultTraitsPerTrialService.SaveAsync(listTraits);
        }

        private async Task GetModifiedObservation()
        {
            ModifiedObsList = await _observationAppService.GetModifiedObservationsForTrialAsync(TrialEZID);
        }

        internal async Task LoadDataOfSelectedTraits(List<Entities.Master.Trait> traits)
        {
            await _observationAppService.GetObservationForSelectedTraits(traits, VarietyDetailList.ToList(), "", TrialEZID, IndexedEzids);
            DynamicObjToDT(VarietyDetailList);
        }

        internal void LoadFieldSetAsync()
        {
            FieldSet = _fieldSetService.GetFieldSetList(CropCode);
        }

        internal async Task LoadGridDataAsync()
        {
            //Get TrialDetail
            TrialDetail = _trialService.GetTrialInfo(TrialEZID);

            var data = await _trialEntryAppService.GetVarietiesListAsync(TrialEZID);
            int index = 0;
            foreach (var _data in data)
            {
                IndexedEzids[_data.EZID.ToText()] = index;
                dynamic item = new ExpandoObject();
                item.EZID = _data.EZID;
                item.FieldNumber = _data.FieldNumber;
                item.VarietyName = _data.VarietyName;
                item.ResistanceHR = _data.ResistanceHR;
                item.ResistanceT = _data.ResistanceT;
                item.ResistanceIR = _data.ResistanceIR;
                VarietyDetailList.Add(item);
                index++;
            }

            ////add columns
            //DataTableCollection.Columns.Add("EZID", typeof(int));
            //DataTableCollection.Columns.Add("FieldNumber", typeof(string));
            //DataTableCollection.Columns.Add("VarietyName", typeof(string));
            //DataTableCollection.Columns.Add("ResistanceHR", typeof(string));
            //DataTableCollection.Columns.Add("ResistanceT", typeof(string));
            //DataTableCollection.Columns.Add("ResistanceIR", typeof(string));

            //binodg
            DynamicObjToDT(VarietyDetailList);
        }

        public void DynamicObjToDT(ObservableCollection<dynamic> dlist)
        {
            if (Device.RuntimePlatform != Device.Android)
            {
                var json = JsonConvert.SerializeObject(dlist);
                DataTableCollection = (DataTable)JsonConvert.DeserializeObject(json, (typeof(DataTable)));
            }
        }

        internal List<Entities.Master.Trait> GetTraitsInFieldSet(int fieldSetID)
        {
            TraitsInFieldset = _traitService.GetTraitList(fieldSetID);
            return TraitsInFieldset;
        }

        internal List<GridColumn> GenerateColumns(IEnumerable<Entities.Master.Trait> traits)
        {
            var list = new List<GridColumn>();
            foreach(var _traits in traits)
            {
                var unit = UnitOfMeasure.SystemUoM == "Imperial" ? _traits.BaseUnitImp ?? "" : _traits.BaseUnitMet ?? "";
                unit = string.IsNullOrEmpty(unit) ? "" : " (" + unit + ") ";
                var columnLabel = _traits.ColumnLabel + unit;

                var headerTemplate = new DataTemplate(() =>
                {
                    Label headerLabel = new Label
                    {
                        Text = columnLabel,
                        LineBreakMode = LineBreakMode.WordWrap,
                        HorizontalOptions = LayoutOptions.Center,
                        VerticalOptions = LayoutOptions.Center,
                        Rotation = 270,
                        FontAttributes = FontAttributes.Bold,
                    };
                    return headerLabel;
                });

                //create combobox column
                if (_traits.ListOfValues)
                {
                    ////add column
                    //DataTableCollection.Columns.Add(_traits.TraitID.ToString(), typeof(string));
                    List<TraitValue> listofvalues = new List<TraitValue>();
                    //var col = new GridPickerColumn();
                    var col = new GridComboBoxColumn();
                    var cmbnull = new TraitValue
                    {
                        TraitValueCode = "", //because if nothing is assigned on data source, null value is assigned automatically.
                        TraitValueName = " "
                    };
                    
                    listofvalues = traitValueService.GetCropTraitValue(_traits.TraitID, CropCode).ToList();
                    listofvalues.ForEach(x => x.TraitValueName = x.TraitValueCode + " : " + x.TraitValueName);

                    listofvalues.Insert(0, cmbnull);
                  
                    col.ColumnSizer = ColumnSizer.Auto;
                    col.ItemsSource = listofvalues;
                    //col.HeaderText = columnLabel;
                    col.HeaderTemplate = headerTemplate;
                    col.LineBreakMode = LineBreakMode.NoWrap;
                    col.AllowEditing = _traits.Updatable;
                    col.AllowSorting = true;                    
                    //col.TextAlignment = TextAlignment.Center;
                    col.DisplayMemberPath = "TraitValueName";
                    col.ValueMemberPath = "TraitValueCode";
                    col.MinimumWidth = 50;
                    col.MappingName = _traits.TraitID.ToString();
                    //col.ColumnSizer = ColumnSizer.Auto;
                    col.AllowFocus = true;
                    col.Width = 100;
                    //col.Title = columnLabel;

                    list.Add(col);
                }
                else
                {
                    //if display format is null or empty create text column
                    if (string.IsNullOrWhiteSpace(_traits.DataType))
                    {
                        ////add column
                        //DataTableCollection.Columns.Add(_traits.TraitID.ToString(), typeof(string));
                        var col = new GridTextColumn
                        {
                            //HeaderText = columnLabel,
                            HeaderTemplate = headerTemplate,
                            AllowEditing = _traits.Updatable,
                            AllowSorting = true,
                            //TextAlignment = TextAlignment.Center,
                            MinimumWidth = 20,
                            MappingName = _traits.TraitID.ToString(),
                            ColumnSizer = ColumnSizer.SizeToHeader,
                            //LoadUIView = true,
                            LineBreakMode = LineBreakMode.NoWrap,
                            AllowFocus = true,
                            Width = 100
                    };
                        
                        list.Add(col);
                    }
                    //create textColumn
                    else if (_traits.DataType.ToText().ToUpper()  == "C")
                    {
                        ////add column
                        //DataTableCollection.Columns.Add(_traits.TraitID.ToString(), typeof(string));
                        var col = new GridTextColumn
                        {
                            //HeaderText = columnLabel,
                            HeaderTemplate = headerTemplate,
                            AllowSorting = true,
                            MinimumWidth = 20,
                            //TextAlignment = TextAlignment.Center,
                            MappingName = _traits.TraitID.ToString(),
                            ColumnSizer = ColumnSizer.SizeToHeader,
                            AllowFocus = true,
                           // LoadUIView = true,
                            LineBreakMode = LineBreakMode.NoWrap,
                            AllowEditing = _traits.Updatable,
                            Width = 100

                        };
                        list.Add(col);

                    }
                    //dateTime column
                    else if (_traits.DataType.ToText().ToUpper() == "D")
                    {
                        ////add column
                        //DataTableCollection.Columns.Add(_traits.TraitID.ToString(), typeof(DateTime));
                        var col = new GridDateTimeColumn
                        {
                            //HeaderText = columnLabel,
                            HeaderTemplate = headerTemplate,
                            AllowEditing = _traits.Updatable,
                            AllowSorting = true,
                           // TextAlignment = TextAlignment.Center,
                            MinimumWidth = 20,
                            MappingName = _traits.TraitID.ToString(),
                            ColumnSizer = ColumnSizer.SizeToHeader,
                            Format = "d",
                            //LoadUIView = true,
                            LineBreakMode = LineBreakMode.NoWrap,
                            AllowFocus = true,
                            Width = 100

                        };
                        list.Add(col);
                    }
                    //Numeric column if starts with -9 or 9 then fixed length numeric field else variable length 
                    //else if (_traits.DisplayFormat.StartsWith("9") || _traits.DisplayFormat.StartsWith("-9") || _traits.DisplayFormat.StartsWith(">") || _traits.DisplayFormat.StartsWith("->"))
                    else if(_traits.DataType.ToText().ToUpper() =="I" || _traits.DataType.ToText().ToUpper() == "A")
                    {
                        ////add column
                        //DataTableCollection.Columns.Add(_traits.TraitID.ToString(), typeof(decimal));
                        var col = new GridNumericColumn
                        {
                            HeaderTemplate = headerTemplate,
                            AllowEditing = _traits.Updatable,
                            AllowSorting = true,
                            NumberDecimalDigits = _traits.DataType.ToText().ToUpper() == "I" ? 0 : GetDecimalDigit(_traits.DisplayFormat),
                            MinimumWidth = 20,
                            MappingName = _traits.TraitID.ToString(),
                            ColumnSizer = ColumnSizer.SizeToHeader,
                            AllowFocus = true,
                            LineBreakMode = LineBreakMode.NoWrap,
                            AllowNullValue = true,
                            TextAlignment = TextAlignment.Center,
                            NullValue = DBNull.Value,
                            NullText = "",
                            Width = 100,
                            //LoadUIView = true
                        };
                        list.Add(col);
                    }
                }
            }

            return list;
        }

        private int GetDecimalDigit(string format)
        {
            if (string.IsNullOrEmpty(format)) return 2;
            var decSeparator = CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator;
            var separators = ",.";
            var decimalSeparator = Convert.ToChar(decSeparator).ToString();
            format = format.Replace(",", "");
            format = format.Replace(">", "9");

            if (format.EndsWith("."))
            {
                format = format.Remove(format.Length - 1, 1);
            }
            format = format.Replace(".", decSeparator);
            separators = separators.Replace(decimalSeparator, "");
            format = format.Replace(".", decSeparator);
            if (format.Contains(decSeparator))
            {
                var format1 = format.Split(Convert.ToChar(decSeparator));
                return format1[1].ToString().Length;
            }
            return 0;
        }
        internal async Task LoadDataOfSelectedTraitSet(string historyObs)
        {
            var traits = TraitsInFieldset.Union(TraitsInChooseColumn).ToList();

            await _observationAppService.GetObservationForSelectedTraits(traits, VarietyDetailList.ToList(), historyObs, TrialEZID, IndexedEzids);
            //AddColumnsWithDataType(traits);
            DynamicObjToDT(VarietyDetailList);

        }

        //private void AddColumnsWithDataType(List<Entities.Master.Trait> traits)
        //{
        //    foreach(var _traits in traits)
        //    {
        //        var dataColumn = new System.Data.DataColumn
        //        {
        //            ColumnName = _traits.TraitID
        //        }
        //    }

        //    DataTableCollection.Columns.Add()
        //}

        internal async Task GetAllTraitsAsync(string cropCode)
        {
            TraitsInCrop = await _traitService.GetAllTraitsAsync(CropCode);

            TraitAll = new ObservableCollection<TraitAll>(TraitsInCrop.Select(x => new TraitAll
            {
                TraitID = x.TraitID,
                ColumnLabel = x.ColumnLabel,
                DataType = x.DataType,
                TraitName = x.TraitName,
                Updatable = x.Updatable,
                TraitTypeID = x.TraitTypeID,
                ListOfValues = x.ListOfValues,
                Property = x.Property,
                Editor = x.Editor,
                ShowSum = x.ShowSum,
                MinValue = x.MinValue,
                MaxValue = x.MaxValue,
                DisplayFormat = x.DisplayFormat,
                Description = x.Description,
                UoMCode = (UnitOfMeasure.SystemUoM == "Imperial" ? x.BaseUnitImp ?? "" : x.BaseUnitMet ?? ""),
                BaseUnitImp = x.BaseUnitImp,
                BaseUnitMet = x.BaseUnitMet
            }));


        }

        internal void CheckSelectedTraits()
        {
            var commonLists = TraitsInFieldset.Union(TraitsInChooseColumn).GroupBy(x => x.TraitID).SelectMany(y=>y) ;

            var traitLists = from x in TraitsInCrop
                             join y in commonLists on x.TraitID equals y.TraitID into tempList
                             from z in tempList.DefaultIfEmpty()
                             select new TraitAll
                             {
                                 TraitID = x.TraitID,
                                 ColumnLabel = x.ColumnLabel,
                                 DataType = x.DataType,
                                 TraitName = x.TraitName,
                                 DisplayFormat = x.DisplayFormat,
                                 Updatable = x.Updatable,
                                 TraitTypeID = x.TraitTypeID,
                                 ListOfValues = x.ListOfValues,
                                 Property = x.Property,
                                 Editor = x.Editor,
                                 ShowSum = x.ShowSum,
                                 MinValue = x.MinValue,
                                 MaxValue = x.MaxValue,
                                 Selected = z == null ? false : true,
                                 UoMCode = (UnitOfMeasure.SystemUoM == "Imperial" ? x.BaseUnitImp ?? "" : x.BaseUnitMet ?? ""),
                                 BaseUnitImp = x.BaseUnitImp,
                                 BaseUnitMet = x.BaseUnitMet
                             };
           
            TraitAll = new ObservableCollection<TraitAll>(traitLists);

        }

        internal async Task<object> GetHistoryList(List<int> traits)
        {
            return await _observationAppService.GetHistoryData(traits, TrialEZID.ToString());
        }

        internal async Task<bool> SaveToDB()
        {
            return await _observationAppService.SaveObservationDataAsync(DataObservation);
        }

        internal string  ValidateTrait(Entities.Master.Trait trait, string valueTovalidate)
        {
            return Validation.validateTrait(trait?.DataType, trait?.DisplayFormat, valueTovalidate);
        }

        internal void UpdateObservationDate()
        {
            foreach (var obs in DataObservation)
            {
                obs.DateCreated = ObsDateVal;
                obs.DateUpdated = ObsDateVal;
            }
        }

        internal void SaveDefaultTraitSet(string cropCode, int traitSetID)
        {
            defaultFieldSetService.SaveDefaultFs(cropCode, traitSetID);
        }

        internal async Task<DefaultFieldSet> GetDefaultTraitSet(string cropCode)
        {
            return await defaultFieldSetService.GetDefaultFieldSetAsync(cropCode);
        }

        internal async Task DeleteTrialImageAsync()
        {
            var fileAccessHelper = DependencyService.Get<IFileAccessHelper>();
            if(SelectedTrialImage != null)
            {
                var location = SelectedTrialImage.ImageLocation;
                var imageSource = SelectedTrialImage.ImageSource;
                if(imageSource != null)
                {

                    imageSource = null;
                }
                await fileAccessHelper.DeleteFileFromLocation(location);
            }
        }
    }
}
