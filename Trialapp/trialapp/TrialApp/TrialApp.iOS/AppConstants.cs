using System;
using System.Collections.Generic;
using Xamarin.Essentials;

namespace TrialApp.iOS
{
    public class AppConstants
    {
        // Azure app-specific connection string and hub path
        public const string ListenConnectionString = "$(ConnectionStringVar)";
        public const string NotificationHubName = "$(NotificationHubNameVar)";
        public static string APNTemplateBody { get; set; } = "{\"aps\":{\"alert\":\"$(messageParam)\"}}";
        public const string IsAADLogin = "$(IsAADLogin)";
        public const string AADAppID = "$(AADAppID)";
        public const string ClientID = "$(AADAppID)";
        public const string RedirectURI = "$(RedirectURIIOS)";
        public const string ServiceAccName = "$(ServiceAccountNameMasterdata)";
        public const string ServiceAccPswrd = "$(ServiceAccountPasswordMasterdata)";

        //Development
        //public const string ListenConnectionString = "Endpoint=sb://trialapp.servicebus.windows.net/;SharedAccessKeyName=DefaultFullSharedAccessSignature;SharedAccessKey=OOsYEjzAeGwrOHJ85RNajIrZyCj3tQd/fLnpBruEa7U=";//"$(ConnectionStringVar)";
        //public const string NotificationHubName = "ANH-WE-ENZA-Business-Trailapp-T-02";
        //public const string IsAADLogin = "True";
        //public const string AADAppID = "0b80c8bd-d69f-4b52-b4c7-2f969b246e5b";
        //public const string Appname = "com.TrialApp.Test";
        //public const string ClientID = "0b80c8bd-d69f-4b52-b4c7-2f969b246e5b";
        //public const string RedirectURI = "msauth.com.enzazaden.TrialAppTest://auth";
        //public const string SignatureHash = "VOZmx761wZLrMfIr%2FWNynVMl7Hc%3D";
        //public const string ServiceAccName = "shubasp";
        //public const string ServiceAccPswrd = "20shu%%20";

        public static List<string> SubscriptionTags { get; set; } = new List<string> { "apns", Guid.NewGuid().ToString() };

        //for javra
        //public const string ListenConnectionString = "Endpoint=sb://javranhubns.servicebus.windows.net/;SharedAccessKeyName=DefaultFullSharedAccessSignature;SharedAccessKey=h4C9ojtYuq3wPqy4rrBHCtsZp+7LtaaMnzj2fmkCnAk=";
        //public const string NotificationHubName = "trialAppNhub";

        public static async void SetSecureStorage()
        {
            try
            {
                await SecureStorage.SetAsync("BlobConnectionKey", "$(BlobConnectionKey)");
                //await SecureStorage.SetAsync("BlobConnectionKey", "DefaultEndpointsProtocol=https;AccountName=trivium3925378757;AccountKey=6dipOd5pdP28sSP5RNA1yAjvvhVNFWEE2WuqszzODUAmSl6WRs/iNE4mS7ynKZyKdHzT9rTCUQbwsNjKfP5AOQ==;EndpointSuffix=core.windows.net");
            }
            catch (Exception)
            {
                // Possible that device doesn't support secure storage on device.
            }
        }
    }
}