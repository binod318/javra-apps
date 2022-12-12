using System.Xml.Serialization;

namespace TrialApp.Entities.ServiceResponse
{
    [XmlRoot(ElementName = "saveObservationDataResponse")]
    public class SaveObservationDataResponse
    {
        [XmlElement(ElementName = "Result")]
        public string Result { get; set; }
    }
}
