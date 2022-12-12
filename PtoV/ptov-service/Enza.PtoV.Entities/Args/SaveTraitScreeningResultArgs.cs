using Enza.PtoV.Entities.Args.Abstract;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Enza.PtoV.Entities.Args
{
    public class SaveTraitScreeningResultArgs:PagedRequestArgs
    {
        public SaveTraitScreeningResultArgs()
        {
            TraitScreeningScreeningValues = new List<TraitScreeningResult>();
        }
        public List<TraitScreeningResult> TraitScreeningScreeningValues { get; set; }

        public DataTable ToTraitScreeningResultTVP()
        {
            var dt = new DataTable("TVP_RelationTraitScreening");
            dt.Columns.Add("TraitScrResultID", typeof(int));
            dt.Columns.Add("TraitScreeningID", typeof(int));
            dt.Columns.Add("TraitValueChar", typeof(string));
            dt.Columns.Add("ScreeningValue", typeof(string));
            dt.Columns.Add("PreferredValue", typeof(bool));
            dt.Columns.Add("Action", typeof(string));
            foreach (var item in TraitScreeningScreeningValues)
            {
                var dr = dt.NewRow();
                dr["TraitScrResultID"] = item.TraitScrResultID;
                dr["TraitScreeningID"] = item.TraitScreeningID;
                dr["TraitValueChar"] = item.TraitValueChar;
                dr["ScreeningValue"] = item.ScreeningValue;
                dr["PreferredValue"] = false;
                dr["Action"] = item.Action;
                dt.Rows.Add(dr);
            }
            return dt;
        }

        public class TraitScreeningResult
        {
            public int? TraitScrResultID { get; set; }
            public int TraitScreeningID { get; set; }
            public string TraitValueChar { get; set; }
            public string ScreeningValue { get; set; }            
            public bool SameValue { get; set; }
            public string Action { get; set; }
        }
    }
    
}
