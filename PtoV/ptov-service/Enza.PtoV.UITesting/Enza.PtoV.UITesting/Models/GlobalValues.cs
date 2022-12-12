using System.Configuration;

namespace Enza.PtoV.UITesting.Models
{
    public static class GlobalValues
    {
        public const string LocalIntranetZoneKeyPath =
            @"Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2";

        public const string LocalIntranetZoneKeyPathForTrusted =
            @"Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges";

        public static string LocalIntranetZoneKeyPathForTrustedServer =
            @"Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscRanges";

        public static readonly string AppDirectory = System.AppContext.BaseDirectory;
        public static string AppReportDirectory = System.IO.Path.Combine(AppDirectory, @"Reports\");
        public static string AppScreenshotsDirectory = System.IO.Path.Combine(AppReportDirectory, @"Screenshots\");
        public static string GetJsonConfigurationFile = System.IO.Path.Combine(AppDirectory, "appSettings.json");
    }
}
