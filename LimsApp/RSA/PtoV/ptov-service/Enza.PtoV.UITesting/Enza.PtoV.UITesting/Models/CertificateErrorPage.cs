using System;
using Microsoft.Win32;

namespace Enza.PtoV.UITesting.Models
{
    public class CertificateErrorPage
    {
        private const int TrustedSiteZone = 0x2;
        private const string LogonSettingValueName = "1A00";
        private static RegistryKey _localIntranetZone;

        protected static RegistryKey LocalIntranetZone
        {
            get
            {
                if (_localIntranetZone == null)
                {
                    _localIntranetZone = Registry.CurrentUser.OpenSubKey(GlobalValues.LocalIntranetZoneKeyPath, true);
                }

                return _localIntranetZone;
            }
        }

        public enum LogonSetting
        {
            NotSet = -1,
            AutomaticallyLogonWithCurrentUsernameAndPassword = 0x00000,
            PromptForUserNameAndPassword = 0x10000,
            AutomaticLogonOnlyInTheIntranetZone = 0x20000,
            AnonymousLogon = 0x30000
        }

        public static void AddToTrustedSite(string url)
        {
            var baseURL = new Uri(url);
            RegistryKey rangeKey = GetRangeKey(baseURL.Authority, baseURL.Host);
            rangeKey.SetValue(baseURL.Scheme, TrustedSiteZone, RegistryValueKind.DWord);
            rangeKey.SetValue(":Range", baseURL.Authority, RegistryValueKind.String);
        }

        private static RegistryKey GetRangeKey(string ipAddress, string ipAddressWithoutPort)
        {
            RegistryKey currentUserKey = Registry.CurrentUser;

            for (int i = 1; i <= int.MaxValue - 1; i++)
            {
                RegistryKey rangeKey = currentUserKey.OpenSubKey((
                    !WindowsServerAuthentication.IsWindowsServer() ? GlobalValues.LocalIntranetZoneKeyPathForTrusted : GlobalValues.LocalIntranetZoneKeyPathForTrustedServer) + "\\Range"
                    + i.ToString(), true);
                if (rangeKey == null)
                    rangeKey = currentUserKey.CreateSubKey(
                        !WindowsServerAuthentication.IsWindowsServer() ? GlobalValues.LocalIntranetZoneKeyPathForTrusted : GlobalValues.LocalIntranetZoneKeyPathForTrustedServer + "\\Range" + i.ToString());
                object address = rangeKey.GetValue(":Range");
                if (address == null)
                {
                    return rangeKey;
                }
                else
                {
                    if (Convert.ToString(address) == ipAddress || Convert.ToString(address) == ipAddressWithoutPort)
                    {
                        return rangeKey;
                    }
                }

            }
            throw new Exception("No range slot can be used.");



        }


        /// <summary>
        /// Sets the IE Logon setting to the desired value.
        /// </summary>
        /// <param name="logonSetting">The desired value to assign to the Logon Setting.</param>
        public static void SetLogonSettings(LogonSetting logonSetting)
        {
            if (logonSetting == LogonSetting.NotSet)
            {
                LocalIntranetZone.DeleteValue(LogonSettingValueName);
            }
            else
            {
                LocalIntranetZone.SetValue(LogonSettingValueName, (int)logonSetting);
            }
        }


        /// <summary>
        /// Retrieves the current IE Logon setting.
        /// </summary>
        public static LogonSetting GetLogonSettings()
        {
            var test = Registry.CurrentUser;
            object logonSettingValue = LocalIntranetZone.GetValue(LogonSettingValueName);

            if (logonSettingValue == null)
            {
                return LogonSetting.NotSet;
            }

            return (LogonSetting)logonSettingValue;
        }
    }
}
