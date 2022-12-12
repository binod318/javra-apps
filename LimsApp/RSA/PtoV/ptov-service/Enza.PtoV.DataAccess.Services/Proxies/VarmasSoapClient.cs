using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;
using Enza.PtoV.Common;
using Enza.PtoV.Common.Extensions;
using Enza.PtoV.Services.Abstract;

namespace Enza.PtoV.Services.Proxies
{
    public class VarmasSoapClient : SoapClient
    {
        public async Task<CreateVarietyResponse> SendToVarmasAsync()
        {
            var response = await ExecuteAsync("");
            return GetResponse(response);
        }

        public async Task<string> SyncToVarmasAsync(string url, object model)
        {
            var tpl = typeof(VarmasSoapClient).Assembly.GetString(
                "Enza.PtoV.Services.Requests.SyncVarmasVariety.st");
            var body = Template.Render(tpl, model);
            var response = await ExecuteAsync(url, "", body);
            var doc = XDocument.Parse(response);
            XNamespace ns = "http://contract.enzazaden.com/RandD/Eazy/Breezys/V01";
            var resp = doc.Descendants(ns + "UpdateVarmasScreeningDataResponse").FirstOrDefault();
            var result = resp?.Element("Result")?.Value;
            return result;
        }

        protected override string PrepareBody()
        {
            var body = typeof(VarmasSoapClient).Assembly.GetString(
                "Enza.PtoV.Services.Requests.CreateVarmasVariety.st");
            return Template.Render(body, Model);
        }

        private CreateVarietyResponse GetResponse(string xml)
        {
            var rs = new CreateVarietyResponse();
            var doc = XDocument.Parse(xml);
            XNamespace ns = "http://contract.enzazaden.com/RandD/Eazy/Breezys/V01";
            var resp = doc.Descendants(ns + "CreateVarmasVarietyResponse").FirstOrDefault();
            var result = resp?.Element("Result")?.Value;
            rs.Success = result.EqualsIgnoreCase("Success");
            if (!rs.Success)
            {
                rs.Message = result;
                return rs;
            }

            var varietyNr = resp?.Element("VarietyNr")?.Value;
            if (int.TryParse(varietyNr, out var value))
            {
                rs.VarietyNr = value;
            }

            rs.Enumber = resp?.Element("Enumber")?.Value;
            var lotnumber = resp?.Element("BreezysLotNr")?.Value;
            if (int.TryParse(lotnumber,out var val))
            {
                rs.LotNr = val;
            }
            rs.VarietyStatus = resp?.Element("VarietyStatus")?.Value;
            rs.VarietyName = resp?.Element("VarietyName")?.Value;
            return rs;
        }
    }

    public class CreateVarietyResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; }
        public int VarietyNr { get; set; }
        public string Enumber { get; set; }
        public int LotNr { get; set; }
        public string VarietyStatus { get; set; }
        public string VarietyName { get; set; }
    }

}
