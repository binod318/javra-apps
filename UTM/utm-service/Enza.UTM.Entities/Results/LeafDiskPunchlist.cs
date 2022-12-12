using System.Collections.Generic;

namespace Enza.UTM.Entities.Results
{

    public class LeafDiskPunchlist
    {
        public LeafDiskPunchlist()
        {
            //Rows = new Row();
            Rows = new List<Row>();
            Columns = new List<Column>();
            //Cells = new List<Cell>();
        }
        public int CellsPerRow { get; set; }
        public List<Row> Rows { get; set; }
        public List<Column> Columns { get; set; }
        
        public class Column
        {
            public int ColumnNr { get; set; }
            public string ColumnHeader { get; set; }

        }
        public class Row
        {
            public Row()
            {
                Cells = new List<Cell>();
            }
            public int RowNr { get; set; }
            public string RowHeader { get; set; }
            public List<Cell> Cells { get; set; }

        }
        public class Cell
        {
            public int RowNr { get; set; }
            public int ColumnNr { get; set; }
            public string Value { get; set; }
        }
    }
    public class LDSampleMaterial
    {
        public int SampleID { get; set; }
        public string SampleName { get; set; }
        public int MaterialID { get; set; }
        public string Material { get; set; }
    }

}
