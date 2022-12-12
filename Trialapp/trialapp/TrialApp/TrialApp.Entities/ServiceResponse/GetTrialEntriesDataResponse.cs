using System.Collections.Generic;
using System.Xml.Serialization;

namespace TrialApp.Entities.ServiceResponse
{
    [XmlRoot(ElementName = "getTrialEntriesDataResponse")]
    public class GetTrialEntriesDataResponse
    {
        [XmlElement(ElementName = "EZID")]
        public string EZID { get; set; }
        [XmlElement(ElementName = "Observations")]
        public Observation Observations { get; set; }
        [XmlElement(ElementName = "TrialEntries")]
        public TrialEntries TrialEntries { get; set; }
        [XmlElement(ElementName = "Result")]
        public string Result { get; set; }
    }
   
    [XmlRoot(ElementName = "TrialEntryDto")]
    public class TrialEntryDto1
    {
        [XmlElement(ElementName = "CropCode")]
        public string CropCode { get; set; }
        [XmlElement(ElementName = "EZID")]
        public string EZID { get; set; }
        [XmlElement(ElementName = "FieldNumber")]
        public string FieldNumber { get; set; }
        [XmlElement(ElementName = "Name")]
        public string Name { get; set; }
        [XmlElement("Observations")]
        public Observation Observations { get; set; }
        [XmlElement(ElementName = "TrialID")]
        public string TrialID { get; set; }
        [XmlElement(ElementName = "Variety")]
        public Variety1 Variety { get; set; }

        [XmlElement(ElementName = "IsHidden")]
        public bool IsHidden { get; set; }
    }

    public class Observation
    {
        [XmlElement("ObservationDto")]
        public List<ObservationDto1> ObservationDto { get; set; }
    }
    public class TrialEntries
    {
        [XmlElement("TrialEntryDto")]
        public List<TrialEntryDto1> TrialEntryDto { get; set; }
    }
    public class ObservationDto1
    {
        [XmlElement(ElementName = "EZID")]
        public string EZID { get; set; }
        [XmlElement(ElementName = "ObservationDate")]
        public string ObservationDate { get; set; }
        [XmlElement(ElementName = "ObservationID")]
        public string ObservationID { get; set; }
        [XmlElement(ElementName = "TraitID")]
        public string TraitID { get; set; }
        [XmlElement(ElementName = "UserIDCreated")]
        public string UserIDCreated { get; set; }
        [XmlElement(ElementName = "UserIDUpdated")]
        public string UserIDUpdated { get; set; }
        [XmlElement(ElementName = "UtcInsertDate")]
        public string UtcInsertDate { get; set; }
        [XmlElement(ElementName = "UtcUpdateDate")]
        public string UtcUpdateDate { get; set; }
        [XmlElement(ElementName = "ValueChar")]
        public string ValueChar { get; set; }
        [XmlElement(ElementName = "ValueDate")]
        public string ValueDate { get; set; }
        [XmlElement(ElementName = "ValueDec")]
        public string ValueDec { get; set; }

        [XmlElement(ElementName = "ObsValueDecMetric")]
        public string ObsValueDecMetric { get; set; }

        [XmlElement(ElementName = "ObsValueDecImperial")]
        public string ObsValueDecImperial { get; set; }

        [XmlElement(ElementName = "ValueInt")]
        public string ValueInt { get; set; }
    }
    [XmlRoot(ElementName = "Variety")]
    public class Variety1
    {
        public string CropCode { get; set; }
        public string CropSegmentCode { get; set; }
        public string EZID { get; set; }
        public string Enumber { get; set; }
        public string MasterNumber { get; set; }
        public string Name { get; set; }
        public string Number { get; set; }
        public string Observations { get; set; }
        public string ProductSegmentCode { get; set; }
        public string ProductStatus { get; set; }
        public string ResistanceHR { get; set; }
        public string ResistanceIR { get; set; }
        public string ResistanceT { get; set; }
        public string SortingOrder { get; set; }

    }


    //public  class TrialEntriesTrialEntryDtoObservations
    //{
    //    public ObservationsObservationDto[] ObservationDto { get; set; }
    //}
}
