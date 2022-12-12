using System.Xml.Serialization;

namespace TrialApp.Entities.ServiceResponse
{
    [XmlRoot(ElementName = "UpdateTrialsWrapperResponse")]
    public class UpdateTrialsWrapperResponse
    {
        /// <remarks/>
        public string Result { get; set; }
    }
}
