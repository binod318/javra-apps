using System;
using System.Threading.Tasks;
using TrialApp.ViewModels;
using Xamarin.Forms;
using System.Globalization;
using TrialApp.Entities.Transaction;
using Xamarin.Forms.Xaml;
using Xamarin.Forms.Maps;
using Xamarin.Essentials;

namespace TrialApp.Views
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class LocationPage : ContentPage
    {
        private readonly LocationPageViewModel vm;

        public LocationPage(TrialLookUp trial)
        {
            InitializeComponent();
            vm = new LocationPageViewModel(trial);
            BindingContext = vm;
            Device.BeginInvokeOnMainThread(async () =>
            {
                await ProceedLocation();
            });
        }

        public async Task ProceedLocation()
        {
            try
            {
                if (await CheckLocationSettings())
                {
                    var status = await Permissions.CheckStatusAsync<Permissions.LocationWhenInUse>();
                    if (status != PermissionStatus.Granted)
                    {
                        status = await Permissions.RequestAsync<Permissions.LocationWhenInUse>();
                    }
                    
                    if(status == PermissionStatus.Granted && vm.Position == null)
                        vm.Position = await Geolocation.GetLocationAsync();

                    await UpdateLocation(false, false);
                }

            }
            catch (Exception)
            {
            }
        }

        public async Task<bool> CheckLocationSettings()
        {
            try
            {
                var request = new GeolocationRequest(GeolocationAccuracy.Medium);
                vm.Position = await Geolocation.GetLocationAsync(request);

                if (vm.Position != null)
                    return true;

                return false;
            }
            catch (FeatureNotSupportedException)
            {
                // Handle not supported on device exception
                return false;
            }
            catch (FeatureNotEnabledException)
            {
                var isAllowed = await DisplayAlert("Enable location", "Your location settings is set to off. Please enable location to use this feature.", "Open settings", "Cancel");
                if (isAllowed)
                    DependencyService.Get<Helper.ILocSettings>().OpenLocationSettings();

                return false;
            }
            catch (PermissionException)
            {
                // Handle permission exception
                var isAllowed = await DisplayAlert("Location Permission", "Please allow app to use location to use this feature.", "Open settings", "Cancel");
                if (isAllowed)
                    DependencyService.Get<Helper.ILocSettings>().OpenApplicationSettings();

                return false;
            }
            catch (Exception)
            {
                await DisplayAlert("Alert", "Unable to get location.", "OK");
                return false;
            }
        }

        protected override void OnDisappearing()
        {
            base.OnDisappearing();
            if (ValidateCoordinates(vm.Longitude, vm.Latitude))
                vm.SaveLongitudeLatitude(vm.Trial, vm.Longitude.Replace(',', '.'), vm.Latitude.Replace(',', '.'));
        }
        
        private void AddPin(Location position1)
        {
            var pin = new Pin
            {
                Type = PinType.Generic,
                Position = new Position(position1.Latitude, position1.Longitude),
                Label = "Current location",
                Address = "Current location"
            };
            MyMap.Pins.Clear();
            MyMap.Pins.Add(pin);
        }

        public async void GetPosition_Click(object sender, EventArgs e)
        {
            if (vm.Position != null || (await CheckLocationSettings()))
            {
                await UpdateLocation(true, true);
                vm.SaveLongitudeLatitude(vm.Trial, vm.Longitude.Replace(',', '.'), vm.Latitude.Replace(',', '.'));
            }
        }

        private async Task UpdateLocation(bool isCurrentPosition, bool updateLocation)
        {
            try
            {
                if (isCurrentPosition)
                {
                    if(vm.Position != null)
                    {
                        vm.Latitude = Math.Round(vm.Position.Latitude, 5).ToString();
                        vm.Longitude = Math.Round(vm.Position.Longitude, 5).ToString();
                    }
                }

                //here check network and show proper message here
                if(Connectivity.NetworkAccess == NetworkAccess.Internet)
                {
                    if (string.IsNullOrEmpty(vm.Latitude) && string.IsNullOrEmpty(vm.Longitude) && vm.Position != null)
                    {
                        MyMap.MoveToRegion(MapSpan.FromCenterAndRadius(
                            new Xamarin.Forms.Maps.Position(vm.Position.Latitude, vm.Position.Longitude),
                            Distance.FromMiles(0.3)));
                    }
                    else if (updateLocation && isCurrentPosition)
                    {
                        MyMap.MoveToRegion(MapSpan.FromCenterAndRadius(
                            new Xamarin.Forms.Maps.Position(vm.Position.Latitude, vm.Position.Longitude),
                            Distance.FromMiles(0.3)));

                        AddPin(vm.Position);
                    }
                    else if (!updateLocation && isCurrentPosition)
                    {
                        MyMap.MoveToRegion(MapSpan.FromCenterAndRadius(
                            new Xamarin.Forms.Maps.Position(vm.Position.Latitude, vm.Position.Longitude),
                            Distance.FromMiles(0.3)));
                        AddPin(vm.Position);
                    }
                    else
                    {
                        if (double.TryParse(vm.Latitude, out double latitude) &&
                            double.TryParse(vm.Longitude, out double longitude))
                        {
                            if (ValidateCoordinates(longitude.ToString(), latitude.ToString()))
                            {
                                MyMap.MoveToRegion(MapSpan.FromCenterAndRadius(
                                    new Xamarin.Forms.Maps.Position(latitude, longitude),
                                    Distance.FromMiles(0.3)));
                                
                                var currentPosition = new Location()
                                {
                                    Latitude = latitude,
                                    Longitude = longitude
                                };

                                AddPin(currentPosition);

                                await Task.Delay(100);
                            }
                            else
                                await DisplayAlert("Error", vm.InvalidCoordinatesMsg, "OK");
                        }
                        else
                            await DisplayAlert("Error", vm.InvalidCoordinatesMsg, "OK");
                    }
                }
                else
                {
                    if (ValidateCoordinates(vm.Longitude, vm.Latitude))
                        await DisplayAlert("Warning", "No internet connection. Unable to update map.", "OK");
                    else
                        await DisplayAlert("Error", vm.InvalidCoordinatesMsg, "OK");
                }
            }
            catch (Exception)
            {
            }
        }

        public void BtnStreet_Click(object sender, EventArgs e)
        {
            MyMap.MapType = MapType.Street;
        }
        public void BtnSatellite_Click(object sender, EventArgs e)
        {
            MyMap.MapType = MapType.Satellite;
        }
        public void BtnHybrid_Click(object sender, EventArgs e)
        {
            MyMap.MapType = MapType.Hybrid;
        }

        private async void LongitudeLatitude_Unfocused(object sender, FocusEventArgs e)
        {
            var entry = sender as Entry;
            var classid = entry.ClassId;
            var entryVal = entry.Text.Replace('.', CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator.ToCharArray()[0]);
            if (!double.TryParse(entryVal, out double value))
            {
                if (!string.IsNullOrWhiteSpace(vm.Trial.Longitude) && !string.IsNullOrWhiteSpace(vm.Trial.Latitude))
                {
                    await DisplayAlert("Error", vm.InvalidCoordinatesMsg, "OK");
                    entry.TextColor = Color.Red;
                    entry.Focus();
                }
            }
            else
            {
                entry.TextColor = Color.Default;
                entry.Text = Math.Round(value, 5).ToString();
                if (ValidateCoordinates(vm.Longitude, vm.Latitude))
                    vm.SaveLongitudeLatitude(vm.Trial, vm.Longitude.Replace(',', '.'), vm.Latitude.Replace(',', '.'));
                else
                {
                    await DisplayAlert("Error", vm.InvalidCoordinatesMsg, "OK");
                    if(string.IsNullOrWhiteSpace(vm.Longitude))
                    {
                        Longitude.TextColor = Color.Red;
                        Longitude.Focus();
                    }
                    else if (string.IsNullOrWhiteSpace(vm.Latitude))
                    {
                        Latitude.TextColor = Color.Red;
                        Latitude.Focus();
                    }
                }
            }
        }

        private async void BtnUpdate_Clicked(object sender, EventArgs e)
        {
            if (ValidateCoordinates(vm.Longitude, vm.Latitude))
                await UpdateLocation(false, true);
        }

        private bool ValidateCoordinates(string longitude, string latitude)
        {
            if (double.TryParse(latitude, out double outLat) && double.TryParse(longitude, out double outLong))
            {
                if (outLat > 90 || outLat < -90 || outLong > 180 || outLong < -180)
                    return false;
            }
            else
                return false;

            return true;
        }
    }
}