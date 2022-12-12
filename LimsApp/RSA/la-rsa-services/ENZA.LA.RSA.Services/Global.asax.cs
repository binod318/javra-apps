using System;
using System.Net;
using System.Web;
using System.Web.Http;

namespace ENZA.LA.RSA.Services
{
    public class WebApiApplication : System.Web.HttpApplication
    {
        protected void Application_BeginRequest(object sender, EventArgs e)
        {
            var request = Request;
            var response = Response;
            if (request.HttpMethod == "OPTIONS")
            {
                var origin = request.Headers.Get("Origin");
                if (!string.IsNullOrWhiteSpace(origin))
                {
                    response.AddHeader("Access-Control-Allow-Headers", "enzauth, Origin, X-Requested-With, Content-Type, Accept");
                    response.StatusCode = (int)HttpStatusCode.OK;
                    (sender as HttpApplication).CompleteRequest();
                }
            }
        }
        protected void Application_Start()
        {
            log4net.Config.XmlConfigurator.Configure();
            GlobalConfiguration.Configure(WebApiConfig.Register);


            


        }
    }
}
