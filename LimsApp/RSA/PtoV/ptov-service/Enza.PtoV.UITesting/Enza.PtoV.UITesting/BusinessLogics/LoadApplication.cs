using AventStack.ExtentReports;
using Enza.PtoV.UITesting.Models;
using OpenQA.Selenium;

namespace Enza.PtoV.UITesting.BusinessLogics
{
    public class LoadApplication
    {
        private readonly IWebDriver _webDriver;
        private readonly ExtentTest _testReport;
        private readonly AppSettings _appSettings;

        public LoadApplication(IWebDriver webDriver, ExtentTest testReport, AppSettings appSettings)
        {
            _webDriver = webDriver;
            _testReport = testReport;
            _appSettings = appSettings;
        }

        public void Load()
        {
            _testReport.Log(Status.Info, "Applications is starting...");
            _webDriver.Url = _appSettings.ApplicationURL;
            _testReport.Log(Status.Info, "Applications loaded successfully");
        }
    }
}
