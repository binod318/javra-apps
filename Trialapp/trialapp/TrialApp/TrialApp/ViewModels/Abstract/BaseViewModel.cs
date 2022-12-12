using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using Xamarin.Forms;
using TrialApp.Services;
using TrialApp.ViewModels.Interfaces;

namespace TrialApp.ViewModels
{
    public class BaseViewModel : ObservableViewModel, IViewModel
    {
        #region private variables

        private readonly Dictionary<string, object> _properties = new Dictionary<string, object>();
        private bool _isBusy;
        private string _userName;
        private ImageSource _filterIcon;
        private List<Entities.Master.Trait> _propertylist;
        private bool _gridviewVisible;
        private bool _listviewVisible;

        #endregion

        #region public properties
        
        //public IDataStore<Trial> DataStore => DependencyService.Get<IDataStore<Trial>>();
        public ImageSource FilterIcon
        {
            get { return _filterIcon; }
            set { _filterIcon = value; OnPropertyChanged(); }
        }
        public INavigation Navigation { get; set; }

        public IDependencyService DependencyService;
        public virtual string UserName
        {
            get { return _userName; }
            set
            {
                if (value.Contains("\\"))
                {
                    var DomainUserName = value.Split('\\');
                    WebserviceTasks.domain = DomainUserName[0];
                    _userName = DomainUserName[1];
                }
                else
                {
                    _userName = value;
                    WebserviceTasks.domain = "INTRA";
                }
                OnPropertyChanged();
            }
        }

        public bool IsBusy
        {
            get { return _isBusy; }
            set
            {
                _isBusy = value;
                OnPropertyChanged();
            }
        }

        public List<Entities.Master.Trait> Propertylist
        {
            get { return _propertylist; }
            set
            {
                _propertylist = value;
                OnPropertyChanged();
            }
        }

        public bool GridviewVisible
        {
            get { return _gridviewVisible; }
            set
            {
                _gridviewVisible = value;
                ListviewVisible = !value;
                OnPropertyChanged();
            }
        }

        public bool ListviewVisible
        {
            get { return _listviewVisible; }
            set
            {
                _listviewVisible = value;
                OnPropertyChanged();
            }
        }

        #endregion

        protected void SetValue<T>(T value, [CallerMemberName] string propertyName = null)
        {
            if (!_properties.ContainsKey(propertyName))
            {
                _properties.Add(propertyName, default(T));
            }

            var oldValue = GetValue<T>(propertyName);
            if (!EqualityComparer<T>.Default.Equals(oldValue, value))
            {
                _properties[propertyName] = value;
                OnPropertyChanged(propertyName);
            }
        }

        protected T GetValue<T>([CallerMemberName] string propertyName = null)
        {
            if (!_properties.ContainsKey(propertyName))
            {
                return default(T);
            }
            else
            {
                return (T)_properties[propertyName];
            }
        }

        protected BaseViewModel() : this(new DependencyServiceWrapper())
        {

        }

        protected BaseViewModel(IDependencyService dependencyService)
        {
            DependencyService = dependencyService;
        }
        
        //string title = string.Empty;
        //public string Title
        //{
        //    get { return title; }
        //    set { SetProperty(ref title, value); }
        //}
  
    }

    public abstract class ObservableViewModel : INotifyPropertyChanged
    {
        public event PropertyChangedEventHandler PropertyChanged;

        protected void OnPropertyChanged([CallerMemberName] string name = "")
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
        }

    }
}
