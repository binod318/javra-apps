using System.Xml.Serialization;

namespace TrialApp.Entities
{
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true, Namespace = "http://contract.enzazaden.com/common/masterdatamanagement/v1")]
    [XmlRoot(ElementName = "getMasterData_V3")]
    public  class GetMasterData_V3
    {
        public string UserID { get; set; }
        public string DeviceID { get; set; }
        public string SoftwareVersion { get; set; }
        public string DatabaseVersion { get; set; }
        public string AppName { get; set; }
        public string TableName { get; set; }
        public string MTSeq { get; set; }
        public string NrOfRecords { get; set; }
        public string onlyActiveRecords { get; set; }
        public string orderBy { get; set; }
        public string isAscending { get; set; }
    }

    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true, Namespace = "http://contract.enzazaden.com/common/masterdatamanagement/v2")]
    [XmlRoot(ElementName = "GetMasterData_V4")]
    public class GetMasterData_V4
    {
        public string UserID { get; set; }
        public string DeviceID { get; set; }
        public string SoftwareVersion { get; set; }
        public string DatabaseVersion { get; set; }
        public string AppName { get; set; }
        public string TableName { get; set; }
        public string MTSeq { get; set; }
        public string NrOfRecords { get; set; }
        public string onlyActiveRecords { get; set; }
        public string orderBy { get; set; }
        public string isAscending { get; set; }
    }

}
