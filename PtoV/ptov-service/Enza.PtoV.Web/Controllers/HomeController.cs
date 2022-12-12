using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Net.Http;
using System.Security.Claims;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;
using Enza.Shared.Authentication;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Enza.PtoV.Web.Controllers
{
    public class HomeController : Controller
    {
        public ActionResult Index()
        {
            var services = new Dictionary<string, string>
            {
                {"API_BASE_URL", ConfigurationManager.AppSettings["BaseServiceUrl"]},
                {"API_TOKEN_URL", ConfigurationManager.AppSettings["UserServiceURL"]},
                {"PHENOME_BASE_URL", ConfigurationManager.AppSettings["BasePhenomeServiceUrl"]}
            };
            ViewBag.Services = JsonConvert.SerializeObject(services);
            return View();
        }


        //sign in as different user in windows authentication
        [AllowAnonymous]
        public ActionResult Logout()
        {
            var cookie = Request.Cookies["TSWA-Last-User"];
            if (User.Identity.IsAuthenticated == false || cookie == null || StringComparer.OrdinalIgnoreCase.Equals(User.Identity.Name, cookie.Value))
            {
                var name = string.Empty;
                if (Request.IsAuthenticated)
                {
                    name = User.Identity.Name;
                }
                cookie = new HttpCookie("TSWA-Last-User", name);
                Response.Cookies.Set(cookie);

                Response.AppendHeader("Connection", "close");
                Response.StatusCode = 401; // Unauthorized;
                Response.Clear();
                //should probably do a redirect here to the unauthorized/failed login page
                //if you know how to do this, please tap it on the comments below
                Response.Write("Unauthorized. Reload the page to try again...");
                Response.End();
                return RedirectToAction("Index");
            }
            cookie = new HttpCookie("TSWA-Last-User", string.Empty)
            {
                Expires = DateTime.Now.AddYears(-5)
            };
            Response.Cookies.Set(cookie);
            return RedirectToAction("Index");
        }

        private async Task<List<string>> GetUserRolesAsync()
        {
            var url = ConfigurationManager.AppSettings["UserServiceURL"];
            var handler = new HttpClientHandler
            {
                //PreAuthenticate = true,
                UseDefaultCredentials = false,
                AllowAutoRedirect = true
                //Credentials = new NetworkCredential(@"dsuvedi", "dibya@j@vr@", "Kathmandu")
            };
            var client = new HttpClient(handler);
            var resp = await client.GetAsync(url);
            if (resp.IsSuccessStatusCode)
            {
                var json = await resp.Content.ReadAsStringAsync();
                var obj = (JObject) JsonConvert.DeserializeObject(json);
                var token = Convert.ToString(obj["token"]);
                if (!string.IsNullOrWhiteSpace(token))
                {
                    var provider = new AuthenticationService();
                    var user = provider.ReadAndVerifyToken(token);
                    return user.Claims.Where(c => c.Type == ClaimTypes.Role)
                        .Select(o => o.Value)
                        .ToList();
                }
            }
            return new List<string>();
        }
    }
}
