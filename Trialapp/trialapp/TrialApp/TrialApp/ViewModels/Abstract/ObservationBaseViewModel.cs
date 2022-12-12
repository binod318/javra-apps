using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using TrialApp.Common;
using TrialApp.Common.Extensions;
using TrialApp.Entities.Transaction;
using TrialApp.Services;
using Xamarin.Forms;
using TrialApp.Entities.Master;
using System.Globalization;
using System.Collections.ObjectModel;

namespace TrialApp.ViewModels.Abstract
{
    public class ObservationBaseViewModel : PictureBaseViewModel
    {
        #region private variables

        private int _pickerSelectedIndex;
        private List<Trait> traitList;
        private List<ReOrderTrait> reOrderTraitList;
        private bool _resistanceStackVisible;
        private Trait _resistanceHr;
        private Trait _resistanceIr;
        private Trait _resistanceT;
        private Color _headerTextColor;
        private Color _headerColor;
        private bool _isValidated { get; set; }
        private Trait trait { get; set; }
       
        private bool _fieldsetPickerEnabled;
        private DateTime _observationDate = DateTime.Now;
        private ObservableCollection<ObservationAppHistory> _historyObservations { get; set; }
        private string _traitName;
        private bool _reorderVisible;
        private List<Entities.Master.Trait> defaultTraitlistPerTrial;
        private double _traitInfoPopupHeight;
        private bool _traitEditorPopupVisible;
        private string _traitEditorValue;
        private string _traitEditorColumnLabel;

        #endregion

        #region public properties

        public double TraitInfoPopupHeight
        {
            get { return _traitInfoPopupHeight; }
            set { _traitInfoPopupHeight = value; OnPropertyChanged(); }
        }

        public List<Entities.Master.Trait> DefaultTraitlistPerTrial
        {
            get { return defaultTraitlistPerTrial; }
            set
            {
                defaultTraitlistPerTrial = value;
                OnPropertyChanged();
            }
        }

        public bool FieldsetPickerEnabled
        {
            get { return _fieldsetPickerEnabled; }
            set
            {
                _fieldsetPickerEnabled = value;
                OnPropertyChanged();
            }
        }

        public DateTime ObservationDate
        {
            get { return _observationDate; }
            set
            {
                _observationDate = value;
                OnPropertyChanged();
            }
        }
        public List<Trait> TraitList
        {
            get { return traitList; }
            set
            {
                traitList = value;
                OnPropertyChanged();
            }
        }

        public List<Trait> FieldsetTraits { get; set; }

        public List<ReOrderTrait> ReOrderTraitList
        {
            get { return reOrderTraitList; }
            set
            {
                reOrderTraitList = value;
                OnPropertyChanged();
            }
        }

        public bool ResistanceStackVisible
        {
            get { return _resistanceStackVisible; }
            set
            {
                _resistanceStackVisible = value;
                OnPropertyChanged();
            }
        }

        public Trait ResistanceHr
        {
            get { return _resistanceHr; }
            set { _resistanceHr = value; OnPropertyChanged(); }
        }

        public Trait ResistanceIr
        {
            get { return _resistanceIr; }
            set { _resistanceIr = value; OnPropertyChanged(); }
        }

        public Trait ResistanceT
        {
            get { return _resistanceT; }
            set { _resistanceT = value; OnPropertyChanged(); }
        }

        public ObservationAppService ObservationService;

        public int PickerSelectedIndex
        {
            get { return _pickerSelectedIndex; }
            set
            {
                _pickerSelectedIndex = value;
                OnPropertyChanged();
            }
        }
        public List<ObservationAppLookup> ObsValueList { get; set; }
        public List<ObservationAppCalculatedSum> ObsValueListForCalculatedSum { get; set; }

        public int? SelectedFieldset { get; set; }

        public TraitFieldValidation Validation { get; set; }

        public string EzId { get; set; }
        public int TrialEzId { get; set; }

        public TrialService TrialService { get; set; }

        public Color HeaderTextColor
        {
            get { return _headerTextColor; }
            set
            {
                _headerTextColor = value;
                OnPropertyChanged();
            }
        }

        public Color HeaderColor
        {
            get { return _headerColor; }
            set
            {
                _headerColor = value;
                OnPropertyChanged();
            }
        }

        public ObservableCollection<ObservationAppHistory> HistoryObservations
        {
            get { return _historyObservations; }
            set
            {
                _historyObservations = value;
                OnPropertyChanged();
            }
        }

        public string TraitName
        {
            get { return _traitName; }
            set { _traitName = value; OnPropertyChanged(); }
        }

        public bool ReorderVisible
        {
            get { return _reorderVisible; }
            set { _reorderVisible = value; OnPropertyChanged(); }
        }

        public bool TraitEditorPopupVisible
        {
            get { return _traitEditorPopupVisible; }
            set { _traitEditorPopupVisible = value; OnPropertyChanged(); }
        }
        public string TraitEditorValue
        {
            get { return _traitEditorValue; }
            set { _traitEditorValue = value; OnPropertyChanged(); }
        }
        public string TraitEditorColumnLabel
        {
            get { return _traitEditorColumnLabel; }
            set { _traitEditorColumnLabel = value; OnPropertyChanged(); }
        }

        public int TraitEditorID { get; set; }
        public string DataType { get; set; }
        public string Format { get; set; }

        #endregion

        /// <summary>
        /// returns corresponant value according to data type
        /// </summary>
        /// <param name="observationData"></param>
        /// <param name="dataType"></param>
        /// <returns></returns>
        public string GetObservationValue(ObservationAppLookup observationData, string dataType, string columnLabel)
        {
            if (observationData != null)
            {
                //Value for cumulated column
                if (columnLabel == "Sum")
                {
                    var data = ObsValueListForCalculatedSum.FirstOrDefault(o => o.TraitID == observationData.TraitID);
                    return data.CalculatedSum.ToText();
                }

                DateTime.TryParse(observationData.DateUpdated, out DateTime updatedDate);

                // If Observation is not from today then display empty value
                //if (updatedDate.Date != ObservationDate && columnLabel!= "FromPrevObs")
                if (!observationData.Modified && columnLabel != "FromPrevObs")
                    return "";

                return GetDisplayObservation(observationData, dataType);
            }
            return "";

        }



        /// <summary>
        /// returns corresponant value according to data type
        /// </summary>
        /// <param name="observationData"></param>
        /// <param name="dataType"></param>
        /// <returns></returns>
        public string GetObservationValueProp(ObservationAppLookup observationData, string dataType, string columnLabel)
        {
            if (observationData != null)
            {
                //Value for cumulated column
                if (columnLabel == "Sum")
                {
                    var data = ObsValueListForCalculatedSum.FirstOrDefault(o => o.TraitID == observationData.TraitID);
                    return data.CalculatedSum.ToText();
                }

                DateTime.TryParse(observationData.DateUpdated, out DateTime updatedDate);


                return GetDisplayObservation(observationData, dataType);
            }
            return "";

        }

        public string GetDisplayObservation(ObservationAppLookup observationData, string dataType)
        {
            switch (dataType)
            {
                case "c":
                    return observationData.ObsValueChar.ToText();
                case "i":
                    return observationData.ObsValueInt.ToText();
                case "d":
                    return observationData.ObsValueDate.ToText().Split('T')[0];
                case "a":
                    if (CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator == ",")
                        observationData.ObsValueDec.ToText().Replace('.', ',');
                    return observationData.ObsValueDec.ToText();
                default:
                    return "";

            }
        }

        /// <summary>
        /// returns single object from list
        /// </summary>
        /// <param name="traitId"></param>
        /// <returns></returns>
        public ObservationAppLookup GetObsValue(int traitId)
        {
            var obsData = ObsValueList.FirstOrDefault(x => x.TraitID == traitId);
            return obsData;
        }

        /// <summary>
        /// returns correct observation value according to the datatype
        /// </summary>
        /// <param name="observationData"></param>
        /// <param name="dataType"></param>
        /// <returns></returns>
        public ObservationAppLookup ObservationWithCorrVal(ObservationAppLookup observation, string dataType, string value)
        {
            switch (dataType)
            {
                case "c":
                    observation.ObsValueChar = value;
                    return observation;
                case "i":
                    int i;
                    observation.ObsValueInt = int.TryParse(value, out i) ? i : (int?)null;// integerval) //Convert.ToInt32(value);
                    return observation;
                case "d":
                    DateTime dt;
                    observation.ObsValueDate = DateTime.TryParse(value, out dt) ? dt.ToString("yyyy-MM-ddTHH:mm:ss") : "";// Convert.ToDateTime(value);
                    return observation;
                case "a":
                    decimal dec;
                    if (CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator == ",")
                        observation.ObsValueDec.ToString().Replace(',', '.');
                    observation.ObsValueDec = decimal.TryParse(value, out dec) ? dec : (decimal?)null;// Convert.ToDecimal(value);
                    return observation;
                default:
                    return observation;

            }
        }

        public async Task GetObsValueList(string ezid, string traitIdList)
        {
            ObsValueList = await ObservationService.GetObservationDataAll(ezid, traitIdList);
        }
        public async Task GetPropObsValueList(string ezid, string traitIdList)
        {
            ObsValueList = await ObservationService.GetObservationPropDataAll(ezid, traitIdList);
        }

        public async Task GetCumulatedObsValue(string ezid, string traitIdList)
        {
            ObsValueListForCalculatedSum = await ObservationService.GetCumulatedObsValueAsync(ezid, traitIdList);
        }

        public async Task GetHistoryObservation(string ezid, int traitId, string datatype)
        {
            HistoryObservations = new ObservableCollection<ObservationAppHistory>();

            //No history data for newly created variety
            if (int.TryParse(ezid, out _))
            {
                var data = await ObservationService.GetHistoryObservation(ezid, traitId.ToString());

                //Convert ObservationAppLookUp to ObservationAppHistory
               var lst = data.Select(o => new ObservationAppHistory()
                {
                    EZID = o.EZID,
                    DateCreated = Convert.ToDateTime(o.DateCreated).ToString("dd-M-yy"),
                    TraitID = o.TraitID,
                    UserIDCreated = o.UserIDCreated,
                    ObsValue = GetDisplayObservation(o, datatype.ToLower())
                }).ToList();

                lst.ForEach(x => HistoryObservations.Add(x));
            }
        }
        public async Task GetHistoryObservationWithDate(string ezid, string traitIds)
        {
            HistoryObservations = new ObservableCollection<ObservationAppHistory>();
            //No history data for newly created variety
            if (int.TryParse(ezid, out _))
            {
                var data = await ObservationService.GetHistoryObservationDates(ezid, traitIds);
                data.OrderByDescending(x=>x.DateCreated);
                var lst = data.GroupBy(o => new 
                {
                    DateCreated = o.DateCreated,
                    UserIDCreated = o.UserIDCreated,
                }).Select(o=> new ObservationAppHistory
                {
                    DateCreated = o.Key.DateCreated,
                    UserIDCreated = o.Key.UserIDCreated,
                }).OrderByDescending(x=>x.DateCreated).ToList();
                if (lst.Any())
                {
                    lst[0].IsChecked = true;

                }
                lst.ForEach(x => HistoryObservations.Add(x));
            }
     
        }

            public async void Entry_Unfocused(object sender, FocusEventArgs e)
        {
            if (!(sender is Entry entry)) return;
            var traitId = Convert.ToInt32(entry.ClassId.Split('|')[0]);
            if (trait == null) return;

            if (trait.TraitID != traitId) return;
            if (trait.ValueBeforeChanged == trait.ObsValue)//this method is called to prevent on data saving because event is fired multiple times by default.
            {
                trait.ValidationErrorVisible = false;
                trait.ChangedValueVisible = trait.ObsvalueInitial != trait.ObsValue;
                return;
            }
            if (_isValidated)
            {
                trait.ValueBeforeChanged = trait.ObsValue;
                var observation = new ObservationAppLookup
                {
                    EZID = EzId,
                    TraitID = trait.TraitID,//traitId,
                                            // DateCreated = DateTime.UtcNow.Date.ToString("yyyy-MM-dd"),
                    DateCreated = ObservationDate.Date.ToString("yyyy-MM-ddTHH:mm:ss"),//DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss"),
                    DateUpdated = ObservationDate.Date.ToString("yyyy-MM-ddTHH:mm:ss"),//DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss"),
                    UserIDCreated = "user",
                    UserIDUpdated = "user",
                    Modified = true,
                    UoMCode = trait.UoMCode
                };

                observation = ObservationWithCorrVal(observation, DataType.ToLower(), entry.Text);

                try
                {
                    //Inserts or update based on property/trait and data in database
                    await InsertOrUpdateObservation(trait, observation);

                    await UpdateCumulatedData(trait.TraitID);
                    TrialService.UpdateTrialStatus(TrialEzId);
                    trait.ValidationErrorVisible = false;
                    if (trait.ObsvalueInitial != trait.ObsValue)
                    {
                        trait.RevertVisible = true;
                        trait.ChangedValueVisible = true;
                    }
                    else
                    {
                        trait.RevertVisible = false;
                        trait.ChangedValueVisible = false;
                    }
                    UpdatedUi();
                }
                catch (Exception ex)
                {

                    throw;
                }
                
            }
            else
            {
                trait.ValidationErrorVisible = true;
                trait.ChangedValueVisible = false;
                Device.BeginInvokeOnMainThread(() =>
                {
                    entry.Focus();
                });

            }
        }
        public async Task UpdateCumulatedData(int traitId)
        {
            var cumulatedTrait = TraitList.FirstOrDefault(x => x.TraitID == traitId && x.ColumnLabel == "Sum");
            if (cumulatedTrait == null) return;

            var updatedvalue = await ObservationService.GetCumulatedObsValueAsync(EzId, traitId.ToString());
            cumulatedTrait.ObsValue = updatedvalue.FirstOrDefault().CalculatedSum.ToString();

        }
        public async void DateEntry_Focused(object sender, FocusEventArgs e)
        {
            var entry = sender as Entry;
            var traitId = Convert.ToInt32(entry.ClassId.Split('|')[0]);
            DataType = entry.ClassId.Split('|')[1];
            Format = entry.ClassId.Split('|')[2];
            var trait = TraitList.FirstOrDefault(x => x.TraitID == traitId);
            if (trait == null) return;
            if (trait.DateVisible)
            {
                trait.DatePickerVisible = true;
                trait.DateVisible = false;
            }
            else if(trait.Editor && !TraitEditorPopupVisible)
            {
                //entry.Unfocus();
                await Task.Delay(200);
                TraitEditorPopupVisible = true;
                //this is the trick to fire text changed event so that it gain focus in popup control especially in IOS.
                TraitEditorValue = trait.ObsValue + ".";
                //reset text with original value.
                TraitEditorValue = trait.ObsValue;
                TraitEditorColumnLabel = trait.ColumnLabel;
                TraitEditorID = trait.TraitID;
                
            }
        }
        public async void Today_Clicked(object sender, EventArgs e)
        {
            var img = sender as Image;
            var traitId = Convert.ToInt32(img.ClassId.Split('|')[0]);
            var trait = TraitList.FirstOrDefault(x => x.TraitID == traitId);
            if (trait == null) return;
            if (trait.DateValue != DateTime.Today.Date)
            {
                var observation = new ObservationAppLookup
                {
                    EZID = EzId,
                    TraitID = traitId,
                    //DateCreated = DateTime.UtcNow.Date.ToString("yyyy-MM-dd"),
                    DateCreated = ObservationDate.Date.ToString("yyyy-MM-ddTHH:mm:ss"),//DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss"),
                    DateUpdated = ObservationDate.Date.ToString("yyyy-MM-ddTHH:mm:ss"),// DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss"),
                    UserIDCreated = "user",
                    UserIDUpdated = "user",
                    ObsValueDate = DateTime.Today.ToString("yyyy-MM-ddTHH:mm:ss"),// datePicker.Date,
                    Modified = true,
                    UoMCode = trait.UoMCode
                };

                //Inserts or update based on property/trait and data in database
                await InsertOrUpdateObservation(trait, observation);

                TrialService.UpdateTrialStatus(TrialEzId);
                trait.DatePickerVisible = false;
                trait.DateVisible = true;
                trait.DateValue = DateTime.Today.Date;
                trait.ValidationErrorVisible = false;
                trait.ChangedValueVisible = true;
                trait.RevertVisible = true;
                UpdatedUi();
            }
            else
            {
                trait.ValidationErrorVisible = false;
                trait.ChangedValueVisible = false;
                trait.RevertVisible = false;

            }
        }
        public void DatePicker_UnFocusedEX(object sender, FocusEventArgs e)
        {
            var datePicker = sender as DatePicker;
            var traitId = Convert.ToInt32(datePicker.ClassId.Split('|')[0]);
            var trait = TraitList.FirstOrDefault(x => x.TraitID == traitId);
            if (trait == null) return;

            trait.DatePickerVisible = false;
            trait.DateVisible = true;
        }
        public async void Picker_SelectedIndexChanged(object sender, EventArgs e)
        {
            var picker = sender as Picker;
            var obsValue = (picker.SelectedItem as TraitValue)?.TraitValueCode;
            if (picker.ClassId != null && picker.SelectedItem != null)
            {
                var traitId = Convert.ToInt32(picker.ClassId.Split('|')[0]);
                if (trait == null || trait.TraitID != traitId)
                {
                    trait = traitList?.FirstOrDefault(x => x.TraitID == traitId);
                    if (trait == null) return;
                }
                trait.ObsValue = obsValue;
                if (trait.ValueBeforeChanged == trait.ObsValue) //this method is called to prevent on data saving because event is fired multiple times by default.
                    return;

                var observation = new ObservationAppLookup
                {
                    EZID = EzId,
                    TraitID = traitId,
                    //DateCreated = DateTime.UtcNow.Date.ToString("yyyy-MM-dd"),
                    DateCreated = ObservationDate.Date.ToString("yyyy-MM-ddTHH:mm:ss"),//DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss"),
                    DateUpdated = ObservationDate.Date.ToString("yyyy-MM-ddTHH:mm:ss"),//DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss"),
                    UserIDCreated = "user",
                    UserIDUpdated = "user",
                    Modified = true,
                    UoMCode = trait.UoMCode
                };

                if (trait.DataType.ToLower() == "c")
                    observation.ObsValueChar = obsValue;
                else if (trait.DataType.ToLower() == "i")
                {
                    int.TryParse(obsValue, out int val);
                    observation.ObsValueInt = val;
                }
                else if (trait.DataType.ToLower() == "a")
                {
                    decimal.TryParse(obsValue, out decimal val);
                    observation.ObsValueDec = val;
                }
                else if (trait.DataType.ToLower() == "d")
                    observation.ObsValueDate = obsValue;

                //Inserts or update based on property/trait and data in database
                await InsertOrUpdateObservation(trait, observation);

                await UpdateCumulatedData(trait.TraitID);
                TrialService.UpdateTrialStatus(TrialEzId);
                trait.ValidationErrorVisible = false;
                trait.ValueBeforeChanged = trait.ObsItemPicker.TraitValueCode;
                if (trait.ObsValue != trait.ObsvalueInitial)
                {
                    trait.RevertVisible = true;
                    trait.ChangedValueVisible = true;
                }
                else
                {
                    trait.RevertVisible = false;
                    trait.ChangedValueVisible = false;
                }
                UpdatedUi();
            }
        }
        public async void Picker_SelectedIndexChanged1(object sender, EventArgs e)
        {
            var picker = sender as Picker;
            var value = (picker.SelectedItem as TraitValue)?.TraitValueCode;
            var traitId = 4185;

            var observation = new ObservationAppLookup
            {
                EZID = EzId,
                TraitID = traitId,
                //DateCreated = DateTime.UtcNow.Date.ToString("yyyy-MM-dd"),
                DateCreated = ObservationDate.Date.ToString("yyyy-MM-ddTHH:mm:ss"),//DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss"),
                DateUpdated = ObservationDate.Date.ToString("yyyy-MM-ddTHH:mm:ss"),
                UserIDCreated = "user",
                UserIDUpdated = "user",
                ObsValueChar = value,
                Modified = true
            };

            //Check if Observation for same EZID/TraitID already exists
            var existingdata = ObsValueList.FirstOrDefault(o => o.EZID == EzId && o.TraitID == traitId && o.DateCreated == ObservationDate.Date.ToString());

            // Update
            if (existingdata != null)
                await ObservationService.UpdateObservationDataForProperty(observation);
            // Create new
            else
                await ObservationService.InsertObservationData(observation);

            try
            {
                TrialService.UpdateTrialStatus(TrialEzId);
                UpdatedUi();
            }
            catch (Exception)
            {
            }
        }
        public async void DateData_DateSelected(object sender, DateChangedEventArgs e)
        {
            var datePicker = sender as DatePicker;
            var traitId = Convert.ToInt32(datePicker.ClassId.Split('|')[0]);
            var trait = TraitList?.FirstOrDefault(x => x.TraitID == traitId);
            if (trait == null) return;
            if (trait.ValueBeforeChanged == null && (datePicker.Date.ToString("yyyy-MM-dd") == trait.ObsvalueInitial))
                return;
            if (trait.ValueBeforeChanged == datePicker.Date.ToString("yyyy-MM-dd")) //this method is called to prevent on data saving because event is fired multiple times by default.
                return;
            trait.ValueBeforeChanged = datePicker.Date.ToString("yyyy-MM-dd");
            var observation = new ObservationAppLookup
            {
                EZID = EzId,
                TraitID = traitId,
                //DateCreated = DateTime.UtcNow.Date.ToString("yyyy-MM-dd"),
                DateCreated = ObservationDate.Date.ToString("yyyy-MM-ddTHH:mm:ss"),//DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss"),
                DateUpdated = ObservationDate.Date.ToString("yyyy-MM-ddTHH:mm:ss"),//DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss"),
                UserIDCreated = "user",
                UserIDUpdated = "user",
                ObsValueDate = datePicker.Date.ToString("yyyy-MM-ddTHH:mm:ss"),
                Modified = true,
                UoMCode = trait.UoMCode
            };

            //Inserts or update based on property/trait and data in database
            await InsertOrUpdateObservation(trait, observation);

            TrialService.UpdateTrialStatus(TrialEzId);
            trait.DatePickerVisible = false;
            trait.DateVisible = true;
            trait.ValidationErrorVisible = false;
            trait.ChangedValueVisible = true;
            trait.DateValueString = datePicker.Date.ToString("yyyy-MM-dd");
            if (trait.ObsvalueInitial != datePicker.Date.ToString("yyyy-MM-dd"))
            {
                trait.RevertVisible = true;
                trait.ChangedValueVisible = true;
            }
            else
            {
                trait.RevertVisible = false;
                trait.ChangedValueVisible = false;

            }
            UpdatedUi();
        }
        public async void Revert_Clicked(object sender, EventArgs e)
        {
            var img = sender as Image;
            var traitId = Convert.ToInt32(img.ClassId.Split('|')[0]);
            var trait = TraitList.FirstOrDefault(x => x.TraitID == traitId);
            if (trait == null)
                return;
            if (trait.DataType.ToLower() == "d")
            {
                trait.DateValueString = trait.ObsvalueInitial;
                trait.DateValue = (trait.DateVisible && trait.ObsvalueInitial != "") ? Convert.ToDateTime((trait.ObsValue.Split('T')[0])) : (DateTime?)null;
                var observation = new ObservationAppLookup
                {
                    EZID = EzId,
                    TraitID = traitId,
                    //DateCreated = DateTime.UtcNow.Date.ToString("yyyy-MM-dd"),
                    DateCreated = ObservationDate.Date.ToString("yyyy-MM-ddTHH:mm:ss"),//DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss"),
                    DateUpdated = ObservationDate.Date.ToString("yyyy-MM-ddTHH:mm:ss"),//DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss"),
                    UserIDCreated = "user",
                    UserIDUpdated = "user",
                    ObsValueDate = trait.DateValue?.ToString("yyyy-MM-ddTHH:mm:ss"),
                    Modified = true,
                    UoMCode = trait.UoMCode
                };

                if (trait.Property)
                    await ObservationService.UpdateObservationDataForProperty(observation);
                else
                    await ObservationService.UpdateObservationData(observation);
            }
            else
            {

                var observation = new ObservationAppLookup
                {
                    EZID = EzId,
                    TraitID = traitId,
                    //DateCreated = DateTime.UtcNow.Date.ToString("yyyy-MM-dd"),
                    DateCreated = ObservationDate.Date.ToString("yyyy-MM-ddTHH:mm:ss"),//DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss"),
                    DateUpdated = ObservationDate.Date.ToString("yyyy-MM-ddTHH:mm:ss"),//DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss"),
                    UserIDCreated = "user",
                    UserIDUpdated = "user",
                    Modified = true,
                    UoMCode = trait.UoMCode
                };
                observation = ObservationWithCorrVal(observation, trait.DataType.ToLower(), trait.ObsvalueInitial);

                if (trait.Property)
                    await ObservationService.UpdateObservationDataForProperty(observation);
                else
                    await ObservationService.UpdateObservationData(observation);
            }
            await UpdateCumulatedData(trait.TraitID);
            trait.ObsValue = trait.ObsvalueInitial;          
            trait.ValidationErrorVisible = false;
            trait.ChangedValueVisible = false;
            trait.RevertVisible = false;
        }
        public void EntryTextChanged(object sender, TextChangedEventArgs e)
        {
            var entry = sender as Entry;
            if (entry?.ClassId == null || TraitList == null) return;
            var traitId = Convert.ToInt32(entry.ClassId.Split('|')[0]);
            if (trait == null || trait.TraitID != traitId)
            {
                trait = TraitList?.FirstOrDefault(x => x.TraitID == traitId);
                if (trait == null) return;
            }
            string datatype = entry.ClassId.Split('|')[1];
            string format = entry.ClassId.Split('|')[2];
            if (datatype.ToLower() == "a" && !string.IsNullOrEmpty(entry.Text) && Device.Idiom == TargetIdiom.Phone)
                entry.Text = entry.Text.Replace('.', CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator.ToCharArray()[0]);
            var validateResult = Validation.validateTrait(datatype, format, entry.Text);
            if (string.IsNullOrEmpty(validateResult))
            {
                //enable picker control here
                foreach (var trait1 in TraitList?.Where(x => x.TraitID != trait.TraitID && x.ListOfValues).ToList())
                    trait1.Updatable = trait1.Updatable1;
                _isValidated = true;
                FieldsetPickerEnabled = true;
            }
            else
            {
                //disable picker control here
                foreach (var trait1 in TraitList?.Where(x => x.TraitID != trait.TraitID && x.ListOfValues).ToList())
                    trait1.Updatable = false;
                _isValidated = false;
                FieldsetPickerEnabled = false;
            }
        }

        public async Task InsertOrUpdateObservation(Trait trait, ObservationAppLookup observation)
        {
            //For Property 
            if (trait.Property)
            {
                //Check if Observation for same EZID/TraitID already exists
                var existingdata = ObsValueList.FirstOrDefault(o => o.EZID == EzId && o.TraitID == trait.TraitID);

                // Update
                if (existingdata != null)
                {
                    await ObservationService.UpdateObservationDataForProperty(observation);

                    //also update ObsValueList : so that no duplicate observation is created for same date/user when value updated without fetching again from db
                    ObsValueList.Remove(existingdata);
                    ObsValueList.Add(observation);
                }
                // Create new
                else
                {
                    await ObservationService.InsertObservationData(observation);

                    //also create new ObsValueList : so that no duplicate observation is created for same date/user when value updated without fetching again from db
                    ObsValueList.Add(observation);
                }
            }
            //For trait
            else
            {
                //Check if Observation for same EZID/TraitID/Date already exists
                var existingdata = ObsValueList.FirstOrDefault(o => o.EZID == EzId && o.TraitID == trait.TraitID && o.Modified && o.DateCreated == observation.DateCreated);

                // Update
                if (existingdata != null)
                {
                    await ObservationService.UpdateObservationData(observation);

                    //also update ObsValueList : so that no duplicate observation is created for same date/user when value updated without fetching again from db
                    ObsValueList.Remove(existingdata);
                    ObsValueList.Add(observation);
                }
                // Create new
                else
                {
                    await ObservationService.InsertObservationData(observation);

                    //also create new ObsValueList : so that no duplicate observation is created for same date/user when value updated without fetching again from db
                    ObsValueList.Add(observation);
                }
            }
        }

        /// <summary>
        /// Change the UI after value is updated in db
        /// </summary>
        public virtual void UpdatedUi()
        {
            HeaderColor = Color.Green;
            HeaderTextColor = Color.White;
        }

        /// <summary>
        /// Normal non modified UI page
        /// </summary>
        public virtual void NormalUi()
        {
            HeaderColor = Color.FromHex("#ebebeb");
            HeaderTextColor = Color.Black;
        }
    }
}
