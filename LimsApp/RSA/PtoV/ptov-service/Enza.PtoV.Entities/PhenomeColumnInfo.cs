using System.Collections.Generic;

namespace Enza.PtoV.Entities
{
    public class PhenomeColumnInfo
    {
        public string ID { get; set; }
        public int Index { get; set; }
        public string ColName { get; set; }
        public string DataType { get; set; }
        public string ColLabel { get; set; }
        public int? TraitID { get; set; }
        public string VariableID { get; set; }
    }
}
