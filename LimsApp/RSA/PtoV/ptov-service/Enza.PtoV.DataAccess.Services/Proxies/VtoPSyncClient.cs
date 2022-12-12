using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;
using Enza.PtoV.Common;
using Enza.PtoV.Common.Extensions;
using Enza.PtoV.Services.Abstract;

namespace Enza.PtoV.Services.Proxies
{
    public class VtoPSyncClient : SoapClient
    {
        public async Task<IEnumerable<Lot>> GetLotsAndVarietiesAsync(string url, object model,string requestedData)
        {
            var tpl = typeof(VtoPSyncClient).Assembly.GetString("Enza.PtoV.Services.Requests.VtoP.GetVarietyAndLotsForSync.st");
            var body = Template.Render(tpl, model);
            var response = await ExecuteAsync(url, "", body);

            var doc = XDocument.Parse(response);
            XNamespace ns = "http://contract.enzazaden.com/RandD/Eazy/Breezys/V01";
            var resp = doc.Descendants(ns + "GetExternalLotsResponse").FirstOrDefault();
            var result = resp?.Element("Result")?.Value;
            if (!result.EqualsIgnoreCase("Success"))
                throw new Exception(result);
            
            //read xml and get data
            var lots = doc.Descendants("Lot")
                .Select(o => {
                    var lot = new Lot
                    {
                        LotNr = Convert.ToInt32(o.Element("LotNr").Value),
                        LotReference = o.Element("LotReference").Value,
                        VarietyNr = Convert.ToInt32(o.Element("VarietyNr").Value),
                        PhenomeGID = Convert.ToInt32(o.Element("PhenomeGID").Value),
                        //LotType = requestedData,
                        ProgramFields = o.Element("ProgramFieldsData")
                                     .Descendants("ProgramFieldData")
                                     .Select(x => new ProgramField
                                     {
                                         TableName = x.Element("PFTableName").Value,
                                         ProgramFieldCode = x.Element("ProgramFieldCode").Value,
                                         ProgramFieldValue = x.Element("ProgramFieldValue").Value
                                     }).ToList()

                    };
                    int lotNr = 0;
                    int.TryParse(lot.ProgramFields.FirstOrDefault(x => x.ProgramFieldCode.EqualsIgnoreCase("OriginLot"))?.ProgramFieldValue, out lotNr);

                    lot.LotType = lot.ProgramFields.FirstOrDefault(x => x.ProgramFieldCode.EqualsIgnoreCase("source"))?.ProgramFieldValue;
                    lot.OriginLot = lotNr;
                    lot.OriginLotSeedStatus = lot.ProgramFields.FirstOrDefault(x => x.ProgramFieldCode.EqualsIgnoreCase("OriginLotSeedStatus"))?.ProgramFieldValue;
                    return lot;
                }).ToList();
            return lots;
        }

        public async Task<bool> UpdateExtenalLotsAsync(string url, object model)
        {
            var tpl = typeof(VtoPSyncClient).Assembly.GetString("Enza.PtoV.Services.Requests.VtoP.UpdateExternalLots.st");
            var body = Template.Render(tpl, model);
            var response = await ExecuteAsync(url, "", body);

            var doc = XDocument.Parse(response);
            XNamespace ns = "http://contract.enzazaden.com/RandD/Eazy/Breezys/V01";
            var resp = doc.Descendants(ns + "UpdateExternalLotsResponse").FirstOrDefault();
            var result = resp?.Element("Result")?.Value;
            if (!result.EqualsIgnoreCase("Success"))
                throw new Exception(result);

            return true;
        }

        public async Task<GetVarietyInfoResponse> GetVarietiesAsync(string url, object model)
        {
            var tpl = typeof(VtoPSyncClient).Assembly.GetString("Enza.PtoV.Services.Requests.VtoP.GetVarietiesAndENumbersForSync.st");
            var body = Template.Render(tpl, model);
            var response = await ExecuteAsync(url, "", body);

            var doc = XDocument.Parse(response);
            XNamespace ns = "http://contract.enzazaden.com/RandD/Eazy/Breezys/V01";
            var resp = doc.Descendants(ns + "GetVarietyInfoResponse").FirstOrDefault();
            var result = resp?.Element("Result")?.Value;
            if (!result.EqualsIgnoreCase("Success"))
                throw new Exception(result);

            //read xml and get data
            var varieties = doc.Descendants("Variety")
                .Select(o => {
                    var variety = new VarietyInfo
                    {
                        VarietyNr = Convert.ToInt32(o.Element("VarietyNr").Value),
                        ProgramFields = o.Element("ProgramFieldsData")
                                        .Descendants("ProgramFieldData")
                                        .Select(x => new ProgramField
                                        {
                                            ProgramFieldCode = x.Element("ProgramFieldCode").Value,
                                            ProgramFieldValue = x.Element("ProgramFieldValue").Value
                                        }).ToList()
                    };
                    variety.CropCode = variety.ProgramFields.FirstOrDefault(x => x.ProgramFieldCode.EqualsIgnoreCase("vcroc_cropcod"))?.ProgramFieldValue;
                    return variety;
                }).ToList();
            

            return new GetVarietyInfoResponse
            {
                Timestamp = resp.Element("TimestampOut").Value,
                Varieties = varieties
            };
        }


        public class GetVarietyInfoResponse
        {
            public GetVarietyInfoResponse()
            {
                Varieties = new List<VarietyInfo>();
            }
            public string Timestamp { get; set; }

            public List<VarietyInfo> Varieties { get; set; }
        }
        
        public class VarietyInfo
        {
            public VarietyInfo()
            {
                ProgramFields = new List<ProgramField>();
            }
            public int VarietyNr { get; set; }
            public string CropCode { get; set; }
            public List<ProgramField> ProgramFields { get; set; }
        }
        
        public class Lot
        {
            public Lot()
            {
                ProgramFields = new List<ProgramField>();
            }
            public int LotNr { get; set; }
            public string LotReference { get; set; }
            public int VarietyNr { get; set; }
            public int PhenomeGID { get; set; }
            public string LotType { get; set; }
            /// <summary>
            /// varmas lot nr
            /// </summary>
            public int OriginLot { get; set; }
            /// <summary>
            /// varmas seed status code
            /// </summary>
            public string OriginLotSeedStatus { get; set; }
            //public bool NeedSelfing { get; set; }
            public List<ProgramField> ProgramFields { get; set; }
        }

        public class ProgramField
        {
            public string TableName { get; set; }
            public string ProgramFieldCode { get; set; }
            public string ProgramFieldValue { get; set; }
        }
    }    
}
