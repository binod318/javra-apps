using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Input;
using TrialApp.Common;
using TrialApp.Entities.Master;
using TrialApp.Entities.Transaction;
using TrialApp.Services;
using TrialApp.ViewModels.Abstract;
using TrialApp.ViewModels.Interfaces;
using TrialApp.Views;
using Xamarin.Forms;

namespace TrialApp.ViewModels
{
    public class ObservationPageViewModel : ObservationBaseViewModel
    {
        #region private variables

        private readonly IDependencyService _dependency;
        private string _nextVarietyName;
        private string _prevVarietyName;
        private Color _nextbuttonColor;
        private Color _prevbuttonColor;
        private List<FieldSetPair> _traitSetList;
        private FieldSetService _FieldSetService;
        private bool _changedVisible;
        private bool _nextButtonEnable;
        private bool prevObsVisibleBase = false;
        private bool _prevButtonEnable;
        private string _varietyName;
        private string _fieldNumber;
        private string _variety;
        private TraitService traitSrv;
        private TraitValueService traitvalSrv;
        private readonly DefaultFieldSetService _defaultFsService;
        private readonly DefaultTraitsPerTrialService _defaultTraitsPerTrialService;
        private ImageSource _toggleResistanceIcon;

        #endregion

        #region public properties
        public string Crop { get; set; }
        public int CurrentVarietyIndex { get; set; }
        public List<VarietyData> VarList { get; set; }
        public List<Trait> TraitsOnControl { get; set; }
        public ImageSource ToggleResistanceIcon
        {
            get { return _toggleResistanceIcon; }
            set
            {
                _toggleResistanceIcon = value;
                OnPropertyChanged();
            }
        }

        public bool NextButtonEnable
        {
            get { return _nextButtonEnable; }
            set
            {
                _nextButtonEnable = value;
                OnPropertyChanged();
            }
        }

        public bool PrevObsVisibleBase
        {
            get { return prevObsVisibleBase; }
            set
            {
                prevObsVisibleBase = value;
                OnPropertyChanged();
            }
        }
        private ObservationAppHistory previousObsFilter;
        public ObservationAppHistory PreviousObsFilter
        {
            get { return previousObsFilter; }
            set
            {
                previousObsFilter = value;
                OnPropertyChanged();
            }
        }
        private string prevObsSelected;
        public string PrevObsSelected
        {
            get { return prevObsSelected; }
            set
            {
                prevObsSelected = value;
                OnPropertyChanged();
            }
        }

        public bool PrevButtonEnable
        {
            get { return _prevButtonEnable; }
            set
            {
                _prevButtonEnable = value;
                OnPropertyChanged();
            }
        }

        public bool ChangedVisible
        {
            get { return _changedVisible; }
            set
            {
                _changedVisible = value;
                OnPropertyChanged();
            }
        }

        public ICommand FieldsetChangeCommand { get; set; }

        public ICommand NextCommand { get; set; }
        public ICommand PrevCommand { get; set; }

        public string VarietyName
        {
            get { return _varietyName; }
            set
            {
                _varietyName = value;
                OnPropertyChanged();
            }
        }

        public string FieldNumber
        {
            get { return _fieldNumber; }
            set
            {
                _fieldNumber = value;
                OnPropertyChanged();
            }
        }

        public string Variety
        {
            get { return _variety; }
            set
            {
                _variety = value;
                OnPropertyChanged();
            }
        }

        public Color NextButtonColor
        {
            get { return _nextbuttonColor; }
            set
            {
                _nextbuttonColor = value;
                OnPropertyChanged();
            }
        }
        public Color PrevButtonColor
        {
            get { return _prevbuttonColor; }
            set
            {
                _prevbuttonColor = value;
                OnPropertyChanged();
            }
        }

        public string NextVarietyName
        {
            get { return _nextVarietyName; }
            set
            {
                _nextVarietyName = value;
                OnPropertyChanged();
            }
        }
        public string PrevVarietyName
        {
            get { return _prevVarietyName; }
            set
            {
                _prevVarietyName = value;
                OnPropertyChanged();
            }
        }

        public List<FieldSetPair> TraitSetList
        {
            get { return _traitSetList; }
            set
            {
                _traitSetList = value;
                OnPropertyChanged();
            }
        }
        
        public TraitService TraitSrv
        {
            get { return traitSrv; }
            set
            {
                traitSrv = value;
                OnPropertyChanged();
            }
        }
        public TraitValueService TraitvalSrv
        {
            get { return traitvalSrv; }
            set
            {
                traitvalSrv = value;
                OnPropertyChanged();
            }
        }

        public TrialEntryAppService TrialEntryAppService { get; set; }

        public List<Entities.Master.Trait> TraitsPerCrop { get; set; }
        



        #endregion

        /// <summary>
        /// 
        /// </summary>
        /// <param name="name"></param>
        /// <param name="id"></param>
        /// <param name="crop"></param>
        /// <param name="varList"></param>
        public ObservationPageViewModel()
        {
            TraitSetList = new List<FieldSetPair>();
            TraitSrv = new TraitService();
            TraitvalSrv = new TraitValueService();
            TrialEntryAppService = new TrialEntryAppService();
            TraitsOnControl = new List<Trait>();
            _FieldSetService = new FieldSetService();
            TrialService = new TrialService();
            ObservationService = new ObservationAppService();
            _defaultFsService = new DefaultFieldSetService();
            _defaultTraitsPerTrialService = new DefaultTraitsPerTrialService();

            FieldsetChangeCommand = new FieldsetChangeOperation();
            Validation = new TraitFieldValidation();
            NextCommand = new NextOperation();
            PrevCommand = new PreviousOperation();
            FieldsetPickerEnabled = true;
            ToggleResistanceIcon = ImageSource.FromFile("Assets/showresist.png");
            ResistanceStackVisible = false;
            ReOrderTraitList = new List<ReOrderTrait>();
            TraitsPerCrop = new List<Entities.Master.Trait>();
        }

        public ObservationPageViewModel(IDependencyService dependencyService)
        {
            _dependency = dependencyService;
        }

        public void LoadFieldsset()
        {
            var firstFieldset = new FieldSetPair() { Id = 0, Name = "<choose traitset>" };
            TraitSetList.Add(firstFieldset);

            var fieldSets = _FieldSetService.GetFieldSetList(Crop);

            foreach (var val in fieldSets)
            {
                var fieldset = new FieldSetPair()
                {
                    Id = Convert.ToInt32(val.FieldSetID),
                    Name = val.FieldSetName
                };
                TraitSetList.Add(fieldset);
            }
        }

        public void SelectDefaultFS()
        {
            //First load default traitset from Trial level
            var selectedIndex = 0;
            var trialInfo = TrialService.GetTrialInfo(TrialEzId);
            if (trialInfo != null && trialInfo.DefaultTraitSetID != 0)
            {
                selectedIndex = TraitSetList.IndexOf(TraitSetList.Find(x => x.Id == trialInfo.DefaultTraitSetID));
            }
            else // If default traitset is null in Trial level then Load selected Traitset from DefaultFieldset table
            {
                var defaultfs = _defaultFsService.GetDefaultFs(Crop);
                if (defaultfs != null)
                {
                    int.TryParse(defaultfs.Fieldset, out int selectedFs);
                    selectedIndex = TraitSetList.IndexOf(TraitSetList.Find(x => x.Id == selectedFs));
                }
            }
            PickerSelectedIndex = selectedIndex == -1 ? 0 : selectedIndex;
        }

        public void LoadObservationViewModel(string id, string crop, List<VarietyData> varList, int trialEzid)
        {
            Crop = crop;
            EzId = id;
            VarList = varList;
            TrialEzId = trialEzid;
            LoadVarietyInfo(EzId);
            UpdateDisplayUi();
        }

        public async void LoadVarietyInfo(string VarietyId)
        {
            var currentItem = VarList.Find(x => x.VarietyId == VarietyId);
            CurrentVarietyIndex = VarList.IndexOf(currentItem);
            VarietyName = currentItem.FieldNumber + " " + currentItem.VarietyName;
            FieldNumber = currentItem.FieldNumber;
            Variety = currentItem.VarietyName;

            // Disable NEXT button if last item in the list is selected
            if (VarList.ElementAtOrDefault(CurrentVarietyIndex + 1) != null)
            {
                var nextVarName = VarList[CurrentVarietyIndex + 1].FieldNumber + " " + VarList[CurrentVarietyIndex + 1].VarietyName;
                NextVarietyName = "NEXT: " + nextVarName;
                NextButtonEnable = true;
            }
            else
            {
                NextVarietyName = "NEXT: ";
                NextButtonEnable = false;
            }
            // Disable PREV button if First item in the list is selected
            if (VarList.ElementAtOrDefault(CurrentVarietyIndex - 1) != null)
            {
                var PrevVarName = VarList[CurrentVarietyIndex - 1].FieldNumber + " " + VarList[CurrentVarietyIndex - 1].VarietyName;
                PrevVarietyName = "PREV: " + PrevVarName;
                PrevButtonEnable = true;
            }
            else
            {
                PrevVarietyName = "PREV: ";
                PrevButtonEnable = false;
            }

            if (TrialEntryAppService == null) return;

            // Load Resistance Information
            var varietyInfo = await TrialEntryAppService.GetVarietiesInfoAsync(VarietyId);

            ResistanceHr = new Trait()
            {
                ColumnLabel = "Res. HR",
                ObsValue = varietyInfo.ResistanceHR,
            };

            ResistanceIr = new Trait()
            {
                ColumnLabel = "Res. IR",
                ObsValue = varietyInfo.ResistanceIR
            };

            ResistanceT = new Trait()
            {
                ColumnLabel = "Res. T",
                ObsValue = varietyInfo.ResistanceT
            };

        }
        /// <summary>
        /// Change the header and button color according to the status
        /// </summary>
        public void UpdateDisplayUi()
        {
            var status = TrialService.GetTrialInfo(TrialEzId);
            if (status.StatusCode == 30)
                UpdatedUi();
            else
                NormalUi();
        }

        public async Task<int> GetDefaultTraitsPerTrials()
        {
            //load local traits defined per trial, Only if this column doesn't exist then go for existing logic
            var data = await _defaultTraitsPerTrialService.GetAsync(TrialEzId);
            if (!data.Any())
                return 0;

            var traits = await TraitSrv.GetTraitsDetailAsync(string.Join(",", data.Select(o => o.TraitID)));

            var orderedTraits = (from option in traits
                             join type in data
                             on option.TraitID equals type.TraitID
                             orderby type.Order
                             select option).ToList();

            DefaultTraitlistPerTrial = orderedTraits;

            return data.FirstOrDefault().FieldsetID;
        }

        public async Task LoadTraits(bool fieldsetChange)
        {
            var orderedTraits = new List<Entities.Master.Trait>();

            //if triggerred by changing fieldset then display all traits from fieldset
            if(fieldsetChange)
            {
                orderedTraits = TraitSrv.GetTraitList(SelectedFieldset.Value);
            }
            else
            {
                if (DefaultTraitlistPerTrial == null)
                    await GetDefaultTraitsPerTrials();

                if(DefaultTraitlistPerTrial == null)
                    orderedTraits = TraitSrv.GetTraitList(SelectedFieldset.Value);
                else
                    orderedTraits = DefaultTraitlistPerTrial;
            }

            //Insert extra row for calculated sum
            var traitsWithShowSum = orderedTraits.Where(x => x.ShowSum).ToList();

            foreach (var val in traitsWithShowSum)
            {
                var newTrait = new Entities.Master.Trait()
                {
                    TraitID = val.TraitID,
                    Updatable = false,
                    ColumnLabel = "Sum",
                    TraitName = "Sum of " + val.TraitName,
                    BaseUnitImp = "",
                    BaseUnitMet = "",
                    ShowSum = val.ShowSum,
                    DataType = val.DataType,
                    DisplayFormat = val.DisplayFormat,
                    Editor = val.Editor,
                    ListOfValues = val.ListOfValues,
                    MaxValue = val.MaxValue,
                    MinValue = val.MinValue,
                    Property = val.Property,
                    TraitTypeID = val.TraitTypeID
                };

                var indexofY = orderedTraits.IndexOf(val);

                orderedTraits.Insert(indexofY + 1, newTrait);
            }

            // Get normal observation value for traits 
            var traitIdList = string.Join(",", orderedTraits.Distinct().Select(x => x.TraitID.ToString()));
            await GetObsValueList(string.Format("'{0}'", EzId), traitIdList); //EZID is sent with quoted format because where clause on ezid is changed to in () so need single type data.

            // Get cumulated observation for cumulated traits
            traitIdList = string.Join(",", traitsWithShowSum.Distinct().Select(x => x.TraitID.ToString()));
            await GetCumulatedObsValue(string.Format("'{0}'", EzId), traitIdList);

            TraitList = new List<Trait>( orderedTraits.Select( x => 
            {
                var unit = UnitOfMeasure.SystemUoM == "Imperial" ? x.BaseUnitImp ?? "" : x.BaseUnitMet ?? "";
                unit = string.IsNullOrEmpty(unit) ? "" : " (" + unit + ") ";
                var trait = new Trait()
                {
                    ColumnLabel = x.ColumnLabel + unit,
                    DataType = x.DataType,
                    DisplayFormat = x.DisplayFormat,
                    Editor = x.Editor,
                    ListOfValues = x.ListOfValues,
                    MaxValue = x.MaxValue,
                    MinValue = x.MinValue,
                    Property = x.Property,
                    TraitID = x.TraitID,
                    TraitName = x.TraitName,
                    Updatable = x.Updatable,
                    Updatable1 = x.Updatable,
                    TraitTypeID = x.TraitTypeID,
                    ListVisible = x.ListOfValues,
                    Tag = x.TraitID.ToString() + "|" + x.DataType + "|" + x.DisplayFormat,
                    CharVisible = (!x.ListOfValues && string.IsNullOrEmpty(x.DataType)) || ((!x.ListOfValues && !string.IsNullOrEmpty(x.DataType) && x.DataType.ToLower() == "c") ? true : false),
                    DateVisible = (x.ListOfValues || !string.IsNullOrEmpty(x.DataType)) && ((!x.ListOfValues && !string.IsNullOrEmpty(x.DataType) && x.DataType.ToLower() == "d") ? true : false),
                    IntOrDecVisible = (x.ListOfValues || !string.IsNullOrEmpty(x.DataType)) && ((!x.ListOfValues && !string.IsNullOrEmpty(x.DataType) && (x.DataType.ToLower() == "i" || x.DataType.ToLower() == "a")) ? true : false),
                    ListSource = x.ListOfValues ? TraitvalSrv.GetTraitValueWithID(x.TraitID, Crop) : null,
                    ObsValue = GetObservationValue(GetObsValue(x.TraitID), x.DataType.ToLower(), x.ColumnLabel),
                    ValidationErrorVisible = false,
                    ChangedValueVisible = false,
                    DatePickerVisible = false,
                    PrevObsVisible = prevObsVisibleBase,
                    RevertVisible = false,
                    UoMCode = (UnitOfMeasure.SystemUoM == "Imperial" ? x.BaseUnitImp ?? "" : x.BaseUnitMet ?? ""),
                    Description = x.Description
                };
                //DateTime.ParseExact(trait.ObsValue.Split('T')[0], "yyyy-MM-dd", CultureInfo.InvariantCulture).ToString()
                trait.DateValue = (trait.DateVisible && trait.ObsValue != "") ? DateTime.ParseExact(trait.ObsValue.Split('T')[0], "yyyy-MM-dd", CultureInfo.InvariantCulture) : (DateTime?)null;
                trait.DateValueString = (trait.DateVisible && trait.ObsValue != "") ? (trait.ObsValue.Split('T')[0]) : "";
                trait.ObsvalueInitial = trait.DateVisible ? trait.DateValueString : trait.ObsValue;
                trait.ValueBeforeChanged = trait.ObsvalueInitial;
                return trait;
            }).ToList());
            TraitsOnControl = TraitList;
            // save selected Traitset as default traitset
            if ( SelectedFieldset != null )
                _defaultFsService.SaveDefaultFs(Crop, SelectedFieldset.Value);

            var traits = string.Join(",", TraitList.Select(x => x.TraitID));
            await GetHistoryObservationWithDate(EzId, traits);

            if (HistoryObservations.Any())
                PreviousObsFilter = HistoryObservations[0];

        }

        public async Task FetchFieldsetTraits(int fieldsetId)
        {
            var traits = TraitSrv.GetTraitList(fieldsetId);

            FieldsetTraits = new List<Trait>(traits.Select(x =>
            {
                var unit = UnitOfMeasure.SystemUoM == "Imperial" ? x.BaseUnitImp ?? "" : x.BaseUnitMet ?? "";
                unit = string.IsNullOrEmpty(unit) ? "" : " (" + unit + ") ";
                var trait = new Trait()
                {
                    ColumnLabel = x.ColumnLabel + unit,
                    TraitID = x.TraitID,
                };
                return trait;
            }).ToList());

            await Task.Delay(10);
        }

        /// <summary>
        /// this method will just update value of traits for next and previous button click... some issues with picker change value need to implement later.
        /// </summary>
        /// <returns></returns>
        public async Task GetNextAndPrevTraitData()
        {
            if (TraitList == null)
                return;
            var traitIdList = string.Join(",", TraitList.Select(x => x.TraitID.ToString()));
            await GetObsValueList(string.Format("'{0}'", EzId), traitIdList);  //EZID is sent with quoted format because where clause on ezid is changed to in () so need single type data.          
            foreach (var _val in TraitList)
            {
                _val.ObsValue = GetObservationValue(GetObsValue(_val.TraitID), _val.DataType.ToLower(), _val.ColumnLabel);
                _val.ValidationErrorVisible = false;
                _val.ChangedValueVisible = false;
                _val.DatePickerVisible = false;
                _val.PrevObsVisible = prevObsVisibleBase;
                _val.RevertVisible = false;
                _val.DateValue = (_val.DateVisible && _val.ObsValue != "") ? DateTime.ParseExact(_val.ObsValue.Split('T')[0], "yyyy-MM-dd", CultureInfo.InvariantCulture) : (DateTime?)null;
                _val.DateValueString = (_val.DateVisible && _val.ObsValue != "") ? (_val.ObsValue.Split('T')[0]) : "";
                _val.ObsvalueInitial = _val.DateVisible ? _val.DateValueString : _val.ObsValue;
                _val.ValueBeforeChanged = _val.ObsvalueInitial;
            }
        }

        public override void NormalUi()
        {
            base.NormalUi();
            NextButtonColor = Color.FromHex("#4a90e2");
            PrevButtonColor = Color.FromHex("#4a90e2");
            ChangedVisible = false;
        }

        public override void UpdatedUi()
        {
            base.UpdatedUi();
            ChangedVisible = true;
            NextButtonColor = Color.Green;
            PrevButtonColor = Color.Green;
        }

        public void LoadReOrderTraitList()
        {
            var list = new List<ReOrderTrait>();

            if(DefaultTraitlistPerTrial != null)
                list = DefaultTraitlistPerTrial.Select(o => new ReOrderTrait { TraitID = o.TraitID, ColumnLabel = o.ColumnLabel, IsChecked = true }).ToList();

            //if traits selected already
            if(list.Any())
            {
                var traitsFromFieldset = FieldsetTraits.Where(p => list.All(p2 => p2.TraitID != p.TraitID)).Select(o => new ReOrderTrait { TraitID = o.TraitID, ColumnLabel = o.ColumnLabel, IsChecked = false }).ToList();
                list.AddRange(traitsFromFieldset);
            }
            //No traits selected per trial yet
            else
            {
                var traitsFromFieldset = FieldsetTraits.Select(o => new ReOrderTrait { TraitID = o.TraitID, ColumnLabel = o.ColumnLabel, IsChecked = true }).ToList();
                list.AddRange(traitsFromFieldset);
            }

            ReOrderTraitList = list;
            TraitsOnControl = ReOrderTraitList.Select(o => new Trait {TraitID = o.TraitID, ColumnLabel = o.ColumnLabel }).ToList();
        }

        internal async Task UpdateUserControl()
        {
            int indx = 0;
            foreach (var itm in TraitList)
            {
                
                if (previousObsFilter != null)
                {
                    if (prevObsVisibleBase)
                    {
                        var trt = TraitsOnControl[indx];
                        var obObj = await ObservationService.GetObservationDateByUserByDate(previousObsFilter.DateCreated, previousObsFilter.UserIDCreated, EzId, trt.TraitID);
                        if (obObj != null)
                            itm.PrevObsValue = GetObservationValue(obObj, trt.DataType.ToLower(), "FromPrevObs");


                    }
                    itm.PrevObsVisible = prevObsVisibleBase;
                    indx++;

                }
            }
        }

        public async Task SaveDefaultTraits()
        {
            int order = 1;
            var listTraits = new List<DefaultTraitsPerTrial>();
            var checkedTraits = ReOrderTraitList.Where(o => o.IsChecked);

            //Save columns info before exit
            foreach (var column in checkedTraits)
            {
                listTraits.Add(new DefaultTraitsPerTrial { EZID = TrialEzId, TraitID = column.TraitID, Order = order, FieldsetID = SelectedFieldset == null ? 0 : (int)SelectedFieldset });
                order++;
            }

            await _defaultTraitsPerTrialService.SaveAsync(listTraits);
        }

        public async Task loadTraitPerCrop(string cropCode)
        {
            TraitsPerCrop = await traitSrv.GetAllTraitsAsync(cropCode);
        }
    }

    public class NextOperation : ICommand
    {
        public bool CanExecute(object parameter)
        {
            return true;
        }

        public async void Execute(object parameter)
        {
            var observationPageViewModel = parameter as ObservationPageViewModel;
            var nextVar = observationPageViewModel?.VarList[observationPageViewModel.CurrentVarietyIndex + 1];
            if (nextVar != null)
            {
                observationPageViewModel.PrevObsVisibleBase = false;
                observationPageViewModel.EzId = nextVar.VarietyId;
                observationPageViewModel.LoadVarietyInfo(observationPageViewModel.EzId);
                //if (observationPageViewModel.SelectedFieldset.HasValue)
                    await observationPageViewModel.LoadTraits(false);
            }
        }
        public event EventHandler CanExecuteChanged;
    }
    public class PreviousOperation : ICommand
    {
        public bool CanExecute(object parameter)
        {
            return true;
        }

        public async void Execute(object parameter)
        {
            var observationPageViewModel = parameter as ObservationPageViewModel;
            observationPageViewModel.PrevObsVisibleBase = false;
            var prevVar = observationPageViewModel?.VarList[observationPageViewModel.CurrentVarietyIndex - 1];
            if (prevVar != null)
            {
                observationPageViewModel.EzId = prevVar.VarietyId;
                observationPageViewModel.LoadVarietyInfo(observationPageViewModel.EzId);
                //if (observationPageViewModel.SelectedFieldset.HasValue)
                    await observationPageViewModel.LoadTraits(false);
            }
        }

        public event EventHandler CanExecuteChanged { add { } remove { } }
    }

    public class FieldsetChangeOperation : ICommand
    {
        public bool CanExecute(object parameter)
        {
            return true;
        }

        public void Execute(object parameter)
        {

        }

        public event EventHandler CanExecuteChanged;
    }

    public class FieldSetPair
    {
        public int Id { get; set; }
        public string Name { get; set; }
    }
    public class TraitAll : Entities.Master.Trait
    {
        public bool Selected { get; set; }
        public string UoMCode { get; set; }
    }

    public class Trait : ObservableViewModel
    {
        private bool _updatable;
        public int TraitID { get; set; }
        public int? TraitTypeID { get; set; }
        public string TraitName { get; set; }
        public string ColumnLabel { get; set; }
        private bool validationErrorVisible;
        public string ObsvalueInitial { get; set; }
        private bool revertVisible;

        public bool RevertVisible
        {
            get { return revertVisible; }
            set
            {
                revertVisible = value;
                OnPropertyChanged();
            }
        }
        public bool ValidationErrorVisible
        {
            get { return validationErrorVisible; }
            set
            {
                validationErrorVisible = value;
                OnPropertyChanged();
            }
        }
        private bool changedValueVisible;
        public bool ChangedValueVisible
        {
            get { return changedValueVisible; }
            set
            {
                changedValueVisible = value;
                OnPropertyChanged();
            }
        }
        private string dataType;
        private bool listVisible;
        public bool ListVisible
        {
            get { return listVisible; }
            set { listVisible = value; }
        }
        private bool charVisible;
        public bool CharVisible
        {
            get { return charVisible; }
            set { charVisible = value; }
        }
        private bool dateVisible;
        private bool datePickerVisible;
        private string dateValueString;
        public string DateValueString
        {
            get { return dateValueString; }
            set
            {
                dateValueString = value;
                OnPropertyChanged();
            }
        }

        private bool prevObsVisible = false;

        public bool PrevObsVisible
        {
            get { return prevObsVisible; }
            set
            {
                prevObsVisible = value;
                OnPropertyChanged();
            }
        }
        public bool DatePickerVisible
        {
            get { return datePickerVisible; }
            set
            {
                datePickerVisible = value;
                OnPropertyChanged();
            }
        }
        public bool DateVisible
        {
            get { return dateVisible; }
            set
            {
                dateVisible = value;
                OnPropertyChanged();
            }
        }
        private DateTime? dateValue;
        public DateTime? DateValue
        {
            get { return dateValue; }
            set
            {
                dateValue = value;
                DateValueString = dateValue?.ToString("yyyy-MM-dd");
                OnPropertyChanged();
            }
        }

        private bool intOrDecVisible;
        public bool IntOrDecVisible
        {
            get { return intOrDecVisible; }
            set { intOrDecVisible = value; }
        }
        public string DataType
        {
            get { return dataType; }
            set { dataType = value; }
        }

        public bool Updatable
        {
            get { return _updatable; }
            set
            {
                _updatable = value;
                OnPropertyChanged();
            }
        }

        public bool Updatable1 { get; set; }
        public string DisplayFormat { get; set; }
        public bool Editor { get; set; }
        private bool listOfValues;

        public bool ListOfValues
        {
            get { return listOfValues; }
            set { listOfValues = value; }
        }
        private string tag;
        public string Tag
        {
            get { return tag; }
            set { tag = value; }
        }

        private string obsValue;

        public string ObsValue
        {
            get { return obsValue; }
            set
            {
                obsValue = value;
                if (ListVisible)
                {
                    ObsItemPicker = ListSource?.FirstOrDefault(o => o.TraitValueCode == obsValue);
                }
                OnPropertyChanged();
            }
        }

        private string prevObsValue="";

        public string PrevObsValue
        {
            get { return prevObsValue; }
            set
            {
                prevObsValue = value;
                OnPropertyChanged();
            }
        }

        private TraitValue obsItemPicker;

        public TraitValue ObsItemPicker
        {
            get { return obsItemPicker; }
            set
            {
                obsItemPicker = value;
                OnPropertyChanged();
            }
        }

        public string ValueBeforeChanged { get; set; }

        public int? MinValue { get; set; }
        public int? MaxValue { get; set; }
        public bool Property { get; set; }
        private ObservableCollection<TraitValue> listSource;
        
        public ObservableCollection<TraitValue> ListSource
        {
            get { return listSource; }
            set
            {
                listSource = value;
                OnPropertyChanged();
            }
        }
        public string UoMCode { get; set; }
        public string Description { get; set; }
    }

    public class ReOrderTrait : ObservableViewModel
    {
        private bool isChecked;

        public int TraitID { get; set; }
        public string ColumnLabel { get; set; }
        public bool IsChecked
        {
            get { return isChecked; }
            set
            {
                isChecked = value;
                OnPropertyChanged();
            }
        }

    }
}
