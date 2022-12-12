using System.Linq;
using AventStack.ExtentReports;
using Enza.PtoV.UITesting.Extensions;
using Enza.PtoV.UITesting.Models;
using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;

namespace Enza.PtoV.UITesting.BusinessLogics
{
    public class SendRowToVarmas
    {
        private readonly IWebDriver _webDriver;
        private readonly ExtentTest _testReport;
        private readonly WebDriverWait _wait;
        private readonly AppSettings _appSettings;

        public SendRowToVarmas(IWebDriver webDriver, ExtentTest testReport, WebDriverWait wait, AppSettings appSettings)
        {
            _webDriver = webDriver;
            _testReport = testReport;
            _wait = wait;
            _appSettings = appSettings;
        }

        public bool VerifyIfRowExists()
        {
            var rows = _webDriver.FindElements(By.ClassName("public_fixedDataTable_bodyRow"));
            return rows.Any();
        }
       
        public void SelectNewCrop()
        {
            int rowNumber = 1;
            int columnNumber = 1;

            string selector =
                "#root > div > div > div > div > div.pvttable > div.fixedDataTableLayout_main.public_fixedDataTable_main > div.fixedDataTableLayout_rowsContainer " +
                "> div:nth-child(3) " +
                $"> div:nth-child({rowNumber}) " +
                "> div " +
                "> div.fixedDataTableRowLayout_body " +
                "> div:nth-child(2) " +
                "> div " +
                $"> div:nth-child({columnNumber}) " +
                "> div > div > div > div";

            _wait.WaitUntilElementIsClickable(By.CssSelector(selector)).Click();

            var selectOptions =
                new SelectElement(_wait.WaitUntilElementIsClickable(By.CssSelector($"{selector} > select")));
            selectOptions.SelectByIndex(1);

            _testReport.Log(Status.Info, $"Selecting Crop option {selectOptions.SelectedOption.Text}");
        }

        public void SelectProductSegment()
        {
            int rowNumber = 1;
            int columnNumber = 2;

            string selector =
                "#root > div > div > div > div > div.pvttable > div.fixedDataTableLayout_main.public_fixedDataTable_main > div.fixedDataTableLayout_rowsContainer " +
                "> div:nth-child(3) " +
                $"> div:nth-child({rowNumber}) " +
                "> div " +
                "> div.fixedDataTableRowLayout_body " +
                "> div:nth-child(2) " +
                "> div " +
                $"> div:nth-child({columnNumber}) " +
                "> div > div > div > div";


            _wait.WaitUntilElementIsClickable(By.CssSelector(selector)).Click();

            var selectOptions =
                new SelectElement(_wait.WaitUntilElementIsClickable(By.CssSelector($"{selector} > select")));

            selectOptions.SelectByIndex(1);
            

            _testReport.Log(Status.Info, $"Selecting product segment {selectOptions.SelectedOption.Text}");
        }

        public void SelectCountryOfOrigin()
        {
            int rowNumber = 1;
            int columnNumber = 3;
            string selector = "#root > div > div > div > div > div.pvttable > div.fixedDataTableLayout_main.public_fixedDataTable_main > div.fixedDataTableLayout_rowsContainer " +
                              "> div:nth-child(3) " +
                              $"> div:nth-child({rowNumber}) " +
                              "> div " +
                              "> div.fixedDataTableRowLayout_body " +
                              "> div:nth-child(2) " +
                              "> div " +
                              $"> div:nth-child({columnNumber}) " +
                              "> div > div > div > div";

            
            _wait.WaitUntilElementIsClickable(By.CssSelector(selector)).Click();


            var selectOptions =
                new SelectElement(_wait.WaitUntilElementIsClickable(By.CssSelector($"{selector} > select")));


            selectOptions.SelectByIndex(1);

            _testReport.Log(Status.Info, $"Country of origin has been selected as {selectOptions.SelectedOption.Text}");
        }

        public void SelectRow()
        {
            int rowNumber = 1;
            string selector = "#root > div > div > div > div > div.pvttable > div.fixedDataTableLayout_main.public_fixedDataTable_main > div.fixedDataTableLayout_rowsContainer " +
                              "> div:nth-child(3) " +
                              $"> div:nth-child({rowNumber}) " +
                              "> div " +
                              "> div.fixedDataTableRowLayout_body " +
                              "> div:nth-child(1) " +
                              "> div > div > div > div > div > div";

            _wait.WaitUntilElementIsClickable(By.CssSelector(selector)).Click();
            _testReport.Log(Status.Info, "Selecting first row");
        }

        public void ClickSaveButton()
        {
            var saveBtn = _webDriver.FindElement(By.Id("main_save_btn"));
            if (saveBtn.Enabled)
            {
                _testReport.Log(Status.Info, "Save button is enabled");
                saveBtn.Click();
                _testReport.Log(Status.Info, "Save button has been clicked");
            }
            else
            {
                _testReport.Log(Status.Error, "Save button isn't enabled. There is nothing to save.");
            }
        }

        public void ClickSendToVarmas()
        {

            _testReport.Log(Status.Info, "Sending to Varmas");

            var sendBtn = _wait.WaitUntilElementIsClickable(By.Id("main_send_btn"));
            sendBtn.Click();

            var alert = _webDriver.SwitchTo().Alert();
            alert.Accept();

            _wait.WaitLoader();
            _testReport.Log(Status.Info, "Send to Varmas request completed");
        }

        public void VerifyIfSentToVarmas()
        {
            _testReport.Log(Status.Info, "Verifying if Sent to Varmas is successful");

            var element = _webDriver.FindElement(By.ClassName("nBody"));
            if (element.Displayed)
            {
                string alertType = element.GetAttribute("style");
                var errorIndicator = "border-color: rgb(253, 132, 132);";
                if (string.Compare(alertType, errorIndicator, true) == 0)
                {
                    //Assert.Fail(element.Text);
                    _testReport.Fail(element.Text);
                    
                }
                else
                {
                    _testReport.Log(Status.Info, "Sent to varmas is succesfully completed");
                    //Assert.Pass();
                }
            }
        }
    }
}
