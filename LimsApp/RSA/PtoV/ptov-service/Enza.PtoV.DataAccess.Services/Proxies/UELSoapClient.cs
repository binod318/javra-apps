using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;
using Enza.PtoV.Common;
using Enza.PtoV.Common.Extensions;
using Enza.PtoV.Services.Abstract;

namespace Enza.PtoV.Services.Proxies
{
    public class UELSoapClient : SoapClient
    {
        public async Task<(string Result, string LogID)> CreateUELRecordProcessAsync()
        {
            var response = await ExecuteAsync("");
            XNamespace ns = "http://contract.enzazaden.com/uel/logging/v1";
            var rs = GetResult(response, ns);
            return rs;
        }
        protected override string PrepareBody()
        {
            var body = typeof(UELSoapClient).Assembly.GetString("Enza.PtoV.Services.Requests.CreateUELRecordProcess.st");
            return Template.Render(body, Model);
        }

        public (string Result, string LogID) GetResult(string response, XNamespace ns)
        {
            var doc = XDocument.Parse(response);
            var result = doc.Descendants(ns + "result")?.FirstOrDefault()?.Value;
            var logID = doc.Descendants(ns + "logID")?.FirstOrDefault()?.Value;
            return (result, logID);
        }
    }
    public class CreateUELRecord
    {
        public string Environment { get; set; }
        public string Location { get; set; }
        public string ErrorDetailText { get; set; }
        public string UserID { get; set; }
        public string Application { get; set; }
        public CreateUelRecordInstanceProperties InstanceProperties { get; set; }
    }

    public class CreateUelRecordInstanceProperties
    {
        public string ProcessDescription { get; set; }
        public string Organization { get; set; }
    }
}
