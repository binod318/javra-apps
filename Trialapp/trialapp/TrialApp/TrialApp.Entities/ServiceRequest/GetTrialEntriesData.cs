using System.Xml.Serialization;

namespace TrialApp.Entities.ServiceRequest
{
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true, Namespace = "http://schemas.enzazaden.com/trailPrep/trials/1.0")]
    [XmlRoot(ElementName = "getTrialEntriesData")]
    public class GetTrialEntriesData
    {
        [XmlElement(ElementName = "UserName")]
        public string UserName { get; set; }
        [XmlElement(ElementName = "DeviceID")]
        public string DeviceID { get; set; }
        [XmlElement(ElementName = "SoftwareVersion")]
        public string SoftwareVersion { get; set; }
        [XmlElement(ElementName = "AppName")]
        public string AppName { get; set; }
        [XmlElement(ElementName = "EZID")]
        public string EZID { get; set; }
        [XmlElement(ElementName = "Token")]
        public string Token { get; set; }
    }
}
