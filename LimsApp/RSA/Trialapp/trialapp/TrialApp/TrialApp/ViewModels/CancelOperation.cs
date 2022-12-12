using System;
using System.Windows.Input;
using TrialApp.Services;

namespace TrialApp.ViewModels
{
    internal class CancelOperation : ICommand
    {
        public CancelOperation()
        {
        }

        public event EventHandler CanExecuteChanged { add { } remove { } }
        public static SettingParametersService _settingParametersService = new SettingParametersService();

        public bool CanExecute(object parameter)
        {
            return true;

        }

        public async void Execute(object parameter)
        {
            if (parameter is SignInPageViewModel)
            {
                var signInViewModel = parameter as SignInPageViewModel;
                signInViewModel.UserName = "";
                var TrialsFromNotification = _settingParametersService.GetEZIDsFromNotification();
                _settingParametersService.DeleteNotificationLog(String.Join(",", TrialsFromNotification.ToArray()));
                await App.MainNavigation.PopAsync();
            }
            else if (parameter is FilterPageViewModel)
            {
                var vm = parameter as FilterPageViewModel;
                await App.MainNavigation.PopAsync();
            }
        }
    }
}
