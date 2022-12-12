using System.Configuration;
using System.Linq;
using System.Threading;
using AventStack.ExtentReports;
using Enza.PtoV.UITesting.Extensions;
using Enza.PtoV.UITesting.Models;
using Enza.PtoV.UITesting.Tests;
using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;

namespace Enza.PtoV.UITesting.BusinessLogics
{
    public class ImportFromVarmas
    {
        private readonly IWebDriver _webDriver;
        private readonly ExtentTest _testReport;
        private readonly WebDriverWait _wait;
        private readonly AppSettings _appSettings;
        public ImportFromVarmas(IWebDriver webDriver, ExtentTest testReport, WebDriverWait wait, AppSettings appSettings)
        {
            _webDriver = webDriver;
            _testReport = testReport;
            _wait = wait;
            _appSettings = appSettings;
        }

        public void ClickImportButton()
        {
            _wait.WaitLoader();

            _testReport.Log(Status.Info, "Import button is being clicked...");
            var importBtn = _wait.WaitUntilElementIsVisible(By.Id("main_import_btn"));
            importBtn.Click();
            _testReport.Log(Status.Info, "Import button has been successfully clicked");
        }

        public void LoginWithoutSSO(string username, string password)
        {
            _testReport.Log(Status.Info, "SSO is false");

            var loginInput = _wait.WaitUntilElementIsVisible(By.Name("username"));
            loginInput.Clear();
            loginInput.SendKeys(username);

            var passwordInput = _wait.WaitUntilElementIsVisible(By.Name("password"));
            passwordInput.Clear();
            passwordInput.SendKeys(password);

            var loginButton = _wait.WaitUntilElementIsClickable(By.XPath("//button[@type='submit']"));
            loginButton.Click();

            _wait.WaitLoader();

            //check if error
            bool error = _webDriver.IsElementPresent(By.ClassName("formErrorP"));
            if (error)
            {
                var errorMessage = _wait.WaitUntilElementIsVisible(By.ClassName("formErrorP"));
                Assert.Fail($"Error while logging in {errorMessage.Text}");
            }
        }

        public void LoginToAzureAD(string currentWindowHandle)
        {
            _testReport.Log(Status.Info, "Login to Azure AD process is starting...");

            string popupHandle = _webDriver.WindowHandles
                .Where(x => x != currentWindowHandle)
                .Select(x => x).FirstOrDefault();
            
            _webDriver.SwitchTo().Window(popupHandle);

            //to be handled, wait for page to complete
            Thread.Sleep(2000);

            var emailAddress =
                _wait.Until(SeleniumExtras.WaitHelpers.ExpectedConditions.ElementIsVisible(By.Id("i0116")));

            emailAddress.SendKeys(_appSettings.UserName);
            _testReport.Log(Status.Info, "Setting username of enza");

            var nextBtn = _wait.WaitUntilElementIsVisible(By.Id("idSIButton9"));
            nextBtn.Click();

            var password = _wait.WaitUntilElementIsVisible(By.Id("i0118"));

            password.SendKeys(_appSettings.Password);
            _testReport.Log(Status.Info, "Setting pasword of enza");

            var signInBtn = _wait.WaitUntilElementIsVisible(By.Id("idSIButton9"));
            signInBtn.Click();
            _testReport.Log(Status.Info, "Clicking sign in button");

            var doNotRemember = _wait.WaitUntilElementIsVisible(By.Id("idBtn_Back"));

            doNotRemember.Click();
            _testReport.Log(Status.Info, "Clicking do not remember option");

            _webDriver.SwitchTo().Window(currentWindowHandle);

            _wait.WaitLoader();
        }

        public void ImportFromList()
        {
            string selector = "#root > div > div > div > div > div.wrapper > div > div.formBody > div > ul > li";

            var element = _wait.WaitUntilElementIsVisible(By.CssSelector(selector));

            element.Click();


            var folderList = _appSettings.FolderList;

            string scripts = typeof(PtoVTest).Assembly.GetResourceFromAssembly("Enza.PtoV.UITesting.Scripts.scripts.js");

            foreach (var folder in folderList)
            {
                _testReport.Log(Status.Info, $"Selecting {folder} folder.");

                if (!folder.EqualsIgnoreCase("To Varmas"))
                    element = _webDriver.GetElementByScript(scripts, element, folder, 1);
                else
                    element = _webDriver.GetElementByScript(scripts, element, folder, 2);
                element.Click();
                _wait.WaitLoader();
            }

            var importBtn = _wait.WaitUntilElementIsVisible(By.Id("form_import_btn"));
            importBtn.Click();
            _testReport.Log(Status.Info, "Import button has been clicked");
            _wait.WaitLoader();
            _testReport.Log(Status.Info, "Loading completed");
        }
    }
}
