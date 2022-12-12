using System.Globalization;
using TrialApp.Entities.Transaction;
using TrialApp.Services;
using Xamarin.Essentials;
using Xamarin.Forms;

namespace TrialApp.ViewModels
{
    public class LocationPageViewModel : ObservableViewModel
    {
        private string longitude;
        private string latitude;
        private int _currentTrial;
        private string _currentTrialName;
        private string _crop;
        private TrialLookUp _trial;
        public TrialService TrialService { get; set; }
        private Color _headerColor;
        private Color _headerTextColor;
        
        public Location Position { get; set; }
        public string InvalidCoordinatesMsg { get; set; } = "Invalid GPS coordinates.";

        public Color HeaderColor
        {
            get { return _headerColor; }
            set
            {
                _headerColor = value;
                OnPropertyChanged();
            }
        }
        public Color HeaderTextColor
        {
            get { return _headerTextColor; }
            set
            {
                _headerTextColor = value;
                OnPropertyChanged();
            }
        }
        public TrialLookUp Trial
        {
            get { return _trial; }
            set { _trial = value; OnPropertyChanged(); }
        }
        public string CurrentTrialName
        {
            get { return _currentTrialName; }
            set { _currentTrialName = value; OnPropertyChanged(); }
        }
        public string Crop
        {
            get { return _crop; }
            set { _crop = value; OnPropertyChanged(); }
        }

        public int CurrentTrial
        {
            get { return _currentTrial; }
            set { _currentTrial = value; OnPropertyChanged(); }
        }
        public string Longitude
        {
            get { return longitude; }
            set { longitude = value.Replace('.', CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator.ToCharArray()[0]); OnPropertyChanged(); }
        }

        public string Latitude
        {
            get { return latitude; }
            set { latitude = value.Replace('.', CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator.ToCharArray()[0]); OnPropertyChanged(); }
        }

        public LocationPageViewModel(TrialLookUp trial)
        {
            Trial = trial;
            if (trial.StatusCode == 30)
            {
                HeaderColor = Color.Green;
                HeaderTextColor = Color.White;
            }
            else
            {
                HeaderColor = Color.FromHex("#ebebeb");
                HeaderTextColor = Color.Black;
            }
            CurrentTrialName = trial.TrialName;
            Longitude = trial.Longitude;
            Latitude = trial.Latitude;
            TrialService = new TrialService();
        }

        internal async void SaveLongitudeLatitude(TrialLookUp trial, string longitude, string latitude)
        {
            if (trial.Latitude != latitude || trial.Longitude != longitude)
            {
                trial.Latitude = latitude;
                trial.Longitude = longitude;

                await TrialService.UpdateGPSCoordinate(trial);

                HeaderColor = Color.Green;
                HeaderTextColor = Color.White;
            }
        }
    }
}
