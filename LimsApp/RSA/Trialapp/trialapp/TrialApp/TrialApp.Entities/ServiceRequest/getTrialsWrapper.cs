using System.Xml.Serialization;

namespace TrialApp.Entities
{
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true, Namespace = "http://schemas.enzazaden.com/trailPrep/trials/1.0")]
    [XmlRoot(ElementName = "getTrialsWrapper")]
    public  class getTrialsWrapper
    {
        public string UserName { get; set; }
        public string DeviceID { get; set; }
        public string SoftwareVersion { get; set; }
        public string AppName { get; set; }
        public string Token { get; set; }
    }
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true, Namespace = "http://schemas.enzazaden.com/trailPrep/trials/1.0")]
    [XmlRoot(ElementName = "getTrialsForExternalUserWrapper")]
    public class getTrialsForExternalUserWrapper : getTrialsWrapper
    {
        public string trialIDs { get; set; }
    }
}
