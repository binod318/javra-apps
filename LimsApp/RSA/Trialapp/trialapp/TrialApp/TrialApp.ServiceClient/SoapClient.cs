using System;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Linq;
using System.Xml.Serialization;

namespace TrialApp.ServiceClient
{
    public class SoapClient
    {
        public string EndPointAddress { get; set; }
        private string envelope = null;
        public string Credentail { get; set; }

        public async Task<T1> GetResponse<T, T1>(T obj, string adToken)
        {
            Serialize(obj, adToken);
            if (string.IsNullOrWhiteSpace(envelope))
            {
                throw new ArgumentNullException("envelope");
            }
            using (var httpClient = new HttpClient())
            {
                try
                {
                    httpClient.DefaultRequestHeaders.Add("SOAPAction", ServiceConstant.ServiceAction[obj.GetType().Name]);
                    var byteArray = Encoding.UTF8.GetBytes(Credentail);
                    httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic",
                        Convert.ToBase64String(byteArray));

                    var req = new HttpRequestMessage(HttpMethod.Post, EndPointAddress ?? "https://bpmtst.enzazaden.com/cordys/com.eibus.web.soap.Gateway.wcp?");
                    req.Content = new StringContent(envelope);
                    var response = await httpClient.SendAsync(req, HttpCompletionOption.ResponseHeadersRead);
                    
                    //if (response.IsSuccessStatusCode)
                    if (response.StatusCode == System.Net.HttpStatusCode.OK)
                    {
                        var cont = await response.Content.ReadAsStreamAsync();
                        using (var reader = new StreamReader(cont))
                        {
                            var content = await reader.ReadToEndAsync();
                            content = NamespaceHelper.RemoveAllNamespaces(content);
                            var xdoc = XDocument.Parse(content).Descendants("Body").Elements().FirstOrDefault();
                            var t1Obj = XmlHelper.ParseXml<T1>(xdoc.ToString());
                            return t1Obj;
                        }
                    }
                    else
                    {
                        throw new Exception(response.ReasonPhrase);
                    }
                }
                catch (Exception ex)
                {
                    throw new Exception(ex.Message);
                }
               
            }
        }


        private void Serialize<T>(T obj, string token)
        {
            XmlSerializer serializer = new XmlSerializer(typeof(T));
            var writer = new StringWriter();
            var namespace1 = ServiceConstant.NamespaceDict[obj.GetType().Name];
            XNamespace ns = namespace1;
            XmlSerializerNamespaces namespaces = new XmlSerializerNamespaces();
            namespaces.Add("ns", namespace1);

            serializer.Serialize(writer, obj, namespaces);
            XElement content = XElement.Parse(writer.ToString());

            content.Name = ns + content.Name.LocalName;

            if (string.IsNullOrEmpty(token))
                envelope =
                    String.Format(
                        @"<soapenv:Envelope xmlns:soapenv=""http://schemas.xmlsoap.org/soap/envelope/"" ><soapenv:Header/><soapenv:Body> {0} </soapenv:Body> </soapenv:Envelope>",
                        content.ToString());
            else
                envelope =
                String.Format(
                        @"<soapenv:Envelope xmlns:soapenv=""http://schemas.xmlsoap.org/soap/envelope/"" ><soapenv:Header><AADToken>" + token + "</AADToken></soapenv:Header><soapenv:Body> {0} </soapenv:Body> </soapenv:Envelope>",
                        content.ToString());
        }
    }

    public class XmlHelper
    {
        public static T ParseXml<T>(string xmlDocumentText)
        {
            XmlSerializer serializer = new XmlSerializer(typeof(T));
            StringReader reader = new StringReader(xmlDocumentText);
            T classObj = (T)(serializer.Deserialize(reader));
            return classObj;
        }
    }
}
