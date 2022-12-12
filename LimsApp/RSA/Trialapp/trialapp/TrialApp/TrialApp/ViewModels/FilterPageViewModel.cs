using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Collections.Specialized;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Input;
using TrialApp.Common.Extensions;
using TrialApp.Entities.Master;
using TrialApp.Entities.Transaction;
using TrialApp.Services;
using TrialApp.ViewModels.Interfaces;
using Model;

namespace TrialApp.ViewModels
{
    public class FilterPageViewModel : BaseViewModel
    {
        #region private variables

        private bool _disableFilter;
        private bool _toggleFilter;

        #endregion

        public ObservableCollection<TrialType> TrialTypeListFromDb { get; set; }

        public ObservableCollection<CropRD> CropListFromDb { get; set; }
        public ObservableCollection<CropSegment> CropSegmentListFromDb { get; set; }
        public ObservableCollection<TrialRegion> TrialRegionListFromDb { get; set; }
        public ObservableCollection<Country> CountryListFromDb { get; set; }
        public List<Entities.Transaction.TrialLookUp> TrialList { get; set; }
        public ICommand ApplyFilterCommand { get; set; }

        public ICommand CancelFilterCommand { get; set; }
        public bool ToggleFilter
        {
            get { return _toggleFilter; }
            set { _toggleFilter = value; OnPropertyChanged(); }
        }
        public bool DisableFilter
        {
            get { return _disableFilter; }
            set { _disableFilter = value; OnPropertyChanged(); }
        }
        
        private readonly CropRdService _cropRdService;
        private readonly CountryService _countryService;
        private readonly TrialTypeService _trialTypeService;
        private readonly TrialRegionService _trialRegionService;
        private readonly SettingParametersService _settingParametersService;
        private readonly CropSegmentService _cropSegmentService;
        private readonly ObservationAppService _observationAppService;
        private readonly TraitService _traitService;
        private readonly TraitValueService _traitValueService;
        public readonly SaveFilterService SaveFilterService;
        public FilterPageViewModel(List<TrialLookUp> allTrials)
        {
            TrialList = allTrials;
            _cropRdService = new CropRdService();
            _countryService = new CountryService();
            _trialTypeService = new TrialTypeService();
            _trialRegionService = new TrialRegionService();
            _settingParametersService = new SettingParametersService();
            _cropSegmentService = new CropSegmentService();
            _observationAppService = new ObservationAppService();
            _traitService = new TraitService();
            _traitValueService = new TraitValueService();
            SaveFilterService = new SaveFilterService();

            ApplyFilterCommand = new ApplyfilterOperation();
            CancelFilterCommand = new CancelOperation();
            var settingparams = _settingParametersService.GetParamsList().Single();
            ToggleFilter = settingparams.Filter;

            //Initially make multi picker visible
            Property1MultipickerVisible = true;
            Property1EntryVisible = false;
            Property2MultipickerVisible = true;
            Property2EntryVisible = false;
            Property3MultipickerVisible = true;
            Property3EntryVisible = false;

            //Load property list value
            Propertylist = new List<Entities.Master.Trait>();
        }

        public async Task LoadFilterProperties()
        {
            var trialList = string.Join(",", TrialList.Select(x => x.EZID));
            var propertyList = await _observationAppService.LoadPropertiesHavingObservation(trialList);
            var traitIDs = string.Join(",", propertyList.Select(x => x.TraitID.ToString()));
            if (!string.IsNullOrWhiteSpace(traitIDs))
            {
                var data = await _traitService.GetTraitsAsync(traitIDs);
                Propertylist = data;
            }
        }

        public FilterPageViewModel(IDependencyService dependencyService)
        {
            DependencyService = dependencyService;
        }

        #region crop
        private ObservableCollection<MyType> _cropList;

        public ObservableCollection<MyType> CropList
        {
            get { return _cropList; }
            set
            {
                _cropList = value;
                OnPropertyChanged();
            }
        }
        private ObservableCollection<MyType> _cropSelected;

        public ObservableCollection<MyType> CropSelected
        {
            get { return _cropSelected; }
            set
            {
                _cropSelected = value;
                OnPropertyChanged();
                //if (Equals(value, _cropSelected)) return;
                //if (_cropSelected != null)
                //    _cropSelected.CollectionChanged -= CropItemsCollectionChanged;
                //_cropSelected = value;
                //if (value != null)
                //    _cropSelected.CollectionChanged += CropItemsCollectionChanged;
                ////OnPropertyChanged();
            }
        }
        #endregion
        #region TrialType
        private ObservableCollection<MyType> _trialTypeList;

        public ObservableCollection<MyType> TrialTypeList
        {
            get { return _trialTypeList; }
            set
            {
                _trialTypeList = value;
                OnPropertyChanged();
            }
        }
        private ObservableCollection<MyType> _trialTypeSelected;

        public ObservableCollection<MyType> TrialTypeSelected
        {
            get { return _trialTypeSelected; }
            set
            {
                _trialTypeSelected = value;
                OnPropertyChanged();

                //if (Equals(value, _trialTypeSelected)) return;
                //if (_trialTypeSelected != null)
                //    _trialTypeSelected.CollectionChanged -= TrialTypeItemsCollectionChanged;
                //_trialTypeSelected = value;
                //if (value != null)
                //    _trialTypeSelected.CollectionChanged += TrialTypeItemsCollectionChanged;
            }
        }
        #endregion
        #region cropsegment
        private ObservableCollection<MyType> _cropSegmentList;

        public ObservableCollection<MyType> CropSegmentList
        {
            get { return _cropSegmentList; }
            set
            {
                _cropSegmentList = value;
                OnPropertyChanged();
            }
        }
        private ObservableCollection<MyType> _cropSegmentSelected;

        public ObservableCollection<MyType> CropSegmentSelected
        {
            get { return _cropSegmentSelected; }
            set
            {
                _cropSegmentSelected = value;
                OnPropertyChanged();
                //if (Equals(value, _cropSegmentSelected)) return;
                //if (_cropSegmentSelected != null)
                //    _cropSegmentSelected.CollectionChanged -= CropSegmentItemsCollectionChanged;
                //_cropSegmentSelected = value;
                //if (value != null)
                //    _cropSegmentSelected.CollectionChanged += CropSegmentItemsCollectionChanged;


            }
        }
        #endregion
        #region trialregion
        private ObservableCollection<MyType> _trialRegionList;
        public ObservableCollection<MyType> TrialRegionList
        {
            get { return _trialRegionList; }
            set
            {
                _trialRegionList = value;
                OnPropertyChanged();
            }
        }
        private ObservableCollection<MyType> _trialRegionSelected;
        public ObservableCollection<MyType> TrialRegionSelected
        {
            get { return _trialRegionSelected; }
            set
            {
                _trialRegionSelected = value;
                OnPropertyChanged();
                //if (Equals(value, _trialRegionSelected)) return;
                //if (_trialRegionSelected != null)
                //    _trialRegionSelected.CollectionChanged -= TrialRegionItemsCollectionChanged;
                //_trialRegionSelected = value;
                //if (value != null)
                //    _trialRegionSelected.CollectionChanged += TrialRegionItemsCollectionChanged;

            }
        }
        #endregion
        #region Country
        private ObservableCollection<MyType> _countrylist;
        public ObservableCollection<MyType> CountryList
        {
            get { return _countrylist; }
            set
            {
                _countrylist = value;
                OnPropertyChanged();
            }
        }
        private ObservableCollection<MyType> _countrySelected;
        public ObservableCollection<MyType> CountrySelected
        {
            get { return _countrySelected; }
            set
            {
                _countrySelected = value;
                OnPropertyChanged();
                //if (Equals(value, _countrySelected)) return;
                //if (_countrySelected != null)
                //    _countrySelected.CollectionChanged -= CountryItemsCollectionChanged;
                //_countrySelected = value;
                //if (value != null)
                //    _countrySelected.CollectionChanged += CountryItemsCollectionChanged;
            }
        }
        #endregion

        #region Properties        

        //Property1
        private Entities.Master.Trait _selectedProperty1;
        public Entities.Master.Trait SelectedProperty1
        {
            get { return _selectedProperty1; }
            set
            {
                _selectedProperty1 = value;
                OnPropertyChanged();
            }
        }

        private bool _property1EntryVisible;
        public bool Property1EntryVisible
        {
            get { return _property1EntryVisible; }
            set
            {
                _property1EntryVisible = value;
                OnPropertyChanged();
            }
        }

        private bool _property1MultipickerVisible;
        public bool Property1MultipickerVisible
        {
            get { return _property1MultipickerVisible; }
            set
            {
                _property1MultipickerVisible = value;
                OnPropertyChanged();
            }
        }

        private ObservableCollection<MyType> _propAttributelist1;
        public ObservableCollection<MyType> PropAttributeList1
        {
            get { return _propAttributelist1; }
            set
            {
                _propAttributelist1 = value;
                OnPropertyChanged();
            }
        }

        private ObservableCollection<MyType> _selectedPropertyAttribute1;
        public ObservableCollection<MyType> SelectedPropertyAttribute1
        {
            get { return _selectedPropertyAttribute1; }
            set
            {
                _selectedPropertyAttribute1 = value;
                OnPropertyChanged();
                //if (Equals(value, _selectedPropertyAttribute1)) return;
                //if (_selectedPropertyAttribute1 != null)
                //    _selectedPropertyAttribute1.CollectionChanged -= Property1ItemsCollectionChanged;
                //_selectedPropertyAttribute1 = value;
                //if (value != null)
                //    _selectedPropertyAttribute1.CollectionChanged += Property1ItemsCollectionChanged;
            }
        }

        private string _stringPropertyAttribute1;
        public string StringPropertyAttribute1
        {
            get { return _stringPropertyAttribute1; }
            set
            {
                _stringPropertyAttribute1 = value;
                OnPropertyChanged();
            }
        }

        private Xamarin.Forms.Keyboard _keyboardProperty1;

        public Xamarin.Forms.Keyboard KeyboardProperty1
        {
            get { return _keyboardProperty1; }
            set
            {
                _keyboardProperty1 = value;
                OnPropertyChanged();
            }
        }


        // Property2
        private Entities.Master.Trait _selectedProperty2;
        public Entities.Master.Trait SelectedProperty2
        {
            get { return _selectedProperty2; }
            set
            {
                _selectedProperty2 = value;
                OnPropertyChanged();
            }
        }

        private bool _property2EntryVisible;
        public bool Property2EntryVisible
        {
            get { return _property2EntryVisible; }
            set
            {
                _property2EntryVisible = value;
                OnPropertyChanged();
            }
        }

        private bool _property2MultipickerVisible;
        public bool Property2MultipickerVisible
        {
            get { return _property2MultipickerVisible; }
            set
            {
                _property2MultipickerVisible = value;
                OnPropertyChanged();
            }
        }

        private ObservableCollection<MyType> _propAttributelist2;
        public ObservableCollection<MyType> PropAttributeList2
        {
            get { return _propAttributelist2; }
            set
            {
                _propAttributelist2 = value;
                OnPropertyChanged();
            }
        }

        private ObservableCollection<MyType> _selectedPropertyAttribute2;
        public ObservableCollection<MyType> SelectedPropertyAttribute2
        {
            get { return _selectedPropertyAttribute2; }
            set
            {
                _selectedPropertyAttribute2 = value;
                OnPropertyChanged();
                //if (Equals(value, _selectedPropertyAttribute2)) return;
                //if (_selectedPropertyAttribute2 != null)
                //    _selectedPropertyAttribute2.CollectionChanged -= Property2ItemsCollectionChanged;
                //_selectedPropertyAttribute2 = value;
                //if (value != null)
                //    _selectedPropertyAttribute2.CollectionChanged += Property2ItemsCollectionChanged;
            }
        }

        private string _stringPropertyAttribute2;
        public string StringPropertyAttribute2
        {
            get { return _stringPropertyAttribute2; }
            set
            {
                _stringPropertyAttribute2 = value;
                OnPropertyChanged();
            }
        }

        private Xamarin.Forms.Keyboard _keyboardProperty2;

        public Xamarin.Forms.Keyboard KeyboardProperty2
        {
            get { return _keyboardProperty2; }
            set
            {
                _keyboardProperty2 = value;
                OnPropertyChanged();
            }
        }

        // Property3
        private Entities.Master.Trait _selectedProperty3;
        public Entities.Master.Trait SelectedProperty3
        {
            get { return _selectedProperty3; }
            set
            {
                _selectedProperty3 = value;
                OnPropertyChanged();
            }
        }

        private bool _property3EntryVisible;
        public bool Property3EntryVisible
        {
            get { return _property3EntryVisible; }
            set
            {
                _property3EntryVisible = value;
                OnPropertyChanged();
            }
        }

        private bool _property3MultipickerVisible;
        public bool Property3MultipickerVisible
        {
            get { return _property3MultipickerVisible; }
            set
            {
                _property3MultipickerVisible = value;
                OnPropertyChanged();
            }
        }

        private ObservableCollection<MyType> _propAttributelist3;
        public ObservableCollection<MyType> PropAttributeList3
        {
            get { return _propAttributelist3; }
            set
            {
                _propAttributelist3 = value;
                OnPropertyChanged();
            }
        }

        private ObservableCollection<MyType> _selectedPropertyAttribute3;
        public ObservableCollection<MyType> SelectedPropertyAttribute3
        {
            get { return _selectedPropertyAttribute3; }
            set
            {
                _selectedPropertyAttribute3 = value;
                OnPropertyChanged();
                //if (Equals(value, _selectedPropertyAttribute3)) return;
                //if (_selectedPropertyAttribute3 != null)
                //    _selectedPropertyAttribute3.CollectionChanged -= Property3ItemsCollectionChanged;
                //_selectedPropertyAttribute3 = value;
                //if (value != null)
                //    _selectedPropertyAttribute3.CollectionChanged += Property3ItemsCollectionChanged;
            }
        }

        private string _stringPropertyAttribute3;
        public string StringPropertyAttribute3
        {
            get { return _stringPropertyAttribute3; }
            set
            {
                _stringPropertyAttribute3 = value;
                OnPropertyChanged();
            }
        }

        private Xamarin.Forms.Keyboard _keyboardProperty3;

        public Xamarin.Forms.Keyboard KeyboardProperty3
        {
            get { return _keyboardProperty3; }
            set
            {
                _keyboardProperty3 = value;
                OnPropertyChanged();
            }
        }

        #endregion

        public void ReloadFilter(string styleId, string selectedValueTrialType, string selectedValueCrop, string selectedValueCropSegment, string selectedValueTrialRegion, string SelectedValueCountry)
        {
            switch (styleId)
            {
                case "TrialType":
                    IndividualFilterItems("Crop", selectedValueTrialType, selectedValueCrop, selectedValueCropSegment, selectedValueTrialRegion, SelectedValueCountry);
                    IndividualFilterItems("Country", selectedValueTrialType, selectedValueCrop, selectedValueCropSegment, selectedValueTrialRegion, SelectedValueCountry);
                    IndividualFilterItems("CropSegment", selectedValueTrialType, selectedValueCrop, selectedValueCropSegment, selectedValueTrialRegion, SelectedValueCountry);
                    IndividualFilterItems("TrialRegion", selectedValueTrialType, selectedValueCrop, selectedValueCropSegment, selectedValueTrialRegion, SelectedValueCountry);
                    //IndividualFilterItems("TrialType", selectedValueTrialType, selectedValueCrop, selectedValueCropSegment, selectedValueTrialRegion, SelectedValueCountry);
                    break;
                case "Crop":
                    //IndividualFilterItems("Crop", selectedValueTrialType, selectedValueCrop, selectedValueCropSegment, selectedValueTrialRegion, SelectedValueCountry);
                    IndividualFilterItems("Country", selectedValueTrialType, selectedValueCrop, selectedValueCropSegment, selectedValueTrialRegion, SelectedValueCountry);
                    IndividualFilterItems("CropSegment", selectedValueTrialType, selectedValueCrop, selectedValueCropSegment, selectedValueTrialRegion, SelectedValueCountry);
                    IndividualFilterItems("TrialRegion", selectedValueTrialType, selectedValueCrop, selectedValueCropSegment, selectedValueTrialRegion, SelectedValueCountry);
                    IndividualFilterItems("TrialType", selectedValueTrialType, selectedValueCrop, selectedValueCropSegment, selectedValueTrialRegion, SelectedValueCountry);
                    break;
                case "CropSegment":
                    IndividualFilterItems("Crop", selectedValueTrialType, selectedValueCrop, selectedValueCropSegment, selectedValueTrialRegion, SelectedValueCountry);
                    IndividualFilterItems("Country", selectedValueTrialType, selectedValueCrop, selectedValueCropSegment, selectedValueTrialRegion, SelectedValueCountry);
                    //IndividualFilterItems("CropSegment", selectedValueTrialType, selectedValueCrop, selectedValueCropSegment, selectedValueTrialRegion, SelectedValueCountry);
                    IndividualFilterItems("TrialRegion", selectedValueTrialType, selectedValueCrop, selectedValueCropSegment, selectedValueTrialRegion, SelectedValueCountry);
                    IndividualFilterItems("TrialType", selectedValueTrialType, selectedValueCrop, selectedValueCropSegment, selectedValueTrialRegion, SelectedValueCountry);
                    break;
                case "TrialRegion":
                    IndividualFilterItems("Crop", selectedValueTrialType, selectedValueCrop, selectedValueCropSegment, selectedValueTrialRegion, SelectedValueCountry);
                    IndividualFilterItems("Country", selectedValueTrialType, selectedValueCrop, selectedValueCropSegment, selectedValueTrialRegion, SelectedValueCountry);
                    IndividualFilterItems("CropSegment", selectedValueTrialType, selectedValueCrop, selectedValueCropSegment, selectedValueTrialRegion, SelectedValueCountry);
                    //IndividualFilterItems("TrialRegion", selectedValueTrialType, selectedValueCrop, selectedValueCropSegment, selectedValueTrialRegion, SelectedValueCountry);
                    IndividualFilterItems("TrialType", selectedValueTrialType, selectedValueCrop, selectedValueCropSegment, selectedValueTrialRegion, SelectedValueCountry);
                    break;
                case "Country":
                    IndividualFilterItems("Crop", selectedValueTrialType, selectedValueCrop, selectedValueCropSegment, selectedValueTrialRegion, SelectedValueCountry);
                    //IndividualFilterItems("Country", selectedValueTrialType, selectedValueCrop, selectedValueCropSegment, selectedValueTrialRegion, SelectedValueCountry);
                    IndividualFilterItems("CropSegment", selectedValueTrialType, selectedValueCrop, selectedValueCropSegment, selectedValueTrialRegion, SelectedValueCountry);
                    IndividualFilterItems("TrialRegion", selectedValueTrialType, selectedValueCrop, selectedValueCropSegment, selectedValueTrialRegion, SelectedValueCountry);
                    IndividualFilterItems("TrialType", selectedValueTrialType, selectedValueCrop, selectedValueCropSegment, selectedValueTrialRegion, SelectedValueCountry);
                    break;

            }
        }
        /// <summary>
        /// filter data for individual items based on selection provided
        /// </summary>
        /// <param name="filterFor">Item on which we want to get fitlered list </param>
        /// <param name="selectedValueTrialType">filtered trial type id in comma seperated format</param>
        /// <param name="selectedValueCrop">filtered crop id in comma seperated format</param>
        /// <param name="selectedValueCropSegment">filtered crop segment id in comma seperated format</param>
        /// <param name="selectedValueTrialRegion">filtered trial region id in comma seperated format</param>
        /// <param name="SelectedValueCountry">filtered country id in comma seperated format </param>
        /// <returns></returns>
        private void IndividualFilterItems(string filterFor, string selectedValueTrialType, string selectedValueCrop, string selectedValueCropSegment, string selectedValueTrialRegion, string SelectedValueCountry)
        {
            List<Entities.Transaction.TrialLookUp> filteredList = TrialList;
            var filteredData = Enumerable.Empty<string>();
            if (!string.IsNullOrWhiteSpace(selectedValueTrialType) && filterFor != "TrialType")
            {
                filteredData = selectedValueTrialType.Split('|').Select(x => x.Trim());
                filteredList = filteredList.Where(x => filteredData.Contains(x.TrialTypeID.ToText())).ToList();
            }
            if (!string.IsNullOrWhiteSpace(selectedValueCrop) && filterFor != "Crop")
            {
                filteredData = selectedValueCrop.Split('|').Select(x => x.Trim());
                filteredList = filteredList.Where(x => filteredData.Contains(x.CropCode)).ToList();
            }
            if (!string.IsNullOrWhiteSpace(selectedValueCropSegment) && filterFor != "CropSegment")
            {
                filteredData = selectedValueCropSegment.Split('|').Select(x => x.Trim());
                filteredList = filteredList.Where(x => filteredData.Contains(x.CropSegmentCode)).ToList();
            }
            if (!string.IsNullOrWhiteSpace(selectedValueTrialRegion) && filterFor != "TrialRegion")
            {
                filteredData = selectedValueTrialRegion.Split('|').Select(x => x.Trim());
                filteredList = filteredList.Where(x => filteredData.Contains(x.TrialRegionID.ToText())).ToList();
            }
            if (!string.IsNullOrWhiteSpace(SelectedValueCountry) && filterFor != "Country")
            {
                filteredData = SelectedValueCountry.Split('|').Select(x => x.Trim());
                filteredList = filteredList.Where(x => filteredData.Contains(x.CountryCode)).ToList();
            }

            if (filterFor == "TrialType")
            {
                if (TrialTypeListFromDb == null)
                    return;
                var data = filteredList.Select(x => x.TrialTypeID.ToText());
                TrialTypeList = new ObservableCollection<MyType>(TrialTypeListFromDb.Where(x => data.Contains(x.TrialTypeID.ToText())).Select(x => new MyType
                {
                    Id = x.TrialTypeID.ToText(),
                    Name = x.TrialTypeName
                }).ToList());
                if (!string.IsNullOrWhiteSpace(selectedValueTrialType))
                {
                    filteredData = selectedValueTrialType.Split('|').Select(x => x.Trim());
                    TrialTypeSelected = new ObservableCollection<MyType>(TrialTypeList.Where(x => filteredData.Contains(x.Id)));
                }
                if (TrialTypeSelected == null)
                {
                    TrialTypeSelected = new ObservableCollection<MyType>();
                }
            }
            if (filterFor == "Crop")
            {
                if (CropListFromDb == null)
                    return;
                var data = filteredList.Select(x => x.CropCode);
                CropList = new ObservableCollection<MyType>(CropListFromDb.Where(x => data.Contains(x.CropCode)).Select(x => new MyType
                {
                    Id = x.CropCode,
                    Name = x.CropName
                }).ToList());
                if (!string.IsNullOrWhiteSpace(selectedValueCrop))
                {
                    filteredData = selectedValueCrop.Split('|').Select(x => x.Trim());
                    CropSelected = new ObservableCollection<MyType>(CropList.Where(x => filteredData.Contains(x.Id)));
                }
                if (CropSelected == null)
                {
                    CropSelected = new ObservableCollection<MyType>();
                }

            }
            if (filterFor == "CropSegment")
            {
                if (CropSegmentListFromDb == null)
                    return;
                var data = filteredList.Select(x => x.CropSegmentCode);
                CropSegmentList = new ObservableCollection<MyType>(CropSegmentListFromDb.Where(x => data.Contains(x.CropSegmentCode)).Select(x => new MyType
                {
                    Id = x.CropSegmentCode,
                    Name = x.CropSegmentName
                }).ToList());
                if (!string.IsNullOrWhiteSpace(selectedValueCropSegment))
                {
                    filteredData = selectedValueCropSegment.Split('|').Select(x => x.Trim());
                    //CropSegmentSelected = null;
                    CropSegmentSelected = new ObservableCollection<MyType>(CropSegmentList.Where(x => filteredData.Contains(x.Id)));
                }
                if (CropSegmentSelected == null)
                {
                    CropSegmentSelected = new ObservableCollection<MyType>();
                }
            }
            if (filterFor == "TrialRegion")
            {
                if (TrialRegionListFromDb == null)
                    return;
                var data = filteredList.Select(x => x.TrialRegionID.ToText());
                TrialRegionList = new ObservableCollection<MyType>(TrialRegionListFromDb.Where(x => data.Contains(x.TrialRegionID.ToText())).Select(x => new MyType
                {
                    Id = x.TrialRegionID.ToText(),
                    Name = x.TrialRegionName
                }).ToList());
                if (!string.IsNullOrWhiteSpace(selectedValueTrialRegion))
                {
                    filteredData = selectedValueTrialRegion.Split('|').Select(x => x.Trim());
                    TrialRegionSelected = new ObservableCollection<MyType>(TrialRegionList.Where(x => filteredData.Contains(x.Id)));
                }
                if (TrialRegionSelected == null)
                {
                    TrialRegionSelected = new ObservableCollection<MyType>();
                }
            }
            if (filterFor == "Country")
            {
                if (CountryListFromDb == null)
                    return;
                var data = filteredList.Select(x => x.CountryCode);
                CountryList = new ObservableCollection<MyType>(CountryListFromDb.Where(x => data.Contains(x.CountryCode)).Select(x => new MyType
                {
                    Id = x.CountryCode,
                    Name = x.CountryName
                }).ToList());
                if (!string.IsNullOrWhiteSpace(SelectedValueCountry))
                {
                    filteredData = SelectedValueCountry.Split('|').Select(x => x.Trim());
                    CountrySelected = new ObservableCollection<MyType>(CountryList.Where(x => filteredData.Contains(x.Id)));
                }
                if (CountrySelected == null)
                {
                    CountrySelected = new ObservableCollection<MyType>();
                }
            }
        }

        public async Task LoadAllFilterData()
        {
            var savedFilter = await SaveFilterService.GetSaveFilterAsync();
            var downloadedList = string.Join(",", TrialList.Select(x => x.TrialTypeID).Distinct());
            TrialTypeListFromDb = new ObservableCollection<TrialType>(await _trialTypeService.GetTrialTypeListAsync(downloadedList));

            downloadedList = string.Join(",", TrialList.Select(x => "'" + x.CropCode + "'").Distinct());
            CropListFromDb = new ObservableCollection<CropRD>(await _cropRdService.GetCropListAsync(downloadedList));

            downloadedList = string.Join(",", TrialList.Select(x => "'" + x.CropSegmentCode + "'").Distinct());
            CropSegmentListFromDb = new ObservableCollection<CropSegment>(await _cropSegmentService.GetCropSegmentListAsync(downloadedList));

            downloadedList = string.Join(",", TrialList.Select(x => "'" + x.TrialRegionID + "'").Distinct()); ;
            TrialRegionListFromDb = new ObservableCollection<TrialRegion>(await _trialRegionService.GetTrialRegionListAsync(downloadedList));

            downloadedList = string.Join(",", TrialList.Select(x => "'" + x.CountryCode + "'").Distinct());
            CountryListFromDb = new ObservableCollection<Country>(await _countryService.GetCountryListAsync(downloadedList));
            if (savedFilter == null)
            {
                CropList = new ObservableCollection<MyType>(CropListFromDb.Select(x => new MyType
                {
                    Id = x.CropCode,
                    Name = x.CropName
                }).ToList());

                CountryList = new ObservableCollection<MyType>(CountryListFromDb.Select(x => new MyType
                {
                    Id = x.CountryCode,
                    Name = x.CountryName
                }).ToList());

                TrialTypeList = new ObservableCollection<MyType>(TrialTypeListFromDb.Select(x => new MyType
                {
                    Id = x.TrialTypeID.ToString(),
                    Name = x.TrialTypeName
                }).ToList());

                CropSegmentList = new ObservableCollection<MyType>(CropSegmentListFromDb.Select(x => new MyType
                {
                    Id = x.CropSegmentCode,
                    Name = x.CropSegmentName
                }).ToList());

                TrialRegionList = new ObservableCollection<MyType>(TrialRegionListFromDb.Select(x => new MyType
                {
                    Id = x.TrialRegionID.ToText(),
                    Name = x.TrialRegionName
                }).ToList());

                CountrySelected = new ObservableCollection<MyType>();
                CropSegmentSelected = new ObservableCollection<MyType>();
                TrialRegionSelected = new ObservableCollection<MyType>();
                TrialTypeSelected = new ObservableCollection<MyType>();
                CropSelected = new ObservableCollection<MyType>();
                return;
            }
            var filterFound = false;
            string trialtypefilter = string.Empty;
            string cropfilter = string.Empty;
            string countryfilter = string.Empty;
            string cropsegmentfilter = string.Empty;
            string trialregionfilter = string.Empty;
            string filter = string.Empty;
            var filteredData = Enumerable.Empty<string>();
            var propertyfilterlist = new List<SaveFilter>();
            foreach (var _data in savedFilter)
            {
                if (!string.IsNullOrWhiteSpace(_data.FieldValue))
                    filteredData = _data.FieldValue.Split('|').Select(x => x.Trim());
                switch (_data.Field.ToLower())
                {
                    case "trialtypeid":
                        if (!filterFound && !string.IsNullOrWhiteSpace(_data.FieldValue))
                        {
                            filter = "TrialType";
                            filterFound = true;
                            TrialTypeList = new ObservableCollection<MyType>(TrialTypeListFromDb.Select(x => new MyType
                            {
                                Id = x.TrialTypeID.ToString(),
                                Name = x.TrialTypeName
                            }).ToList());
                            TrialTypeSelected = new ObservableCollection<MyType>(TrialTypeList.Where(x => filteredData.Contains(x.Id)));
                            if (TrialTypeSelected.Count <= 0)
                                filterFound = false;

                        }
                        trialtypefilter = _data.FieldValue;
                        break;
                    case "cropcode":
                        if (!filterFound && !string.IsNullOrWhiteSpace(_data.FieldValue))
                        {
                            filter = "Crop";
                            filterFound = true;
                            CropList = new ObservableCollection<MyType>(CropListFromDb.Select(x => new MyType
                            {
                                Id = x.CropCode,
                                Name = x.CropName
                            }).ToList());
                            CropSelected = new ObservableCollection<MyType>(CropList.Where(x => filteredData.Contains(x.Id)));
                            if (CropSelected.Count <= 0)
                                filterFound = false;
                        }
                        cropfilter = _data.FieldValue;
                        break;
                    case "cropsegmentcode":
                        if (!filterFound && !string.IsNullOrWhiteSpace(_data.FieldValue))
                        {
                            filter = "CropSegment";
                            filterFound = true;
                            CropSegmentList = new ObservableCollection<MyType>(CropSegmentListFromDb.Select(x => new MyType
                            {
                                Id = x.CropSegmentCode,
                                Name = x.CropSegmentName
                            }).ToList());
                            CropSegmentSelected = new ObservableCollection<MyType>(CropSegmentList.Where(x => filteredData.Contains(x.Id)));
                            if (CropSegmentSelected.Count <= 0)
                                filterFound = false;
                        }
                        cropsegmentfilter = _data.FieldValue;
                        break;
                    case "trialregionid":
                        if (!filterFound && !string.IsNullOrWhiteSpace(_data.FieldValue))
                        {
                            filter = "TrialRegion";
                            filterFound = true;
                            TrialRegionList = new ObservableCollection<MyType>(TrialRegionListFromDb.Select(x => new MyType
                            {
                                Id = x.TrialRegionID.ToText(),
                                Name = x.TrialRegionName
                            }).ToList());
                            TrialRegionSelected = new ObservableCollection<MyType>(TrialRegionList.Where(x => filteredData.Contains(x.Id)));
                            if (TrialRegionSelected.Count <= 0)
                                filterFound = false;
                        }
                        trialregionfilter = _data.FieldValue;
                        break;
                    case "countrycode":
                        if (!filterFound && !string.IsNullOrWhiteSpace(_data.FieldValue))
                        {
                            filter = "Country";
                            filterFound = true;
                            CountryList = new ObservableCollection<MyType>(CountryListFromDb.Select(x => new MyType
                            {
                                Id = x.CountryCode,
                                Name = x.CountryName
                            }).ToList());
                            CountrySelected = new ObservableCollection<MyType>(CountryList.Where(x => filteredData.Contains(x.Id)));
                            if (CountrySelected.Count <= 0)
                                filterFound = false;
                        }
                        countryfilter = _data.FieldValue;
                        break;
                    default:
                        if (!string.IsNullOrWhiteSpace(_data.FieldValue))
                        {
                            propertyfilterlist.Add(_data);
                        }
                        break;
                }
            }

            //Display saved filter for properties
            if (propertyfilterlist.Any())
            {
                var count = 1;
                foreach (var val in propertyfilterlist)
                {
                    var enumValue = val.FieldValue.Split('|').Select(x => x.Trim());
                    switch (count)
                    {
                        case 1:
                            {
                                SelectedProperty1 = Propertylist.FirstOrDefault(x => x.TraitID.ToString() == val.Field);

                                if (SelectedProperty1 != null)
                                {
                                    //Select attributes
                                    var traitInfo = (await _traitService.GetTraitsAsync(val.Field)).FirstOrDefault();
                                    if (traitInfo.ListOfValues)
                                    {
                                        var traitid = 0;
                                        int.TryParse(val.Field, out traitid);
                                        var traitValueList = _traitValueService.GetTraitValue(traitid);
                                        PropAttributeList1 = new ObservableCollection<MyType>(traitValueList.Select(x =>
                                            new MyType
                                            {
                                                Id = x.TraitValueID.ToString(),
                                                Name = x.TraitValueCode
                                            }).ToList());

                                        SelectedPropertyAttribute1 =
                                            new ObservableCollection<MyType>(
                                                PropAttributeList1.Where(x => enumValue.Contains(x.Name)));
                                        if (SelectedPropertyAttribute1.Count <= 0)
                                            filterFound = false;
                                    }
                                    else if (traitInfo.DataType.ToLower() == "d")
                                    {
                                        var traitid = 0;
                                        int.TryParse(val.Field, out traitid);
                                        var traitValueList = await _observationAppService.LoadObservationUsingQuery(" TraitID = " + traitid);
                                        var finalObsAppList = new List<ObservationAppLookup>();
                                        foreach (var item in traitValueList)
                                        {
                                            if (finalObsAppList.Where(x => x.ObsValueDate.Contains(item.ObsValueDate.ToString().Split('T')[0])).Any()) continue;
                                            finalObsAppList.Add(item);
                                        }
                                        finalObsAppList = finalObsAppList.OrderByDescending(x => DateTime.Parse(x.ObsValueDate)).ToList();
                                        PropAttributeList1 = new ObservableCollection<MyType>(finalObsAppList.Select(x =>
                                            new MyType
                                            {
                                                Id = x.TraitID.ToString(),
                                                Name = x.ObsValueDate.Split('T')[0]
                                            }).ToList());

                                        SelectedPropertyAttribute1 =
                                            new ObservableCollection<MyType>(
                                                PropAttributeList1.Where(x => enumValue.Contains(x.Name.Split('T')[0])));
                                        if (SelectedPropertyAttribute1.Count <= 0)
                                            filterFound = false;
                                    }
                                    else
                                        StringPropertyAttribute1 = val.FieldValue;
                                }
                            }
                            break;
                        case 2:
                            {
                                SelectedProperty2 = Propertylist.FirstOrDefault(x => x.TraitID.ToString() == val.Field);

                                if (SelectedProperty2 != null)
                                {
                                    //Select attributes
                                    var traitInfo = (await _traitService.GetTraitsAsync(val.Field)).FirstOrDefault();
                                    if (traitInfo.ListOfValues)
                                    {
                                        var traitid = 0;
                                        int.TryParse(val.Field, out traitid);
                                        var traitValueList = _traitValueService.GetTraitValue(traitid);
                                        PropAttributeList2 = new ObservableCollection<MyType>(traitValueList.Select(x =>
                                            new MyType
                                            {
                                                Id = x.TraitValueID.ToString(),
                                                Name = x.TraitValueCode
                                            }).ToList());

                                        SelectedPropertyAttribute2 =
                                            new ObservableCollection<MyType>(
                                                PropAttributeList2.Where(x => enumValue.Contains(x.Name)));
                                        if (SelectedPropertyAttribute2.Count <= 0)
                                            filterFound = false;
                                    }
                                    else if (traitInfo.DataType.ToLower() == "d")
                                    {
                                        var traitid = 0;
                                        int.TryParse(val.Field, out traitid);
                                        var traitValueList = await _observationAppService.LoadObservationUsingQuery(" TraitID = " + traitid);
                                        var finalObsAppList = new List<ObservationAppLookup>();
                                        foreach (var item in traitValueList)
                                        {
                                            if (finalObsAppList.Where(x => x.ObsValueDate.Contains(item.ObsValueDate.ToString().Split('T')[0])).Any()) continue;
                                            finalObsAppList.Add(item);
                                        }
                                        finalObsAppList = finalObsAppList.OrderByDescending(x => DateTime.Parse(x.ObsValueDate)).ToList();
                                        PropAttributeList2 = new ObservableCollection<MyType>(finalObsAppList.Select(x =>
                                            new MyType
                                            {
                                                Id = x.TraitID.ToString(),
                                                Name = x.ObsValueDate.Split('T')[0]
                                            }).ToList());

                                        SelectedPropertyAttribute2 =
                                            new ObservableCollection<MyType>(
                                                PropAttributeList2.Where(x => enumValue.Contains(x.Name.Split('T')[0])));
                                        if (SelectedPropertyAttribute2.Count <= 0)
                                            filterFound = false;
                                    }
                                    else
                                        StringPropertyAttribute2 = val.FieldValue;
                                }
                            }
                            break;
                        case 3:
                            {
                                SelectedProperty3 = Propertylist.FirstOrDefault(x => x.TraitID.ToString() == val.Field);

                                if (SelectedProperty3 != null)
                                {
                                    //Select attributes
                                    var traitInfo = (await _traitService.GetTraitsAsync(val.Field)).FirstOrDefault();
                                    if (traitInfo.ListOfValues)
                                    {
                                        var traitid = 0;
                                        int.TryParse(val.Field, out traitid);
                                        var traitValueList = _traitValueService.GetTraitValue(traitid);
                                        PropAttributeList3 = new ObservableCollection<MyType>(traitValueList.Select(x =>
                                            new MyType
                                            {
                                                Id = x.TraitValueID.ToString(),
                                                Name = x.TraitValueCode
                                            }).ToList());

                                        SelectedPropertyAttribute3 =
                                            new ObservableCollection<MyType>(
                                                PropAttributeList3.Where(x => enumValue.Contains(x.Name)));
                                        if (SelectedPropertyAttribute3.Count <= 0)
                                            filterFound = false;
                                    }
                                    else if (traitInfo.DataType.ToLower() == "d")
                                    {
                                        var traitid = 0;
                                        int.TryParse(val.Field, out traitid);
                                        var traitValueList = await _observationAppService.LoadObservationUsingQuery(" TraitID = " + traitid);
                                        var finalObsAppList = new List<ObservationAppLookup>();
                                        foreach (var item in traitValueList)
                                        {
                                            if (finalObsAppList.Where(x => x.ObsValueDate.Contains(item.ObsValueDate.ToString().Split('T')[0])).Any()) continue;
                                            finalObsAppList.Add(item);
                                        }
                                        finalObsAppList = finalObsAppList.OrderByDescending(x => DateTime.Parse(x.ObsValueDate)).ToList();
                                        PropAttributeList3 = new ObservableCollection<MyType>(finalObsAppList.Select(x =>
                                            new MyType
                                            {
                                                Id = x.TraitID.ToString(),
                                                Name = x.ObsValueDate.Split('T')[0]
                                            }).ToList());

                                        SelectedPropertyAttribute3 =
                                            new ObservableCollection<MyType>(
                                                PropAttributeList3.Where(x => enumValue.Contains(x.Name.Split('T')[0])));
                                        if (SelectedPropertyAttribute3.Count <= 0)
                                            filterFound = false;
                                    }
                                    else
                                        StringPropertyAttribute3 = val.FieldValue;
                                }
                            }
                            break;

                        default:
                            break;
                    }
                    count++;
                }
            }

            if (filterFound)
            {
                ReloadFilter(filter, trialtypefilter, cropfilter, cropsegmentfilter, trialregionfilter, countryfilter);
                return;
            }
            CropList = new ObservableCollection<MyType>(CropListFromDb.Select(x => new MyType
            {
                Id = x.CropCode,
                Name = x.CropName
            }).ToList());

            CountryList = new ObservableCollection<MyType>(CountryListFromDb.Select(x => new MyType
            {
                Id = x.CountryCode,
                Name = x.CountryName
            }).ToList());

            TrialTypeList = new ObservableCollection<MyType>(TrialTypeListFromDb.Select(x => new MyType
            {
                Id = x.TrialTypeID.ToString(),
                Name = x.TrialTypeName
            }).ToList());

            CropSegmentList = new ObservableCollection<MyType>(CropSegmentListFromDb.Select(x => new MyType
            {
                Id = x.CropSegmentCode,
                Name = x.CropSegmentName
            }).ToList());

            TrialRegionList = new ObservableCollection<MyType>(TrialRegionListFromDb.Select(x => new MyType
            {
                Id = x.TrialRegionID.ToText(),
                Name = x.TrialRegionName
            }).ToList());

            CountrySelected = new ObservableCollection<MyType>();
            CropSegmentSelected = new ObservableCollection<MyType>();
            TrialRegionSelected = new ObservableCollection<MyType>();
            TrialTypeSelected = new ObservableCollection<MyType>();
            CropSelected = new ObservableCollection<MyType>();

        }

        private void CountryItemsCollectionChanged(object sender, NotifyCollectionChangedEventArgs e)
        {
            OnPropertyChanged(nameof(CountrySelected));
        }
        private void CropItemsCollectionChanged(object sender, NotifyCollectionChangedEventArgs e)
        {
            OnPropertyChanged(nameof(CropSelected));
            //OnPropertyChanged();
        }
        private void TrialRegionItemsCollectionChanged(object sender, NotifyCollectionChangedEventArgs e)
        {
            OnPropertyChanged(nameof(TrialRegionSelected));
            //OnPropertyChanged();
        }
        private void CropSegmentItemsCollectionChanged(object sender, NotifyCollectionChangedEventArgs e)
        {
            OnPropertyChanged(nameof(CropSegmentSelected));
            //OnPropertyChanged();
        }
        private void TrialTypeItemsCollectionChanged(object sender, NotifyCollectionChangedEventArgs e)
        {
            OnPropertyChanged(nameof(TrialTypeSelected));
        }
        private void Property1ItemsCollectionChanged(object sender, NotifyCollectionChangedEventArgs e)
        {
            OnPropertyChanged(nameof(SelectedPropertyAttribute1));
        }
        private void Property2ItemsCollectionChanged(object sender, NotifyCollectionChangedEventArgs e)
        {
            OnPropertyChanged(nameof(SelectedPropertyAttribute2));
        }
        private void Property3ItemsCollectionChanged(object sender, NotifyCollectionChangedEventArgs e)
        {
            OnPropertyChanged(nameof(SelectedPropertyAttribute3));
        }

        public void ToggleFilterSetting(string isToggled)
        {
            _settingParametersService.UpdateParams("filter", isToggled);
        }

        public async void LoadPropertyAttributes(Entities.Master.Trait trait, int propertyfield)
        {
            if (trait.ListOfValues)
            {
                var traitValueList = _traitValueService.GetTraitValue(trait.TraitID);

                var newPropAttributeList = new ObservableCollection<MyType>(traitValueList.Select(x => new MyType
                {
                    Id = x.TraitValueID.ToString(),
                    Name = x.TraitValueCode
                }).ToList());

                switch (propertyfield)
                {
                    case 1:
                        {
                            Property1MultipickerVisible = true;
                            Property1EntryVisible = false;

                            if (PropAttributeList1 != null && PropAttributeList1.Count == newPropAttributeList.Count && PropAttributeList1.FirstOrDefault()?.Id == newPropAttributeList.FirstOrDefault()?.Id)
                                return;

                            PropAttributeList1 = newPropAttributeList;
                            SelectedPropertyAttribute1 = new ObservableCollection<MyType>();
                            StringPropertyAttribute1 = "";
                        }
                        break;
                    case 2:
                        {
                            Property2MultipickerVisible = true;
                            Property2EntryVisible = false;

                            if (PropAttributeList2 != null && PropAttributeList2.Count == newPropAttributeList.Count && PropAttributeList2.FirstOrDefault()?.Id == newPropAttributeList.FirstOrDefault()?.Id)
                                return;

                            PropAttributeList2 = newPropAttributeList;
                            SelectedPropertyAttribute2 = new ObservableCollection<MyType>();
                            StringPropertyAttribute2 = "";
                        }
                        break;
                    case 3:
                        {
                            Property3MultipickerVisible = true;
                            Property3EntryVisible = false;

                            if (PropAttributeList3 != null && PropAttributeList3.Count == newPropAttributeList.Count && PropAttributeList3.FirstOrDefault()?.Id == newPropAttributeList.FirstOrDefault()?.Id)
                                return;

                            PropAttributeList3 = newPropAttributeList;
                            SelectedPropertyAttribute3 = new ObservableCollection<MyType>();
                            StringPropertyAttribute3 = "";
                        }
                        break;
                }
            }
            else if (trait.DataType.ToLower() == "d")
            {
                var finalObsAppList = new List<ObservationAppLookup>();
                var obsAppList = await _observationAppService.GetObservationDataAll(string.Empty, trait.TraitID.ToString());
                obsAppList = obsAppList.OrderByDescending(x => DateTime.Parse(x.ObsValueDate)).ToList();
                foreach (var item in obsAppList)
                {
                    if (finalObsAppList.Where(x => x.ObsValueDate.Contains(item.ObsValueDate.ToString().Split('T')[0])).Any()) continue;
                    finalObsAppList.Add(item);
                }
                var newPropAttributeList = new ObservableCollection<MyType>(finalObsAppList
                    .Select(x => new MyType
                    {
                        Id = x.TraitID.ToString(),
                        Name = x.ObsValueDate.ToString().Split('T')[0]
                    })
                .ToList());
                switch (propertyfield)
                {
                    case 1:
                        {
                            Property1MultipickerVisible = true;
                            Property1EntryVisible = false;

                            if (PropAttributeList1 != null && PropAttributeList1.Count == newPropAttributeList.Count && PropAttributeList1.FirstOrDefault()?.Id == newPropAttributeList.FirstOrDefault()?.Id)
                                return;

                            PropAttributeList1 = newPropAttributeList;
                            SelectedPropertyAttribute1 = new ObservableCollection<MyType>();
                            StringPropertyAttribute1 = "";
                        }
                        break;
                    case 2:
                        {
                            Property2MultipickerVisible = true;
                            Property2EntryVisible = false;

                            if (PropAttributeList2 != null && PropAttributeList2.Count == newPropAttributeList.Count && PropAttributeList2.FirstOrDefault()?.Id == newPropAttributeList.FirstOrDefault()?.Id)
                                return;

                            PropAttributeList2 = newPropAttributeList;
                            SelectedPropertyAttribute2 = new ObservableCollection<MyType>();
                            StringPropertyAttribute2 = "";
                        }
                        break;
                    case 3:
                        {
                            Property3MultipickerVisible = true;
                            Property3EntryVisible = false;

                            if (PropAttributeList3 != null && PropAttributeList3.Count == newPropAttributeList.Count && PropAttributeList3.FirstOrDefault()?.Id == newPropAttributeList.FirstOrDefault()?.Id)
                                return;

                            PropAttributeList3 = newPropAttributeList;
                            SelectedPropertyAttribute3 = new ObservableCollection<MyType>();
                            StringPropertyAttribute3 = "";
                        }
                        break;
                }
            }
            else
            {
                var keyboard = Xamarin.Forms.Keyboard.Default;
                if (trait.DataType.ToLower() == "a" || trait.DataType.ToLower() == "i")
                    keyboard = Xamarin.Forms.Keyboard.Numeric;

                switch (propertyfield)
                {
                    case 1:
                        {
                            Property1MultipickerVisible = false;
                            Property1EntryVisible = true;
                            SelectedPropertyAttribute1 = null;
                            KeyboardProperty1 = keyboard;
                        }
                        break;
                    case 2:
                        {
                            Property2MultipickerVisible = false;
                            Property2EntryVisible = true;
                            SelectedPropertyAttribute2 = null;
                            KeyboardProperty2 = keyboard;
                        }
                        break;
                    case 3:
                        {
                            Property3MultipickerVisible = false;
                            Property3EntryVisible = true;
                            SelectedPropertyAttribute3 = null;
                            KeyboardProperty3 = keyboard;
                        }
                        break;
                }
            }
        }
    }
    internal class ApplyfilterOperation : ICommand
    {
        public event EventHandler CanExecuteChanged;

        public bool CanExecute(object parameter)
        {
            return true;
        }

        public async void Execute(object parameter)
        {
            var vm = parameter as FilterPageViewModel;
            if (vm == null) return;

            var savefilterList = new List<SaveFilter>
            {
                new SaveFilter() {Field = "TrialTypeId", FieldValue = string.Join("|", vm.TrialTypeSelected.Select(m => m.Id))},
                new SaveFilter() {Field = "CropCode", FieldValue = string.Join("|", vm.CropSelected.Select(m => m.Id))},
                new SaveFilter() {Field = "CropSegmentCode", FieldValue = string.Join("|", vm.CropSegmentSelected.Select(m => m.Id))},
                new SaveFilter() {Field = "TrialRegionId", FieldValue = string.Join("|", vm.TrialRegionSelected.Select(m => m.Id))},
                new SaveFilter() {Field = "CountryCode", FieldValue = string.Join("|", vm.CountrySelected.Select(m => m.Id)) }
            };

            //Property1
            if (vm.SelectedPropertyAttribute1 != null)
            {
                var value = string.Join("|", vm.SelectedPropertyAttribute1.Select(m => m.Name));
                var filterprop = new SaveFilter()
                {
                    Field = vm.SelectedProperty1.TraitID.ToString(),
                    FieldValue = string.IsNullOrEmpty(value) ? "0" : value
                };
                savefilterList.Add(filterprop);
            }
            else if (!string.IsNullOrEmpty(vm.StringPropertyAttribute1))
            {
                var filterprop = new SaveFilter()
                {
                    Field = vm.SelectedProperty1.TraitID.ToString(),
                    FieldValue = string.IsNullOrEmpty(vm.StringPropertyAttribute1) ? "0" : vm.StringPropertyAttribute1
                };
                savefilterList.Add(filterprop);
            }

            //Property2
            if (vm.SelectedPropertyAttribute2 != null)
            {
                var value = string.Join("|", vm.SelectedPropertyAttribute2.Select(m => m.Name));
                var filterprop = new SaveFilter()
                {
                    Field = vm.SelectedProperty2.TraitID.ToString(),
                    FieldValue = string.IsNullOrEmpty(value) ? "0" : value
                };
                savefilterList.Add(filterprop);
            }
            else if (!string.IsNullOrEmpty(vm.StringPropertyAttribute2))
            {
                var filterprop = new SaveFilter()
                {
                    Field = vm.SelectedProperty2.TraitID.ToString(),
                    FieldValue = string.IsNullOrEmpty(vm.StringPropertyAttribute2) ? "0" : vm.StringPropertyAttribute2
                };
                savefilterList.Add(filterprop);
            }

            //Property3
            if (vm.SelectedPropertyAttribute3 != null)
            {
                var value = string.Join("|", vm.SelectedPropertyAttribute3.Select(m => m.Name));
                var filterprop = new SaveFilter()
                {
                    Field = vm.SelectedProperty3.TraitID.ToString(),
                    FieldValue = string.IsNullOrEmpty(value) ? "0" : value
                };
                savefilterList.Add(filterprop);
            }
            else if (!string.IsNullOrEmpty(vm.StringPropertyAttribute3))
            {
                var filterprop = new SaveFilter()
                {
                    Field = vm.SelectedProperty3.TraitID.ToString(),
                    FieldValue = string.IsNullOrEmpty(vm.StringPropertyAttribute3) ? "0" : vm.StringPropertyAttribute3
                };
                savefilterList.Add(filterprop);
            }

            await vm.SaveFilterService.SaveFilterAsync(savefilterList);
            await App.MainNavigation.PopAsync();
        }

    }
}
