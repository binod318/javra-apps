using System.Collections.Generic;
using System.Data;

namespace Enza.PtoV.Entities.Results
{
    public class GermplasmsImportResult:GermplasmResult
    {
        public GermplasmsImportResult()
        {
            Errors = new List<string>();
            Data = new GermplasmsData();
        }
        public int Total { get; set; }
        public string FileName { get; set; }
        public List<string> Errors { get; set; }
        public GermplasmsData Data { get; set; }
    }

    public class GermplasmsData
    {
        public GermplasmsData()
        {
            Columns = new DataTable("Columns");
            Data = new DataTable("Data");
        }

        public DataTable Columns { get; set; }
        public DataTable Data { get; set; }
    }
}