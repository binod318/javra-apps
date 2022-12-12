using System;
using System.Collections.Generic;
using Xamarin.Essentials;

namespace TrialApp.Droid
{
    public static class AppConstants
    {
        public static string NotificationChannelName { get; set; } = "XamarinNotifyChannel";

        public const string ListenConnectionString = "$(ConnectionStringVar)";
        public const string NotificationHubName = "$(NotificationHubNameVar)";
        public const string IsAADLogin = "$(IsAADLogin)";
        public const string Appname = "$(AppName)";
        public const string ClientID = "$(AADAppID)";
        public const string SignatureHash = "$(SignatureHash)";
        public const string ServiceAccName = "$(ServiceAccountNameMasterdata)";
        public const string ServiceAccPswrd = "$(ServiceAccountPasswordMasterdata)";

        //Development
        //public const string ListenConnectionString = "Endpoint=sb://trialapp.servicebus.windows.net/;SharedAccessKeyName=DefaultFullSharedAccessSignature;SharedAccessKey=OOsYEjzAeGwrOHJ85RNajIrZyCj3tQd/fLnpBruEa7U=";//"$(ConnectionStringVar)";
        //public const string NotificationHubName = "ANH-WE-ENZA-Business-Trailapp-T-02";
        //public const string IsAADLogin = "True";
        //public const string Appname = "com.TrialApp.Test";
        //public const string ClientID = "e5274716-fa80-4b01-9568-0b6fc6a9daab";
        //public const string SignatureHash = "DoocnyaI0XUJR/gGhncmIvDeGw4=";
        //public const string ServiceAccName = "shubasp";
        //public const string ServiceAccPswrd = "Welcome01!";

        public static string DebugTag { get; set; } = "TrialappDebug";
        public static List<string> SubscriptionTags { get; set; } = new List<string> { "fcm", Guid.NewGuid().ToString() };
        public static string FCMTemplateBody { get; set; } = "{\"data\":{\"message\":\"$(messageParam)\"}}";
        public static string APNTemplateBody { get; set; } = "{\"aps\":{\"alert\":\"$(messageParam)\"}}";
        public static string ApplicationID { get; set; } = "1:589892520196:android:43af2e9e2e6f758c7a6851";
        public static string ApiKey { get; set; } = "AIzaSyDiaBIWNRBoJygSX2_fKMzK3fBjUCCguTk";

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