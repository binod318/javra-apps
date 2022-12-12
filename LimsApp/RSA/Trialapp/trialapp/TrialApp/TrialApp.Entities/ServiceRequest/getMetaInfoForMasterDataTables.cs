using System;
using System.Collections.Generic;

namespace TrialApp.Entities
{
    /// <summary>
    /// version 1 for userservice call
    /// </summary>
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true, Namespace = "http://contract.enzazaden.com/common/masterdatamanagement/v1")]
    public  class getMetaInfoForMasterDataTables
    {
        public TablesInfo1 TablesInfo { get; set; }
    }

    public class TablesInfo1
    {
        public List<TablesName> tables { get; set; }
    }
    public class TablesName
    {
        public string table { get; set; }
    }
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true, Namespace = "http://contract.enzazaden.com/common/masterdatamanagement/v2")]
    public class GetMetaInfoForMasterDataTables_v1
    {
        public TablesInfo1 TablesInfo { get; set; }
    }
}
