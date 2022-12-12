using System.Collections.Generic;
using System.Xml.Serialization;

namespace TrialApp.Entities.ServiceResponse
{
    public class getTrialsWrapperResponse
    {
        [XmlElement("TrialDto")]
        public List<TrialDto1> TrialDto { get; set; }
    }

    public class TrialDto1
    {
        public string Completed { get; set; }
        public string CountryCode { get; set; }
        public string CountryName { get; set; }
        public string CropCode { get; set; }
        public string EZID { get; set; }
        public string Name { get; set; }
        public int TrialRegionID { get; set; }
        public string CropSegmentCode { get; set; }
        public int DefaultTraitSetID { get; set; }
        public string TrialTypeID { get; set; }
        public string Year { get; set; }
        public string Latitude { get; set; }
        public string Longitude { get; set; }
        public string UserTrialCode { get; set; }
    }
    public class getTrialsForExternalUserWrapperResponse: getTrialsWrapperResponse
    { }
    }
