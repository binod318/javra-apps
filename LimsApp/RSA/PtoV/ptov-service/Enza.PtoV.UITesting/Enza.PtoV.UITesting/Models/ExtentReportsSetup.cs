using System;
using System.IO;
using AventStack.ExtentReports;
using AventStack.ExtentReports.Reporter;
using Enza.PtoV.UITesting.Extensions;
using Newtonsoft.Json;
using NUnit.Framework;
using NUnit.Framework.Interfaces;
using OpenQA.Selenium.Chrome;
using OpenQA.Selenium.Support.Extensions;
using OpenQA.Selenium.Support.UI;

namespace Enza.PtoV.UITesting.Models
{
    public class ExtentReportsSetup
    {
        protected static ChromeDriver WebDriver;
        protected static WebDriverWait Wait;
        protected ExtentReports ExtentReports;
        protected ExtentTest TestReport;
        protected AppSettings Settings;
        private static CertificateErrorPage.LogonSetting DesiredLogonSetting = CertificateErrorPage.LogonSetting.AutomaticallyLogonWithCurrentUsernameAndPassword;
        private static CertificateErrorPage.LogonSetting originalLogonSetting;


        [OneTimeSetUp]
        public void Initialize()
        {
            //Instantiate JsonConfiguration
            var json = File.ReadAllText(GlobalValues.GetJsonConfigurationFile);
            Settings = JsonConvert.DeserializeObject<AppSettings>(json);

            if (!Directory.Exists(GlobalValues.AppReportDirectory))
            {
                Directory.CreateDirectory(GlobalValues.AppReportDirectory);
            }
            if (!Directory.Exists(GlobalValues.AppScreenshotsDirectory))
            {
                Directory.CreateDirectory(GlobalValues.AppScreenshotsDirectory);
            }

            ChromeOptions chromeOptions = ChromeExtensions.GetChromeOptions();
            string tempReportDirectory = GlobalValues.AppReportDirectory;
            var htmlReporter = new ExtentHtmlReporter(tempReportDirectory);
            ExtentReports = new ExtentReports();
            ExtentReports.AttachReporter(htmlReporter);

            //AuthHandler
            CertificateErrorPage.AddToTrustedSite(Settings.ApplicationURL);
            originalLogonSetting = CertificateErrorPage.GetLogonSettings();

            if (originalLogonSetting != DesiredLogonSetting)
            {
                CertificateErrorPage.SetLogonSettings(DesiredLogonSetting);
            }

            WebDriver = new ChromeDriver(chromeOptions);

            WebDriver.Manage().Timeouts().ImplicitWait = TimeSpan.FromSeconds(5);


            Wait = new WebDriverWait(WebDriver, TimeSpan.FromSeconds(30));

            WebDriver.Url = Settings.ApplicationURL;

        }

        [SetUp]
        public void BeforeStart()
        {
            TestReport = ExtentReports.CreateTest(TestContext.CurrentContext.Test.Name);
        }


        [TearDown]
        public void AfterEachTestComplete()
        {
            var status = TestContext.CurrentContext.Result.Outcome.Status;
            var stacktrace = string.IsNullOrEmpty(TestContext.CurrentContext.Result.StackTrace)
                ? ""
                : $"{TestContext.CurrentContext.Result.StackTrace}";

            var stackMessage = string.IsNullOrWhiteSpace(TestContext.CurrentContext.Result.Message)
                ? ""
                : $"{TestContext.CurrentContext.Result.Message}";
            Status logstatus;

            switch (status)
            {
                case TestStatus.Failed:
                    {
                        logstatus = Status.Fail;

                        //save screenshot
                        var screenshot = WebDriver.TakeScreenshot();
                        var imageAsBase64 = screenshot.AsBase64EncodedString;
                        TestReport.AddScreenCaptureFromBase64String(imageAsBase64, TestContext.CurrentContext.Test.MethodName);

                        break;
                    }
                case TestStatus.Inconclusive:
                    logstatus = Status.Warning;
                    break;
                case TestStatus.Skipped:
                    logstatus = Status.Skip;
                    break;
                default:
                    {
                        logstatus = Status.Pass;

                        //save screenshot
                        var screenshot = WebDriver.TakeScreenshot();
                        var imageAsBase64 = screenshot.AsBase64EncodedString;
                        TestReport.AddScreenCaptureFromBase64String(imageAsBase64, TestContext.CurrentContext.Test.MethodName);

                        break;
                        
                    }
            }

            TestReport.Log(logstatus, "Test ended with " + logstatus + stackMessage);
            ExtentReports.Flush();

        }
        [OneTimeTearDown]
        public void OnComplete()
        {
            ExtentReports.Flush();
            WebDriver.Quit();
        }
    }
}
