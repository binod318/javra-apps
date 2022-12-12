using System.Collections.Generic;

namespace Enza.PtoV.Entities.Results
{
    public class VarietyLogResult
    {
        public VarietyLogResult()
        {
            ProgramFieldData = new List<ProgramField>();
        }
        public string CropCode { get; set; }
        public int VarietyID { get; set; }
        public int GID { get; set; }
        public string ENumber { get; set; }
        public string VarietyName { get; set; }
        public int ObjectID { get; set; }
        public int ObjectType { get; set; }
        public string VarmasVarietyStatus { get; set; }

        public List<ProgramField> ProgramFieldData { get; set; }
    }
    public class ProgramField
    {
        public string TableName { get; set; }
        public string ProgramFieldCode { get; set; }
        public string ProgramFieldValue { get; set; }
    }
    public class VarietyLogRelation
    {
        public int VarietyNr { get; set; }
        public int GID { get; set; }
        public int ObjectID { get; set; }
        public int ObjectType { get; set; }
    }
}
