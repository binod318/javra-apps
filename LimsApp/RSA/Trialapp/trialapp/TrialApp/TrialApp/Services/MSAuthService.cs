using System;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Identity.Client;
using Xamarin.Essentials;
using Xamarin.Forms;

namespace TrialApp.Services
{
    public class MSAuthService
    {
        readonly string[] Scopes = { "User.Read" };
        readonly IPublicClientApplication _pca;
        private readonly SimpleGraphService _simpleGraphService;
        private readonly int _tokenExpiryDuration = 60;
        const string authority = "https://login.microsoftonline.com/EZNLB.onmicrosoft.com";
        // Android uses this to determine which activity to use to show
        // the login screen dialog from.
        public static object ParentWindow { get; set; }

        public MSAuthService(string AppId, string ClientID, string redirecUri)
        {
            _simpleGraphService = new SimpleGraphService();

            switch (Device.RuntimePlatform)
            {
                case Device.Android:
                    _pca = PublicClientApplicationBuilder.Create(ClientID)
                        .WithBroker(true)
                        .WithAuthority(authority)
                        .WithRedirectUri(redirecUri)
                        .Build();
                    break;
                case Device.iOS:
                    _pca = PublicClientApplicationBuilder.Create(ClientID)
                        .WithIosKeychainSecurityGroup(AppId)
                        .WithRedirectUri(redirecUri)
                        //.WithBroker(true)
                        .WithIosKeychainSecurityGroup("com.microsoft.adalcache")
                        .WithAuthority(authority)
                        .Build();
                    break;

                case Device.UWP:
                    _pca = PublicClientApplicationBuilder.Create(ClientID)
                        // .WithRedirectUri("https://login.microsoftonline.com/common/oauth2/nativeclient")      
                        .WithRedirectUri(redirecUri)
                        .WithWindowsBrokerOptions(new WindowsBrokerOptions()
                        {
                            // GetAccounts will return Work and School accounts from Windows
                            ListWindowsWorkAndSchoolAccounts = true,

                            // Legacy support for 1st party apps only
                            MsaPassthrough = true
                        })
                        .WithBroker(true)
                        .WithAuthority(authority)
                        .WithExperimentalFeatures()
                        .Build();
                    break;
            }
        }




        public async Task<bool> SignInAsync()
        {
            //var token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6ImpTMVhvMU9XRGpfNTJ2YndHTmd2UU8yVnpNYyIsImtpZCI6ImpTMVhvMU9XRGpfNTJ2YndHTmd2UU8yVnpNYyJ9.eyJhdWQiOiJlNTI3NDcxNi1mYTgwLTRiMDEtOTU2OC0wYjZmYzZhOWRhYWIiLCJpc3MiOiJodHRwczovL3N0cy53aW5kb3dzLm5ldC9lMGIxMDI3MC0yNDBiLTRlZGEtYWZmYi01MGZiMmI1OTIwZGUvIiwiaWF0IjoxNjQ4MTgyNTczLCJuYmYiOjE2NDgxODI1NzMsImV4cCI6MTY0ODE4NjQ3MywiYWlvIjoiQVNRQTIvOFRBQUFBOXkyZ2xMR0FOdXMxcWJuOVMrQm8wc2lnQzc2NTR3bmx0STNsWStZNTMxZz0iLCJhbXIiOlsicHdkIl0sImZhbWlseV9uYW1lIjoiQmFudHdhIiwiZ2l2ZW5fbmFtZSI6IlByYWthc2giLCJpcGFkZHIiOiI3Ny42MS4yNDAuMTk0IiwibmFtZSI6IlByYWthc2ggQmFudHdhIiwibm9uY2UiOiJhOWJiYTIxNy1lMGQ0LTQ4ZjctYmNmNy1jZmQzZDZiYzFiODMiLCJvaWQiOiI1NTQ0NzE1ZC0xOWViLTQzZjctYTQxZS04ZDMxNTQwZDhlNTciLCJvbnByZW1fc2lkIjoiUy0xLTUtMjEtMjk1NTQ2MjI1NC0zODQ3MzQwNTI2LTMwMDkzNDE5NTEtMjc4MyIsInJoIjoiMC5BUXNBY0FLeDRBc2syazZ2LTFEN0sxa2czaFpISi1XQS1nRkxsV2dMYjhhcDJxc0xBRzQuIiwicm9sZXMiOlsibWFuYWdlbWFzdGVyZGF0YXRyaWFscHJlcCIsInNhdmVvYnNlcnZhdGlvbnMiLCJBR19ST0xFX0Nyb3BUTyIsIkFHX1JPTEVfQ3JvcEVEIiwiZGlzcGxheXRyYWl0cyIsImFzc2lnbmxvdG51bWJlciIsIm1hbmFnZWdsb2JhbHRyYWl0cyIsImV4Y2x1ZGV2YXJpZXRpZXMiLCJkZWZpbmV0cmlhbCIsImFzc2lnbnVzZXJzIiwiQUdfUk9MRV9Dcm9wQUxMIl0sInN1YiI6Imo2VEFINlZXaVhoN1BiYzlzTnBZWnFxTXU0RFFDdGxsV05sZE1ncTRkNGsiLCJ0aWQiOiJlMGIxMDI3MC0yNDBiLTRlZGEtYWZmYi01MGZiMmI1OTIwZGUiLCJ1bmlxdWVfbmFtZSI6IlAuQmFudHdhQGVuemF6YWRlbi5ubCIsInVwbiI6IlAuQmFudHdhQGVuemF6YWRlbi5ubCIsInV0aSI6InQ1c3ZOSTBXOWsyMmFnamhSVzkzQUEiLCJ2ZXIiOiIxLjAifQ.m_1fnqzJCe0sAZBS7fA3viKEIB4qlKqR6KlvLtbjlmv0KS2egyVPHGyIXGeOHCxBcuKFVPTB5pTRAS3ktK3_R1n1IQ0lGMRzIzD-lBHktXOzmPD-z12ZOW0_7E4XC0-dbjCUNAY5GMQQftzZUzLrckI6HWXIviaSvG2y6uYR0HchXOFMJkLT1o0BEevabQsBJBoIFFtHXaiF_tmzUzTPKcpSafJnia4zglYeRWBP57uC7BiDEVQGMfW-sLCrvbLmYmL6ec6PS7A0Ax5a6jKF9QCLoAyW-uf349ovUgAY8Ls6ciuLoLrGCY4s77-FBaYydI7O4G-Kb4W0sth1VTGH-Q";
            //WebserviceTasks.AdToken = token;
            //WebserviceTasks.AdAccessToken = token;

            //WebserviceTasks.UsernameWS = "Binod_Gurung";

            //return true;


            try
            {

                var accounts = await _pca.GetAccountsAsync();
                var firstAccount = accounts.FirstOrDefault();
                AuthenticationResult authResult;

                if (WebserviceTasks.TokenExpiryDate < DateTime.Now)
                {
                    authResult =  await GetSilentTokenAsync(firstAccount, true);
                    WebserviceTasks.TokenExpiryDate = DateTime.Now.AddMinutes(_tokenExpiryDuration);
                }
                else
                {
                    authResult = await GetSilentTokenAsync(firstAccount, false);
                    if (authResult.ExpiresOn.UtcDateTime.AddMinutes(-5) < DateTime.UtcNow)
                    {
                        authResult = await GetSilentTokenAsync(firstAccount, true);
                        WebserviceTasks.TokenExpiryDate = DateTime.Now.AddMinutes(_tokenExpiryDuration);
                    }
                }

                
                // Store the access token securely for later use.
                WebserviceTasks.AdToken = authResult?.IdToken;
                WebserviceTasks.AdAccessToken = authResult?.AccessToken;
                
                var Name = await _simpleGraphService.GetNameAsync();
                WebserviceTasks.UsernameWS = Name;
                return true;
            }
            catch (Exception)
            {
                try
                {
                    // This means we need to login again through the MSAL window.
                    await TokenFlow();
                    return true;
                }
                catch (Exception ex2)
                {
                    throw ex2;
                }
            }
        }


       
        public async Task<bool> SignOutAsync()
        {
            try
            {
                var accounts = await _pca.GetAccountsAsync();

                // Go through all accounts and remove them.
                while (accounts.Any())
                {
                    await _pca.RemoveAsync(accounts.FirstOrDefault());
                    accounts = await _pca.GetAccountsAsync();
                }

                // Clear our access token from secure storage.
                SecureStorage.Remove("AccessToken");
                WebserviceTasks.AdToken = "";
                return true;
            }
            catch (Exception ex)
            {
                Debug.WriteLine(ex.ToString());
                return false;
            }
        }

        private async Task TokenFlow()
        {
            AuthenticationResult authResult = null;
            switch (Device.RuntimePlatform)
            {
                case Device.Android:
                    authResult = await _pca.AcquireTokenInteractive(Scopes)
                                       .WithParentActivityOrWindow(ParentWindow)
                                       .WithUseEmbeddedWebView(false)
                                        .ExecuteAsync();
                    break;
                case Device.iOS:
                    authResult = await _pca.AcquireTokenInteractive(Scopes)
                                       .WithParentActivityOrWindow(ParentWindow)
                                       .ExecuteAsync();
                    break;

                case Device.UWP:
                    authResult = await _pca.AcquireTokenInteractive(Scopes)
                                       .WithAccount(null)
                                       .ExecuteAsync();
                    break;
            }
            WebserviceTasks.AdToken = authResult?.IdToken;
            WebserviceTasks.AdAccessToken = authResult?.AccessToken;
            WebserviceTasks.TokenExpiryDate = DateTime.Now.AddMinutes(_tokenExpiryDuration);

            var Name = await _simpleGraphService.GetNameAsync();
            WebserviceTasks.UsernameWS = Name;

        }
        private async Task<AuthenticationResult> GetSilentTokenAsync(IAccount account, bool forceRefresh)
        {
           return await _pca.AcquireTokenSilent(Scopes, account)
                    .WithForceRefresh(forceRefresh)
                    .ExecuteAsync();
        }
    }
}
