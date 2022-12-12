using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TrialApp.Common;
using TrialApp.Entities.Master;
using TrialApp.Entities.Transaction;
using TrialApp.Services;
using TrialApp.ViewModels.Abstract;
using Xamarin.Forms;

namespace TrialApp.ViewModels
{
    public class TrialPropertiesPageViewModel : ObservationBaseViewModel
    {
        #region private variables

        private readonly FieldSetService _fieldSetService;
        private readonly TraitService _traitService;
        private readonly TraitValueService _traitValueService;
        private ObservableCollection<FieldSetPair> _propertySetList;
        private ObservableCollection<TraitValue> _statusSetList;
        //private readonly INavigation _navigation;

        //public string getTraitValueByID(int v)
        //{
        //    var obs = GetObsValue(v);
        //    return obs.ObsValueChar;
        //}

        private string _currentTrial;
        private string _cropCode;
        private TrialLookUp _trial;

        #endregion

        #region public properties

        public Entities.Transaction.TrialLookUp Trial
        {
            get { return _trial; }
            set { _trial = value; OnPropertyChanged(); }
        }
        public string CropCode
        {
            get { return _cropCode; }
            set { _cropCode = value; OnPropertyChanged(); }
        }

        public ObservableCollection<FieldSetPair> PropertySetList
        {
            get { return _propertySetList; }
            set { _propertySetList = value; OnPropertyChanged(); }
        }
        public ObservableCollection<TraitValue> StatusSetList
        {
            get { return _statusSetList; }
            set { _statusSetList = value; OnPropertyChanged(); }
        }

        public string CurrentTrial
        {
            get { return _currentTrial; }
            set { _currentTrial = value; OnPropertyChanged(); }
        }

        private TraitValue _selectedStatus;

        public TraitValue SelectedStatus
        {
            get { return _selectedStatus; }
            set { _selectedStatus = value; OnPropertyChanged(); }
        }

        public string InitialStatus { get; set; }



        #endregion

        public TrialPropertiesPageViewModel(int ezid, string crop)
        {
            CropCode = crop;
            EzId = ezid.ToString();
            TrialEzId = ezid;
            PropertySetList = new ObservableCollection<FieldSetPair>();
            StatusSetList = new ObservableCollection<TraitValue>();
            _fieldSetService = new FieldSetService();
            _traitService = new TraitService();
            _traitValueService = new TraitValueService();
            ObservationService = new ObservationAppService();
            Validation = new TraitFieldValidation();
            TraitList = new List<Trait>();
            ObsValueList = new List<ObservationAppLookup>();
            TrialService = new TrialService();
            SelectedStatus = new TraitValue();
        }

        public void LoadTrialName()
        {
            Trial = TrialService.GetTrialInfo(TrialEzId);

            if (Trial == null) return;

            CurrentTrial = Trial.TrialName;
            if (Trial.StatusCode == 30)
                UpdatedUi();
            else
                NormalUi();
        }

        /// <summary>
        /// Load list of Property set in Propertyset picker
        /// </summary>
        /// <param name="crop"></param>
        public void LoadFieldsset(string crop)
        {
            var firstFieldset = new FieldSetPair() { Id = 0, Name = "<choose propertyset>" };
            PropertySetList.Add(firstFieldset);

            var fieldSets = _fieldSetService.GetPropertySetList(crop);

            foreach (var val in fieldSets)
            {
                var fieldset = new FieldSetPair()
                {
                    Id = Convert.ToInt32(val.FieldSetID),
                    Name = val.FieldSetName
                };
                PropertySetList.Add(fieldset);
            }

            //Always select first propertyset
            if (PropertySetList.Count() > 1)
                PickerSelectedIndex = 1;
            else
                PickerSelectedIndex = 0;
        }

        /// <summary>
        /// Load list of Trial Status set in statusset picker
        /// </summary>
        /// <param name="crop"></param>
        public async Task LoadStatusset()
        {
            //Get List of status for dropdown list
            StatusSetList = _fieldSetService.GetStatusSetList(CropCode);

            //Get Observation value for Status for selected trial
            await GetPropObsValueList(EzId, "4185");
            InitialStatus = ObsValueList.FirstOrDefault().ObsValueChar;

            //Select value from database on dropdown 
            SelectedStatus = StatusSetList.FirstOrDefault(o => o.TraitValueCode == InitialStatus);
        }

        public async Task LoadProperties(int fieldsetId)
        {
            var traits = _traitService.GetTraitList(fieldsetId);
            var traitIdList = string.Join(",", traits.Select(x => x.TraitID.ToString()));
            await GetPropObsValueList(string.Format("'{0}'", TrialEzId.ToString()), traitIdList); //EZID is sent with quoted format because where clause on ezid is changed to in () so need single type data.

            TraitList = new List<Trait>(traits.Select(x =>
            {
                var unit = UnitOfMeasure.SystemUoM == "Imperial" ? x.BaseUnitImp ?? "" : x.BaseUnitMet ?? "";
                unit = string.IsNullOrEmpty(unit) ? "" : " (" + unit + ") ";
                var trait = new Trait
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
                    CharVisible = (!x.ListOfValues && string.IsNullOrEmpty(x.DataType)) || ((!x.ListOfValues && !string.IsNullOrEmpty(x.DataType) && x.DataType.ToLower() == "c") ? true : false),//datatype c=char, i=int,d=date,a=dec
                    DateVisible = (x.ListOfValues || !string.IsNullOrEmpty(x.DataType)) && ((!x.ListOfValues && !string.IsNullOrEmpty(x.DataType) && x.DataType.ToLower() == "d") ? true : false),
                    IntOrDecVisible = (x.ListOfValues || !string.IsNullOrEmpty(x.DataType)) && ((!x.ListOfValues && !string.IsNullOrEmpty(x.DataType) && (x.DataType.ToLower() == "i" || x.DataType.ToLower() == "a")) ? true : false),
                    ListSource = x.ListOfValues ? _traitValueService.GetTraitValueWithID(x.TraitID, CropCode) : null,
                    ObsValue = GetObservationValueProp(GetObsValue(x.TraitID), x.DataType.ToLower(), x.ColumnLabel),
                    ValidationErrorVisible = false,
                    ChangedValueVisible = false,
                    DatePickerVisible = false,
                    UoMCode = (UnitOfMeasure.SystemUoM == "Imperial" ? x.BaseUnitImp ?? "" : x.BaseUnitMet ?? ""),
                    Description = x.Description
                };
                trait.DateValue = (trait.DateVisible && trait.ObsValue != "") ? DateTime.ParseExact(trait.ObsValue.Split('T')[0], "yyyy-MM-dd", CultureInfo.InvariantCulture) : (DateTime?)null;
                trait.ObsvalueInitial = trait.DateValue?.ToString("yyyy-MM-dd") ?? trait.ObsValue;
                return trait;
            }).ToList());
        }
    }
}
