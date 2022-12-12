using Enza.UTM.Common.Extensions;
using Enza.UTM.Entities.Args;
using Enza.UTM.Entities.Results;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Net;
using System.Security.Cryptography;
using System.Text;
using System.Web;

namespace Enza.UTM.Services.Proxies
{
    public class LimsServiceRestClient
    {
        public string AccessKey { get; set; }
        public string SecretKey { get; set; }
        public string Url { get; set; }

        public LimsServiceRestClient()
        {
            AccessKey = ConfigurationManager.AppSettings["AccessKey"];
            SecretKey = ConfigurationManager.AppSettings["SecretKey"];
            Url = ConfigurationManager.AppSettings["RestLimsServiceUrl"];
        }

        public RequestSampleTestResult RequestSampleTestAsync(RequestSampleTestRequest request)
        {                        
            var api = Url + "/v1/utm/request";
            var resp = ExecutePostService(request, api);

            //extract response
            var response = ExtractResponseBody(resp);

            //convert response to json to check for success or failure
            var jsonResp = JsonConvert.DeserializeObject<RequestSampleTestResult>(response);

            return new RequestSampleTestResult
            {
                Success = jsonResp.Success,
                ErrorMsg = jsonResp.ErrorMsg
            };
            
        }

        public LDRequestSampleTestResult RequestSampleTestLDAsync(LDRequestSampleTestRequest request)
        {
            var api = Url + "/v1/utmtracktrace/request";
            var resp = ExecutePostService(request, api);

            //extract response
            var response = ExtractResponseBody(resp);

            //convert response to json to check for success or failure
            var jsonResp = JsonConvert.DeserializeObject<LDRequestSampleTestResult>(response);

            return new LDRequestSampleTestResult
            {
                Success = jsonResp.Success,
                ErrorMsg = jsonResp.ErrorMsg
            };
        }

        private WebResponse ExecutePostService(object requestData, string url)
        {
            JsonSerializerSettings jsonSettings = new JsonSerializerSettings();
            jsonSettings.DateFormatString = "yyyy-MM-ddTHH:mm:ss.fffZ";

            var json = JsonConvert.SerializeObject(requestData, jsonSettings);

            HttpWebRequest req = WebRequest.CreateHttp(url);
            req.Timeout = 1000 * 60 * 10; // 10 min
            req.ReadWriteTimeout = 1000 * 60 * 10;
            req.Method = "POST";

            // write payload         
            byte[] data = Encoding.UTF8.GetBytes(json);
            req.GetRequestStream().Write(data, 0, data.Length);

            req.Headers.Add("SL-API-Timestamp", DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ss.fffZ"));
            req.Headers.Add("SL-API-Auth", AccessKey);
            req.Headers.Add("SL-API-Signature", ComputeSignature(req, json));

            req.ContentType = "application/json";
            
            return req.GetResponse();            
        }

        // used with string payloads, such as JSON     
        private string ComputeSignature(HttpWebRequest req, string payload)
        {
            string data = String.Format("{0}\n{1}\n{2}\n{3}\n{4}\n{5}",
            req.RequestUri.AbsoluteUri,
            req.Method,
            req.Headers["SL-API-Auth"],
            req.Headers["SL-API-Method"] ?? "",
            req.Headers["SL-API-Timestamp"],
            payload);

            byte[] dataBytes = Encoding.UTF8.GetBytes(data);
            return ComputeHash(dataBytes);
        }


        private string ExtractResponseBody(WebResponse resp)
        {
            using (StreamReader reader = new StreamReader(resp.GetResponseStream()))
            {
                return reader.ReadToEnd();
            }
        }

        private string ComputeHash(byte[] dataBytes)
        {
            byte[] keyBytes = Encoding.UTF8.GetBytes(SecretKey);

            HMACSHA256 crypto = new HMACSHA256(keyBytes);
            byte[] hashBytes = crypto.ComputeHash(dataBytes);

            string hash = Convert.ToBase64String(hashBytes);
            string encodedHash = HttpUtility.UrlEncode(hash);

            return encodedHash;
        }

        public RequestSampleTestResult UpdatesampletestinfoAsync(Updatesampletestinfo request)
        {           

            
            var api = Url + "/v1/utm/updatesampletestinfo";
            var resp = ExecutePostService(request, api);

            // Get the stream associated with the response.
            Stream receiveStream = resp.GetResponseStream();

            StreamReader readStream = new StreamReader(receiveStream, Encoding.UTF8);
            var response = readStream.ReadToEnd();

            //convert response to json to check for success or failure
            var jsonResp = JsonConvert.DeserializeObject<RequestSampleTestResult>(response);

            return new RequestSampleTestResult
            {
                Success = jsonResp.Success,
                ErrorMsg = jsonResp.ErrorMsg
            };

        }
    }

}
