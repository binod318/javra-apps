using System.Collections.Generic;

namespace TrialApp.ViewModels.Abstract
{
    public class GridFilterViewModel : PictureBaseViewModel
    {
        public GridFilterViewModel()
        {
        }

        #region Filtering

        #region Fields

        private string filtertext = "";
        private string selectedcolumn = "All Columns";
        private string selectedcondition = "Contains";

        internal delegate void FilterChanged();

        internal FilterChanged filtertextchanged;

        #endregion

        #region Property

        public string FilterText
        {
            get { return filtertext; }
            set
            {
                filtertext = value;
                OnFilterTextChanged();
                OnPropertyChanged("FilterText");
            }

        }

        public string SelectedCondition
        {
            get { return selectedcondition; }
            set { selectedcondition = value; }
        }

        public string SelectedColumn
        {
            get { return selectedcolumn; }
            set { selectedcolumn = value; }
        }
        
        #endregion

        #region Private Methods

        private void OnFilterTextChanged()
        {
            if (filtertextchanged != null)
                filtertextchanged();
        }
        
        #endregion

        #region Public Methods

        public bool FilerRecords(object o)
        {
            double res;
            bool checkNumeric = double.TryParse(FilterText, out res);
            var item = o as IDictionary<string, object>;
            if (item != null && FilterText.Equals("") && !string.IsNullOrEmpty(FilterText))
            {
                return true;
            }
            else
            {
                if (item != null)
                {
                    if (checkNumeric && !SelectedColumn.Equals("All Columns") && !SelectedCondition.Equals("Contains"))
                    {
                        //bool result = MakeNumericFilter(item, SelectedColumn, SelectedCondition);
                        //return result;
                        return true;
                    }
                    // filtering on All columns
                    else if (SelectedColumn.Equals("All Columns"))
                    {
                        foreach (KeyValuePair<string, object> kvp in item)
                        {
                            if (kvp.Value != null && kvp.Value.ToString().ToLower().Contains(FilterText.ToLower()))
                                return true;
                        }

                        return false;
                    }
                    else
                    {
                        //bool result = MakeStringFilter(item, SelectedColumn, SelectedCondition);
                        //return result;
                        return true;
                    }
                }
            }
            return false;
        }

        #endregion

        #endregion

    }
}
