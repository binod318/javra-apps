using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Serialization;

namespace TrialApp.Entities.ServiceRequest
{
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true, Namespace = "http://schemas.enzazaden.com/trailPrep/trials/1.0")]
    [XmlRoot(ElementName = "saveObservationData")]
    public class SaveObservationData
    {
        public string UserName { get; set; }
        public string DeviceID { get; set; }
        public string SoftwareVersion { get; set; }
        public string AppName { get; set; }
        public string Observationsjson { get; set; }
        public string Token { get; set; }
    }
}
