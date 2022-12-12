using Foundation;
using System;
using System.Collections.Generic;
using System.Linq;
using TrialApp.iOS.Helper;
using TrialApp.ViewModels.Interfaces;
using UIKit;
using WindowsAzure.Messaging;
using Xamarin.Forms;

[assembly: Dependency(typeof(NotificationHelper))]
namespace TrialApp.iOS.Helper
{
    public class NotificationHelper : INotificationHelper

    {

        public void UpdateToken(string userName)

        {
            try
            {
                var Hub = new SBNotificationHub(AppConstants.ListenConnectionString, AppConstants.NotificationHubName);


                Hub.UnregisterAll(AppDelegate.notificationRefreshTokenIos, async (error) =>
                {
                    if (error != null)
                    {
                        System.Diagnostics.Debug.WriteLine("Error calling Unregister: {0}", error.ToString());
                        return;
                    }
                    var tag = new List<string> { "apns", Guid.NewGuid().ToString() };
                    tag.Add(userName.Replace(" ", "_"));

                    NSSet tags = new NSSet(tag.ToArray());

                    Hub.RegisterNative(AppDelegate.notificationRefreshTokenIos, tags, (errorCallback) =>
                    {
                        if (errorCallback != null)
                            System.Diagnostics.Debug.WriteLine("RegisterNativeAsync error: " + errorCallback.ToString());

                    });
                });

            }
            catch (System.Exception ex)
            {

                UIAlertController.Create("Error", ex.Message + "Stack:" + ex.StackTrace, UIAlertControllerStyle.Alert);
            }
        }

    }
}