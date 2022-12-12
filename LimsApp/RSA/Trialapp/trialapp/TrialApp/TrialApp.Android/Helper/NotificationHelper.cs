using Plugin.CurrentActivity;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using TrialApp.Droid.Helper;
using TrialApp.ViewModels.Interfaces;
using WindowsAzure.Messaging;
using Xamarin.Essentials;
using Xamarin.Forms;

[assembly: Dependency(typeof(NotificationHelper))]
namespace TrialApp.Droid.Helper
{
    public class NotificationHelper : INotificationHelper

    {

        public async void UpdateToken(string userName)

        {
            var tags = new List<string> { "fcm", Guid.NewGuid().ToString() };
            tags.Add(userName.Replace(" ", "_"));
            NotificationHub hub = new NotificationHub(AppConstants.NotificationHubName, AppConstants.ListenConnectionString, CrossCurrentActivity.Current.Activity);

            //run on different thread, not on ui thread to prevent an exception
            try
            {
                await Task.Run(() => {

                    //First unregister from current tags
                    if (!string.IsNullOrEmpty(App.NotificationRefreshToken) || Preferences.ContainsKey("OldNotificationRefreshToken"))
                    {
                        if (Preferences.ContainsKey("OldNotificationRefreshToken"))
                            hub.UnregisterAll(Preferences.Get("OldNotificationRefreshToken", App.NotificationRefreshToken));

                        // register new tags with Azure Notification Hub using the token from FCM

                         hub.Register(string.IsNullOrEmpty(App.NotificationRefreshToken)? Preferences.Get("OldNotificationRefreshToken", App.NotificationRefreshToken) : App.NotificationRefreshToken, tags.ToArray());


                        Preferences.Set("OldNotificationRefreshToken", App.NotificationRefreshToken);
                    }
                    //else
                    //    Application.Current.MainPage.DisplayAlert("Info", "Refresh token not found.", "OK");

                });
            }
            catch (System.Exception ex)
            {

                await Application.Current.MainPage.DisplayAlert("Error", "Update registration failed with : " + ex.Message  + "tOKEN :  "+" Stack:" + ex.StackTrace , "OK");
            }
            

        }

    }
}