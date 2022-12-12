using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Input;
using TrialApp.Entities.Transaction;
using TrialApp.Services;
using TrialApp.Views;
using Xamarin.Forms;

namespace TrialApp.ViewModels
{
    public class VarietyPageViewModel : VarietyBaseViewModel
    {
        #region private variables

        private string _mainText;
        private List<Entities.Master.Trait> _traitlist;

        #endregion

        #region public properties

        public List<VarietyData> VarietyList { get; set; }        
        public string MainText { get { return _mainText; } set { _mainText = value;
                OnPropertyChanged();
            } }

        public ICommand AddVarietyCommand { get; set; }
        public TraitService TraitSrv;
        public Entities.Master.Trait TraitSelectedFirst { get; set; }
        public Entities.Master.Trait TraitSelectedSecond { get; set; }
        public List<Entities.Master.Trait> Traitlist
        {
            get { return _traitlist; }
            set
            {
                _traitlist = value;
                OnPropertyChanged();
            }
        }

        #endregion

        public VarietyPageViewModel(int ezid, string trialName, string cropCode)
        {
            TrialEZID = ezid;
            TrialName = trialName;
            CropCode = cropCode;
            //AddVarietyCommand = new AddVariety();
            //CreateNewVarietyCommand = new CreateNewVariety();
            TraitSrv = new TraitService();
            LoadTrialPropParams();
        }

        public async void LoadVarietyPageViewModel(int ezid, string trialName, Action<List<VarietyData>> predicate)
        {
            var res = await LoadVarieties(ezid, trialName);
            var varietiesEzids = string.Join(",", VarietyList.Select(x => "'"+ x.VarietyId +"'"));
            await LoadTraitsHavingObservation(varietiesEzids);
            string trait1 = TraitSelectedFirst == null ? string.Empty : TraitSelectedFirst.TraitID.ToString();
            string trait2 = TraitSelectedSecond == null ? string.Empty : TraitSelectedSecond.TraitID.ToString();
            if (!string.IsNullOrWhiteSpace(trait1) || !string.IsNullOrWhiteSpace(trait2))
            {
                await LoadObservationData(trait1, trait2);
            }
            predicate(res);
        }

        /// <summary>
        /// Load Traits list which have observation data of variety provided on parameter
        /// </summary>
        /// <param name="varietyEZIDs"> Comma seperated variety EZIDs</param>
        /// <returns></returns>
        public async Task LoadTraitsHavingObservation(string varietyEZIDs)
        {
            var traitList = await _observationService.LoadTraitsHavingObservation(varietyEZIDs);
            var traitIDs = string.Join(",", traitList.Select(x => x.TraitID.ToString()));
            if (!string.IsNullOrWhiteSpace(traitIDs))
            {
                var data = await TraitSrv.GetTraitsAsync(traitIDs);
                if (Traitlist == null || Traitlist.Count < data.Count)
                    Traitlist = data;
            }
        }

        private async Task<List<VarietyData>> LoadVarieties(int ezid, string trialName)
        {
            MainText = trialName;
            VarietyList = new List<VarietyData>();

            var trialList = await _trialEntryAppService.GetVarietiesListAsync(ezid);
            foreach (var val in trialList)
            {
                var vvar = new VarietyData
                {
                    VarietyId = val.EZID,
                    FieldNumber = val.FieldNumber,
                    VarietyName = val.VarietyName,
                    Crop = val.CropCode
                };
                VarietyList.Add(vvar);
            }
            return VarietyList;
        }

        public async Task LoadObservationData(string trait1,string trait2)
        {
            var EZIDs = string.Join(",", VarietyList.Select(x => "'" + x.VarietyId + "'")); //variety id is changed to  quoted format because where clause on ezid is changed to in () so need same type data.
            string TraitIDs = string.Empty;
            if (!string.IsNullOrWhiteSpace(trait1) && !string.IsNullOrWhiteSpace(trait2))
                TraitIDs = string.Join(",", trait1, trait2);
            else if (!string.IsNullOrWhiteSpace(trait1))
                TraitIDs = trait1;
            else if (!string.IsNullOrWhiteSpace(trait2))
                TraitIDs = trait2;

            if(!string.IsNullOrWhiteSpace(TraitIDs) && !string.IsNullOrWhiteSpace(EZIDs))
            {
                var result = await _observationService.GetObservationDataAll(EZIDs, TraitIDs);
                foreach(var _val in VarietyList)
                {
                    if(!string.IsNullOrWhiteSpace(trait1) && !string.IsNullOrWhiteSpace(trait2))
                    {
                        var obs1 = result.FirstOrDefault(x => x.EZID == _val.VarietyId && x.TraitID.ToString() == trait1);
                        _val.ObsvalueTrait1 = obs1 == null?"": ReturnObsData(obs1, TraitSelectedFirst);

                        var obs2 = result.FirstOrDefault(x => x.EZID == _val.VarietyId && x.TraitID.ToString() == trait2);
                        _val.ObsvalueTrait2 = obs2 == null? "": ReturnObsData(obs2, TraitSelectedSecond);
                    }
                    else if (!string.IsNullOrWhiteSpace(trait1))
                    {
                        var obs1 = result.FirstOrDefault(x => x.EZID == _val.VarietyId && x.TraitID.ToString() == trait1);
                        _val.ObsvalueTrait1 = obs1 == null ? "" : ReturnObsData(obs1, TraitSelectedFirst);
                    }
                    else if(!string.IsNullOrWhiteSpace(trait2))
                    {
                        var obs2 = result.FirstOrDefault(x => x.EZID == _val.VarietyId && x.TraitID.ToString() == trait2);
                        _val.ObsvalueTrait2 = obs2 == null ? "" : ReturnObsData(obs2, TraitSelectedSecond);
                    }
                }
            }
                
        }

        private string ReturnObsData(ObservationAppLookup obs, Entities.Master.Trait trait)
        {
            if (trait.DataType.ToLower() == "i")
                return obs.ObsValueInt?.ToString();
            else if (trait.DataType.ToLower() == "c")
                return obs.ObsValueChar;
            else if (trait.DataType.ToLower() == "a")
                return obs.ObsValueDec?.ToString();
            else if (trait.DataType.ToLower() == "d")
            {
                var dateval = obs.ObsValueDate == null ? "" : obs.ObsValueDate.ToString();
                if (!string.IsNullOrWhiteSpace(dateval))
                {
                    DateTime.TryParse(dateval, out DateTime dt);
                    return dt.Date.ToString("yyyy-MM-dd");
                }
            }
            return "";
                
        }
        private class AddVariety : ICommand
        {
            public event EventHandler CanExecuteChanged;

            public bool CanExecute(object parameter)
            {
                return true;
            }

            public void Execute(object parameter)
            {
                var vm = parameter as VarietyPageViewModel;
                vm.AddVarietyPopupVisible = true;
            }
        }

        private class CreateNewVariety : ICommand
        {
            public event EventHandler CanExecuteChanged;

            public bool CanExecute(object parameter)
            {
                if (!(parameter is VarietyPageViewModel ViewModel))
                    return false;
                else if (!ViewModel.ButtonEnabled)
                    return false;
                return true;
            }

            public async void Execute(object parameter)
            {
                var vm = parameter as VarietyPageViewModel;

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
                    if (await vm._trialEntryAppService.AddVariety(trialEntry, relationShip) > 0)
                    {
                        vm.VarietyName = "";
                        vm.ConsecutiveNumber = null;
                        vm.ConfirmationColor = Color.Green;
                        vm.ConfirmationMessage = "New variety added.";
                    }
                    else
                    {
                        vm.ConfirmationColor = Color.Red;
                        vm.ConfirmationMessage = "Unable to add new variety.";
                    }

                    vm.AddVarietyPopupVisible = false;
                }
            }
        }
    }
}
