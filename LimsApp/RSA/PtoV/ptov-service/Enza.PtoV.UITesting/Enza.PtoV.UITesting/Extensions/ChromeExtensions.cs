using System;
using OpenQA.Selenium.Chrome;

namespace Enza.PtoV.UITesting.Extensions
{
    public static class ChromeExtensions
    {
        public static ChromeOptions GetChromeOptions()
        {
            var chromeOptions= new ChromeOptions { AcceptInsecureCertificates = true };
            chromeOptions.AddArgument("headless");
            chromeOptions.AddArgument("no-sandbox");
            chromeOptions.AddArgument("--disable-gpu");
            chromeOptions.AddArgument("--start-maximized");
            chromeOptions.AddArgument("--disable-extensions");
            chromeOptions.AddArgument("--disable-notifications");
            chromeOptions.AddArgument("--ignore-certificate-errors");
            chromeOptions.AddArgument("--disable-popup-blocking");            
            return chromeOptions;
        }

        public static void ThrottleNetwork(this ChromeDriver webDriver)
        {
            webDriver.NetworkConditions= new ChromeNetworkConditions()
            {
                Latency = TimeSpan.FromMilliseconds(500),
                DownloadThroughput = 5 * 1024 * 1024 * 8,
                UploadThroughput = 5 * 1024 * 1024 * 8
            };
        }
    }
}
