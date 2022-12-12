using System.Collections.Generic;

namespace Enza.PtoV.Entities.Results
{
    public class GermplasmsColumnsResponse : GermplasmResult
    {
        public GermplasmsColumnsResponse()
        {
            Columns = new List<Column>();
        }
        public List<Column> Columns { get; set; }

    }
    public class Column
    {
        public Column()
        {
            properties = new List<ColumnProperty>();
        }
        //this property is equivalent to name property of column
        public string desc { get; set; }

        //this is equivalent to trait id
        public string variable_id { get; set; }

        //this is used to get data based for matching column
        public string id { get; set; }
        public string data_type { get; set; }
        public string col_num { get; set; }
        public List<ColumnProperty> properties { get; set; }
    }

    public class ColumnProperty
    {
        public string id { get; set; }
    }
}
