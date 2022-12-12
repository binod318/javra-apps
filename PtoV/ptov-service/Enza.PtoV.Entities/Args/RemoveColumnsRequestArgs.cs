using System.Collections.Generic;

namespace Enza.PtoV.Entities.Args
{
    public class RemoveColumnsRequestArgs
    {
        public RemoveColumnsRequestArgs()
        {
            Columns = new List<RemoveColumnInfo>();
        }
        public string CropCode { get; set; }
      
        public List<RemoveColumnInfo> Columns { get; set; }
    }

    public class RemoveColumnInfo
    {
        public int TraitID { get; set; }
        public string ColumnLabel { get; set; }

    }
}
