using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Enza.PtoV.Entities.Results
{
    public class ColumnResult
    {
        public int ColumnID { get; set; }
        public int ColumnNr { get; set; }
        public int? TraitID { get; set; }
        public string ColumnLabel { get; set; }
        public string DataType { get; set; }
        public string VariableID { get; set; }
    }
}
