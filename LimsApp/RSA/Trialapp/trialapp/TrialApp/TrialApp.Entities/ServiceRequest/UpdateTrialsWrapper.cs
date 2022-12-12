using System.Xml.Serialization;

namespace TrialApp.Entities.ServiceRequest
{
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true, Namespace = "http://schemas.enzazaden.com/trailPrep/trials/1.0")]
    [XmlRoot(ElementName = "UpdateTrialsWrapper")]
    public class UpdateTrialsWrapper
    {
        /// <remarks/>
        public string UserName { get; set; }

        /// <remarks/>
        public string DeviceID { get; set; }
        /// <remarks/>
        public string SoftwareVersion { get; set; }

        /// <remarks/>
        public string AppName { get; set; }

        /// <remarks/>
        public string TrialData { get; set; }

        /// <remarks/>
        public string Token { get; set; }

    }
}
