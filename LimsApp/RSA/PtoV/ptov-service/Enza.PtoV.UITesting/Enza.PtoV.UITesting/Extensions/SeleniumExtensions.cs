using System;
using System.IO;
using System.Reflection;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;

namespace Enza.PtoV.UITesting.Extensions
{
    public static class SeleniumExtensions
    {
        public static object ExecuteScript(this IWebDriver webDriver, string script, params object[] args)
        {
            IJavaScriptExecutor js = (IJavaScriptExecutor)webDriver;
            return js.ExecuteScript(script, args);
        }


        public static IWebElement GetElementByScript(this IWebDriver webDriver, string script, params object[] args)
        {
            return (IWebElement)webDriver.ExecuteScript(script, args);
        }

        public static string GetResourceFromAssembly(this Assembly assembly, string resourceName)
        {
            using (var stream = assembly.GetManifestResourceStream(resourceName))
            {
                using (var reader = new StreamReader(stream))
                {
                    return reader.ReadToEnd();
                }
            }
        }

        public static bool EqualsIgnoreCase(this string a, string b)
        {
            return string.Compare(a, b, StringComparison.OrdinalIgnoreCase) == 0;
        }

        public static IWebElement WaitUntilElementIsClickable(this WebDriverWait wait, By elementLocator)
        {
            return wait.Until(SeleniumExtras.WaitHelpers.ExpectedConditions.ElementToBeClickable(elementLocator));
        }

        public static IWebElement WaitUntilElementIsVisible(this WebDriverWait wait, By elementLocator)
        {
            return wait.Until(SeleniumExtras.WaitHelpers.ExpectedConditions.ElementIsVisible(elementLocator));
        }

        public static void WaitLoader(this WebDriverWait wait)
        {
            wait.Until(SeleniumExtras.WaitHelpers.ExpectedConditions
                .InvisibilityOfElementLocated(By.ClassName("loaderWrapper")));
        }

        public static bool IsElementPresent(this IWebDriver webDriver, By by)
        {
            try
            {
                webDriver.FindElement(by);
                return true;
            }
            catch (NoSuchElementException)
            {
                return false;
            }
        }
    }
}
