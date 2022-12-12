using System.Collections.Generic;

namespace Enza.PtoV.Entities.Results
{
    public class GermplasmsObjectResult
    {
        public GermplasmsObjectResult()
        {
            Columns = new List<ColumnInfo>();
        }

        public string CropCode { get; set; }
        public string ObjectID { get; set; }
        public string ObjectType { get; set; }
        public List<ColumnInfo> Columns { get; set; }

    }

    public class ColumnInfo
    {
        public int ColumnID { get; set; }
        public string ColumnLabel { get; set; }
        public string PhenomeColID { get; set; }
        public string VariableID { get; set; }
    }
}