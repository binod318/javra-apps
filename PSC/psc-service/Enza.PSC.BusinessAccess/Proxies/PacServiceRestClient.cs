using Newtonsoft.Json;
using System.Configuration;
using System.IO;
using System.Net;
using System.Text;
using System.Threading.Tasks;

namespace Enza.PSC.BusinessAccess.Proxies
{
    public class PacServiceRestClient
    {
        public string Url { get; set; }

        public PacServiceRestClient()
        {
            Url = ConfigurationManager.AppSettings["PacServiceUrl"];
        }

        public async Task<string> PostData(string apiName, object req)
        {
            var url = string.Concat(Url, apiName); //Url + apiName;
            var request = (HttpWebRequest)WebRequest.Create(url);
            var json = JsonConvert.SerializeObject(req);
            var data = Encoding.ASCII.GetBytes(json);
            request.Method = "POST";
            request.ContentType = "application/json";
            request.ContentLength = data.Length;
            using (var stream = request.GetRequestStream())
            {
                stream.Write(data, 0, data.Length);
            }
            var response = (HttpWebResponse)await request.GetResponseAsync();
            var responseString = new StreamReader(response.GetResponseStream()).ReadToEnd();
            return responseString;
        }        
    }
}