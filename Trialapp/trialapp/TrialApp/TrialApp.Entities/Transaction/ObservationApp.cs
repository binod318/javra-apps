using System;
using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace TrialApp.Entities.Transaction
{
    public class ObservationAppLookup
    {
        public string EZID { get; set; }
        public int TraitID { get; set; }
        public string DateCreated { get; set; }
        public string DateUpdated { get; set; }
        public string UserIDCreated { get; set; }
        public string UserIDUpdated { get; set; }
        public string ObsValueChar { get; set; }
        public int? ObsValueInt { get; set; }
        public bool IsNullEntry { get; set; }
        private decimal? _obsValueDec { get; set; }

        public decimal? ObsValueDec
        {
            get { return UnitOfMeasure.SystemUoM == "Imperial" ? ObsValueDecImp : ObsValueDecMet; }
            set
            {
                _obsValueDec = value;
                if (UnitOfMeasure.SystemUoM == "Imperial")
                    ObsValueDecImp = value;
                else
                    ObsValueDecMet = value;
            }
        }

        public decimal? ObsValueDecImp { get; set; }
        public decimal? ObsValueDecMet { get; set; }
        public string ObsValueDate { get; set; }
        public string UoMCode { get; set; }
        public bool Modified { get; set; }
        public int? ObservationId { get; set; }
    }

    public class ObservationApp
    {
        public string EZID { get; set; }
        public int TraitID { get; set; }
        public string DateCreated { get; set; }
        public string DateUpdated { get; set; }
        public string UserIDCreated { get; set; }
        public string UserIDUpdated { get; set; }
        public string ObsValueChar { get; set; }
        public int? ObsValueInt { get; set; }
        public decimal? ObsValueDecImp { get; set; }
        public decimal? ObsValueDecMet { get; set; }
        public string ObsValueDate { get; set; }
        public bool Modified { get; set; }
        public int? ObservationId { get; set; }
        public string UoMCode { get; set; }
    }

    public class ObservationAppCalculatedSum
    {
        public decimal CalculatedSum { get; set; }
        public int TraitID { get; set; }
    }

    public class ObservationAppHistory:INotifyPropertyChanged
    {
        public string EZID { get; set; }
        public int TraitID { get; set; }
        public string DateCreated { get; set; }
        public string UserIDCreated { get; set; }
        public string ObsValue { get; set; }
        public string DataType { get; set; }

        private bool isCheck;

        public bool IsChecked
        {
            get
            {
                return isCheck;
            }
            set
            {
                if (value != this.isCheck)
                {
                    this.isCheck = value;
                    NotifyPropertyChanged();
                }
            }
        }
        public event PropertyChangedEventHandler PropertyChanged;
        private void NotifyPropertyChanged([CallerMemberName] String propertyName = "")
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }

    }
}
