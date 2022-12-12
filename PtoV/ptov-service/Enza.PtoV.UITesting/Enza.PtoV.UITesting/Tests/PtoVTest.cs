using Enza.PtoV.UITesting.BusinessLogics;
using Enza.PtoV.UITesting.Extensions;
using Enza.PtoV.UITesting.Models;
using NUnit.Framework;
using System.Collections.Generic;

namespace Enza.PtoV.UITesting.Tests
{
    [TestFixture]
    public class PtoVTest : ExtentReportsSetup
    {

        [Test, Order(1)]
        public void LoadApplication()
        {
            var loadApplication = new LoadApplication(WebDriver, TestReport, Settings);
            loadApplication.Load();
        }


        [Test, Order(2)]
        public void ImportFromVarmas()
        {
            string currentWindowHandle = WebDriver.CurrentWindowHandle;

            var importFromVarmas = new ImportFromVarmas(WebDriver, TestReport, Wait, Settings);
            importFromVarmas.ClickImportButton();

            var ssoDetails = (Dictionary<string, object>)WebDriver.ExecuteScript("return sso;");
            var ssoEnabled = false;
            if (ssoDetails.TryGetValue("enabled", out object enabled))
            {
                if (enabled != null)
                    bool.TryParse(enabled.ToString(), out ssoEnabled);
            }
            if (!ssoEnabled)
            {
                importFromVarmas.LoginWithoutSSO(Settings.UserName , Settings.Password);
            }
            else
            {
                importFromVarmas.LoginToAzureAD(currentWindowHandle);
            }
            importFromVarmas.ImportFromList();
        }

        [Test, Order(3)]
        public void SendRowToVarmas()
        {
            var sendRowToVarmas = new SendRowToVarmas(WebDriver, TestReport, Wait, Settings);

            if (sendRowToVarmas.VerifyIfRowExists())
            {

                sendRowToVarmas.SelectNewCrop();
                sendRowToVarmas.SelectProductSegment();
                sendRowToVarmas.SelectCountryOfOrigin();
                sendRowToVarmas.SelectRow();
                sendRowToVarmas.ClickSaveButton();
                sendRowToVarmas.ClickSendToVarmas();
                sendRowToVarmas.VerifyIfSentToVarmas();
            }
            else
            {
                Assert.Fail("There doesn't exist any rows in a table");
            }
            Wait.WaitLoader();
        }
    }
}
