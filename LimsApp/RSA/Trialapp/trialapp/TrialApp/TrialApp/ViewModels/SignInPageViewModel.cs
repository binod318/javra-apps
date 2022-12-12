using System;
using System.Threading.Tasks;
using System.Windows.Input;
using TrialApp.Entities;
using TrialApp.Entities.ServiceResponse;
using TrialApp.ServiceClient;
using TrialApp.Services;
using Xamarin.Essentials;
using Xamarin.Forms;

namespace TrialApp.ViewModels
{
    public class SignInPageViewModel : BaseViewModel
    {
        #region Private variables

        private string _password;
        private bool _loginButtonEnable;
        private string _errorMessage;
        private bool _errorMsgVisible;
        private bool _UserNameEnable;
        private bool _passwordEnable;
        private Color _buttonColor;
        private readonly SettingParametersService _setPar;

        #endregion

        #region public properties
        public double FontSizeMedium { get; set; }
        public double FontSizeLarge { get; set; }
        public double FontSizeDefault { get; set; }
        public ICommand LogInCommand { get; set; }
        public ICommand CancelSignIn { get; set; }
        public override string UserName
        {
            get
            {
                return base.UserName;
            }

            set
            {
                base.UserName = value;
                LoginButtonEnable = !string.IsNullOrEmpty(Password) && !string.IsNullOrEmpty(UserName);
                OnPropertyChanged(nameof(LoginButtonEnable));
            }
        }
        public string Password
        {
            get { return _password; }
            set
            {
                _password = value;
                OnPropertyChanged();
                LoginButtonEnable = !string.IsNullOrEmpty(UserName) && !string.IsNullOrEmpty(Password);
                OnPropertyChanged(nameof(LoginButtonEnable));
            }
        }
        public bool LoginButtonEnable
        {
            get { return _loginButtonEnable; }
            set
            {
                _loginButtonEnable = value;

                if (_loginButtonEnable)
                    ButtonColor = Color.FromHex("#2B7DF4");
                else
                    ButtonColor = Color.FromHex("#ebebeb");
                OnPropertyChanged();
            }

        }
        public string ErrorMessage
        {
            get { return _errorMessage; }
            set
            {
                _errorMessage = value;
                OnPropertyChanged();
            }
        }
        public bool ErrorMsgVisible
        {
            get { return _errorMsgVisible; }
            set
            {
                _errorMsgVisible = value;
                OnPropertyChanged();
            }
        }
        public bool PasswordEnable
        {
            get { return _passwordEnable; }
            set
            {
                _passwordEnable = value;
                OnPropertyChanged();
            }
        }
        public bool UserNameEnable
        {
            get { return _UserNameEnable; }
            set
            {
                _UserNameEnable = value;
                OnPropertyChanged();
            }
        }
        public Color ButtonColor
        {
            get { return _buttonColor; }
            set
            {
                _buttonColor = value;
                OnPropertyChanged();
            }
        }

        #endregion

        public SignInPageViewModel()
        {
            LogInCommand = new LoginOperation();
            CancelSignIn = new CancelOperation();
            UserNameEnable = true;
            PasswordEnable = true;
            IsBusy = false;
            _setPar = new SettingParametersService();
        }

        public SignInPageViewModel(INavigation navigation)
        {
            Navigation = navigation;
            LogInCommand = new LoginOperation();
            CancelSignIn = new CancelOperation();
            IsBusy = false;
        }
        
        public async Task<bool> LoginOperation()
        {
            try
            {
                var cread = "";
                if (App.IsAADLogin)
                    cread = WebserviceTasks.domain + "\\" + App.ServiceAccName + ":" + App.ServiceAccPswrd;
                else
                {
                    WebserviceTasks.ServiceUsername = UserName; WebserviceTasks.ServicePassword = Password;
                    cread = WebserviceTasks.domain + "\\" + UserName + ":" + Password;
                }
                var soapClient = new SoapClient
                {
                    EndPointAddress = WebserviceTasks.Endpoint,
                    Credentail = cread//WebserviceTasks.domain + "\\" + App.ServiceAccName + ":" + App.ServiceAccPswrd//new NetworkCredential { Domain = "INTRA", UserName = UserName, Password = Password }
                };

                var authRequest = new GetTrialTokenBack()
                {
                    cropCode = "TO",
                    userName = WebserviceTasks.domain + "/" + UserName,
                    password = Password
                };
                var result = await soapClient.GetResponse<GetTrialTokenBack, GetTrialTokenBackResponse>(authRequest, WebserviceTasks.AdToken);
                WebserviceTasks.UsernameWS = UserName;
                WebserviceTasks.PasswordWS = Password;
                WebserviceTasks.Token = result.tuple.old.TokenInformation.Token;
                WebserviceTasks.TokenExpiryDate = GetTokenExpiryDate(result.tuple.old.TokenInformation.IssueDate, result.tuple.old.TokenInformation.ExpiryDate);
                _setPar.UpdateParams("loggedinuser", UserName);
                return true;
            }
            catch (Exception ex)
            {
                ErrorMessage = ex.Message;
                return false;
            }
        }

        private DateTime GetTokenExpiryDate(DateTime issueDate, DateTime expiryDate)
        {
            return DateTime.Now.Add(expiryDate - issueDate);
        }

        private void PutDefaultValues()
        {
            FontSizeMedium = Device.GetNamedSize(NamedSize.Medium, typeof(Label));
            FontSizeLarge = Device.GetNamedSize(NamedSize.Large, typeof(Label));
            FontSizeDefault = Device.GetNamedSize(NamedSize.Default, typeof(Label));
            UserName = "";
            _password = "";
            _errorMessage = "";
            _loginButtonEnable = false;
            _errorMsgVisible = false;
        }
    }

    internal class LoginOperation : ICommand
    {
        private SignInPageViewModel _signinViewModel;
        private SettingParametersService _settingParametersService;
        public LoginOperation()
        {
        }

        public event EventHandler CanExecuteChanged;

        public bool CanExecute(object parameter)
        {
            return true;
        }

        public async void Execute(object parameter)
        {
            _signinViewModel = parameter as SignInPageViewModel;
            _settingParametersService = new SettingParametersService();
            
            DisableUi();

            if (Connectivity.NetworkAccess == NetworkAccess.Internet)
            {
                _signinViewModel.ErrorMessage = "";
                _signinViewModel.ErrorMsgVisible = false;

                if (await _signinViewModel.LoginOperation())
                {
                    if (_settingParametersService.CheckNotification() && WebserviceTasks.CheckTokenValidDate())
                        WebserviceTasks.GoDownload = true;
                    await App.MainNavigation.PopToRootAsync();
                }
                else
                    _signinViewModel.ErrorMsgVisible = true;
            }
            else
            {
                _signinViewModel.ErrorMessage = "No internet connection.";
                _signinViewModel.ErrorMsgVisible = true;
            }
            EnableUi();
        }

        /// <summary>
        /// Disable UI during load
        /// </summary>
        private void DisableUi()
        {
            _signinViewModel.IsBusy = true;
            _signinViewModel.UserNameEnable = false;
            _signinViewModel.PasswordEnable = false;
            _signinViewModel.LoginButtonEnable = false;
        }

        /// <summary>
        /// Enable UI after load
        /// </summary>
        private void EnableUi()
        {
            _signinViewModel.IsBusy = false;
            _signinViewModel.UserNameEnable = true;
            _signinViewModel.PasswordEnable = true;
            _signinViewModel.LoginButtonEnable = true;
        }
    }
}
