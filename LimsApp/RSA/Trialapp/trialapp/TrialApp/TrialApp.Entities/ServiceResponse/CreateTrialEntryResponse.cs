using System.Collections.Generic;
using System.Xml.Serialization;

namespace TrialApp.Entities.ServiceResponse
{
    [XmlRoot(ElementName = "createTrialEntryResponse")]
    public class CreateTrialEntryResponse
    {
        [XmlElement(ElementName = "TrialEntriesResultData")]
        public TrialEntriesResultData TrialEntriesResultData { get; set; }
        [XmlElement(ElementName = "Result")]
        public string Result { get; set; }
    }

    

    [XmlRoot(ElementName = "hideTrialEntriesWrapperResponse")]
    public class HideTrialEntriesWrapperResponse
    {
        [XmlElement(ElementName = "Result")]
        public string Result { get; set; }
    }

    [XmlRoot(ElementName = "CreateTrialEntryResponseDto")]
    public class CreateTrialEntryResponseDto
    {
        [XmlElement(ElementName = "TrialEntryEZID")]
        public string TrialEntryEZID { get; set; }
        [XmlElement(ElementName = "TrialEntryGuid")]
        public string TrialEntryGuid { get; set; }
    }

    [XmlRoot(ElementName = "TrialEntriesResultData")]
    public class TrialEntriesResultData
    {
        [XmlElement(ElementName = "CreateTrialEntryResponseDto")]
        public List<CreateTrialEntryResponseDto> CreateTrialEntryResponseDto { get; set; }
    }

  
}
