using System.Collections.Generic;
using System.Data;

namespace Enza.PtoV.Entities.Results
{
    public class PedigreeResult
    {
        public int Total { get; set; }
        public PedigreeResult()
        {
            Columns = new DataTable("Columns");
            Columns.Columns.Add("TraitID", typeof(int));
            Columns.Columns.Add("PhenomeColID");
            Columns.Columns.Add("ColumnLabel");
            Data = new DataTable("Data");
        }
        public DataTable Columns { get; set; }
        public DataTable Data { get; set; }
    }
    
}