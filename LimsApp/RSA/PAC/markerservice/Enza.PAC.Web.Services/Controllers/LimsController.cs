using Enza.PAC.BusinessAccess.Interfaces;
using Enza.PAC.Entities;
using Enza.PAC.Entities.Args;
using Enza.PAC.Web.Services.Core.Controllers;
using log4net;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Xml.Linq;

namespace Enza.PAC.Web.Services.Controllers
{
    [RoutePrefix("api/v1/Lims")]
    public class LimsController : BaseApiController
    {
        private readonly ILimsService _limsService;
        readonly Scheduling.QuartzJobScheduler _scheduler;
        public LimsController(ILimsService limsService, Scheduling.QuartzJobScheduler scheduler)
        {
            _limsService = limsService;
            _scheduler = scheduler;
        }

        [HttpPost]
        [Route("ReservePlateplansInLIMSCallback")]
        [Authorize(Roles = AppRoles.PAC_HANDLE_LAB_CAPACITY)]
        public async Task<IHttpActionResult> ReservePlateplansInLIMSCallback([FromBody]ReservePlateplansInLIMSCallbackRequestArgs requestArgs)
        {
            if (requestArgs == null)
                return InvalidRequest("Please provide required parameters.");

            var result = await _limsService.ReservePlateplansInLIMSCallbackAsync(requestArgs);
            return Ok(result);
        }

        [HttpPost]
        [Route("ReceiveResultsinKscoreCallback")]
        [Authorize(Roles = AppRoles.PAC_HANDLE_LAB_CAPACITY)]
        public async Task<IHttpActionResult> ReceiveResultsinKscoreCallback()
        {
            // these lines added to handle ubescaping of xml character
            string result = await Request.Content.ReadAsStringAsync();
            var htmlresult = System.Web.HttpUtility.HtmlDecode(result);
            //_logger.Error($"Request::{htmlresult}");
            var xml = XElement.Parse(htmlresult);

            if (xml == null)
                return InvalidRequest("Please provide required parameter(s).");

            XNamespace ns = "http://schemas.enzazaden.com/RestSeed2Seed";

            //var t2 = xml.Element(ns + "PACReceiveResultsinKscoreCallback");
            //var t3 = t2.Element(ns + "requestNode");
            //var t4 = t3.Element(ns + "RequestID");

            var requestID = int.Parse(xml.Element(ns + "RequestID").Value);

            var plates = (from _plate in xml.Element(ns + "Plates").Elements(ns + "Plate")
                          select new KscorePlate
                          {
                              LIMSPlateID = int.Parse(_plate.Element(ns +"LimsPlateID").Value),
                              Wells = (from _well in _plate.Element(ns +"Wells").Elements(ns +"Well")
                                       select new KscoreWell
                                       {
                                           PlateRow = _well.Element(ns +"PlateRow").Value,
                                           PlateColumn = int.Parse(_well.Element(ns +"PlateColumn").Value),
                                           Markers = (from _marker in _well.Element(ns +"Markers").Elements(ns +"Marker")
                                                      select new KscoreMarker
                                                      {
                                                          AlleleScore = _marker.Element(ns +"Scores").Element(ns +"Score").Element(ns +"AlleleScore").Value,
                                                          CreationDate = _marker.Element(ns + "Scores").Element(ns + "Score").Element(ns + "CreationDate").Value,
                                                          MarkerNr = _marker.Element(ns +"MarkerNr").Value,
                                                      }).ToList()
                                       }).ToList()
                          }).ToList();

            var args = new ReceiveResultsinKscoreRequestArgs
            {
                RequestID = requestID,
                Plates = plates
            };

            await _limsService.ReceiveResultsinKscoreCallbackAsync(args);

            await _scheduler.TriggerJobAsync<Scheduling.Jobs.TestResultSummaryJob>();

            return Ok();
        }
    }
}
