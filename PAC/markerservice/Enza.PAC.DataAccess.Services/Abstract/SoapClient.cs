using Enza.PAC.Common.Exceptions;
using System;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Linq;

namespace Enza.PAC.DataAccess.Services.Abstract
{
    public abstract class SoapClient : IDisposable
    {
        private bool disposed;

        private readonly HttpClient client;
        private readonly HttpClientHandler handler;

        protected SoapClient()
        {
            handler = new HttpClientHandler
            {
                PreAuthenticate = false,
                UseCookies = true,
                UseDefaultCredentials = false,
                CookieContainer = new CookieContainer(),
                AutomaticDecompression = DecompressionMethods.Deflate | DecompressionMethods.GZip
            };
            client = new HttpClient(handler);
            ServicePointManager.ServerCertificateValidationCallback = (sender, certificate, chain, errors) =>
            {
                return true;
            };
        }

        public string Url { get; set; }
        public int StatusCode { get; set; }
        public NetworkCredential Credentials { get; set; }

        protected async Task<string> ExecuteAsync(string url, string actionName, string body)
        {
            if (Credentials != null && handler.Credentials == null)
                handler.Credentials = Credentials;

            if (!client.DefaultRequestHeaders.Contains("SOAPAction"))
                client.DefaultRequestHeaders.Add("SOAPAction", actionName);


            /*Avoid this error
            ---> System.Net.WebException: The underlying connection was closed: An unexpected error occurred on a receive. 
            ---> System.IO.IOException: Unable to read data from the transport connection: An existing connection was forcibly closed by the remote host. 
            ---> System.Net.Sockets.SocketException: An existing connection was forcibly closed by the remote host
            */
            //client.DefaultRequestHeaders.Add("Connection", "keep-alive");
            //client.DefaultRequestHeaders.Add("Keep-Alive", "600");
            //ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;

            var content = new StringContent(body, Encoding.UTF8, "text/xml");

            //var rs = @"<soapenv:Envelope xmlns:soapenv=""http://schemas.xmlsoap.org/soap/envelope/"" xmlns:v1=""http://contract.enzazaden.com/LIMS/v1"" xmlns:fil=""http://schemas.datacontract.org/2004/07/FillPlates""><soapenv:Header xmlns:fil=""http://schemas.datacontract.org/2004/07/FillPlates"" xmlns:v1=""http://contract.enzazaden.com/LIMS/v1"" xmlns:soapenv=""http://schemas.xmlsoap.org/soap/envelope/""><header xmlns:fil=""http://schemas.datacontract.org/2004/07/FillPlates"" xmlns:v1=""http://contract.enzazaden.com/LIMS/v1"" xmlns:soapenv=""http://schemas.xmlsoap.org/soap/envelope/"" xmlns=""http://schemas.cordys.com/General/1.0/""><msg-id>005056A2-51EC-A1EC-A296-5CF292E1813F</msg-id><messageoptions noreply=""true""/></header><bpm xmlns=""http://schemas.cordys.com/bpm/instance/1.0""><instance_id>005056A2-51EC-A1EC-A296-5E1C42C8013F</instance_id></bpm></soapenv:Header><soapenv:Body><FillPlatesWrapperResponse xmlns:fil=""http://schemas.datacontract.org/2004/07/FillPlates"" xmlns:v1=""http://contract.enzazaden.com/LIMS/v1"" xmlns:soapenv=""http://schemas.xmlsoap.org/soap/envelope/"" xmlns=""http://contract.enzazaden.com/LIMS/v1""><Result xmlns:fil=""http://schemas.datacontract.org/2004/07/FillPlates"" xmlns:v1=""http://contract.enzazaden.com/LIMS/v1"" xmlns:soapenv=""http://schemas.xmlsoap.org/soap/envelope/"" xmlns=""http://contract.enzazaden.com/LIMS/v1"" xmlns:SOAP=""http://schemas.xmlsoap.org/soap/envelope/"" xmlns:ns25=""http://schemas.xmlsoap.org/soap/encoding/"" xmlns:ns24=""http://microsoft.com/wsdl/mime/textMatching/"" xmlns:ns23=""http://www.starlims.com/webservices/encodedTypes"" xmlns:ns22=""http://www.starlims.com/webservices/"" xmlns:ns21=""http://schemas.cordys.com/General/1.0/"" xmlns:ns20=""http://schemas.cordys.com/cws/1.0"" xmlns:ns19=""http://schemas.cordys.com/1.0/xmlstore"" xmlns:ns18=""http://schemas.microsoft.com/2003/10/Serialization/"" xmlns:ns17=""http://schemas.xmlsoap.org/ws/2004/09/mex"" xmlns:ns16=""http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"" xmlns:ns15=""http://schemas.xmlsoap.org/ws/2004/09/policy"" xmlns:ns14=""http://www.w3.org/2006/05/addressing/wsdl"" xmlns:ns13=""http://schemas.xmlsoap.org/ws/2004/08/addressing/policy"" xmlns:ns12=""http://www.w3.org/2007/05/addressing/metadata"" xmlns:ns11=""http://www.w3.org/2005/08/addressing"" xmlns:ns10=""http://schemas.xmlsoap.org/ws/2004/08/addressing"" xmlns:ns9=""http://schemas.xmlsoap.org/wsdl/soap12/"" xmlns:ns8=""http://schemas.microsoft.com/ws/2005/12/wsdl/contract"" xmlns:ns7=""http://schemas.datacontract.org/2004/07/FillPlatesInLIMS"" xmlns:ns6=""http://ENZA/Lims/v1"" xmlns:ns5=""http://schemas.cordys.com/casemanagement/1.0"" xmlns:ns4=""http://schemas.datacontract.org/2004/07/ReservePlate"" xmlns:ns3=""http://schemas.cordys.com/bpm/execution/1.0"" xmlns:ns2=""http://schemas.datacontract.org/2004/07/FillPlates"" xmlns:bpm=""http://contract.enzazaden.com/LIMS/v1"" xmlns:sm=""http://www.w3.org/2005/07/scxml"" xmlns:instance=""http://schemas.cordys.com/bpm/instance/1.0"">Success</Result></FillPlatesWrapperResponse></soapenv:Body></soapenv:Envelope>";
            //return rs;
            using (var response = await client.PostAsync(url, content))
            {
                StatusCode = (int)response.StatusCode;
                var result = await response.Content.ReadAsStringAsync();

                if (response.IsSuccessStatusCode)
                    return result;

                if (response.StatusCode == HttpStatusCode.Unauthorized)
                    throw new SoapException("Response status code does not indicate success: 401 (Unauthorized).");
                var fault = GetSoapFaults(result);

                throw new SoapException(fault.FaultCode, fault.FaultString, fault.Detail);

            }
        }

        protected async Task<string> ExecuteAsync(string actionName, string body)
        {
            return await ExecuteAsync(Url, actionName, body);
        }

        protected async Task<string> ExecuteAsync(string actionName)
        {
            var body = PrepareBody();
            return await ExecuteAsync(actionName, body);
        }

        protected virtual string PrepareBody()
        {
            return string.Empty;
        }


        protected virtual SoapFault GetSoapFaults(string response)
        {
            var doc = XDocument.Parse(response);
            var faultCode = doc.Descendants("faultcode").FirstOrDefault()?.Value;
            var faultString = doc.Descendants("faultstring").FirstOrDefault()?.Value;
            var detail = doc.Descendants("detail").FirstOrDefault()?.Value;
            return new SoapFault
            {
                FaultCode = faultCode,
                FaultString = faultString,
                Detail = detail
            };
        }

        protected virtual SoapExecutionResult GetResult(XNamespace ns,  string response)
        {

            var doc = XDocument.Parse(response);
            var result = doc.Descendants(ns + "Result").FirstOrDefault()?.Value;
            var error = string.Empty;
            if (result != null && result.ToLower().Contains("failure"))
            {
                error = GetErrorDetails(ns, doc);
                if (string.IsNullOrWhiteSpace(error))
                {
                    error = result;
                    result = "Failure";
                }
            }
            return new SoapExecutionResult(result, error);
        }


        protected virtual string GetErrorDetails(XNamespace ns, XDocument doc)
        {
            var element = doc.Descendants(ns + "Errors").FirstOrDefault();
            if (element != null)
            {
                if (!element.HasElements)
                    return element.Value;
                return element.Element(ns + "faultDetails")?.Value;
            }
            return string.Empty;
        }

        #region IDisposable Support

        protected virtual void Dispose(bool disposing)
        {
            if (!disposed)
            {
                if (disposing)
                {
                    // TODO: dispose managed state (managed objects).
                    handler.Dispose();
                    client.Dispose();
                }

                // TODO: free unmanaged resources (unmanaged objects) and override a finalizer below.
                // TODO: set large fields to null.

                disposed = true;
            }
        }

        // TODO: override a finalizer only if Dispose(bool disposing) above has code to free unmanaged resources.
        // ~SoapClient() {
        //   // Do not change this code. Put cleanup code in Dispose(bool disposing) above.
        //   Dispose(false);
        // }

        // This code added to correctly implement the disposable pattern.
        public void Dispose()
        {
            // Do not change this code. Put cleanup code in Dispose(bool disposing) above.
            Dispose(true);
            // TODO: uncomment the following line if the finalizer is overridden above.
            // GC.SuppressFinalize(this);
        }

        #endregion
    }
}
