using System.Collections.Generic;
using System.Xml.Serialization;

namespace TrialApp.Entities.ServiceResponse
{
    public class getMetaInfoForMasterDataTablesResponse
    {
        public Tables Tables { get; set; }
    }
    public class GetMetaInfoForMasterDataTables_v1Response
    {
        public Tables Tables { get; set; }
    }
    public class Tables
    {
        [XmlElement("Table")]
        public List<Table1> Table { get; set; }
    }

    public class Table1
    {
        public string Name { get; set; }
        public string Count { get; set; }
        public string MTSeqMax { get; set; }
    }

}
