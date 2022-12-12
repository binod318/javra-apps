using Enza.PtoV.Entities.Args.Abstract;
using System.Collections.Generic;
using System.Data;

namespace Enza.PtoV.Entities.Args
{
    public class SaveTraitScreeningRequestArgs:PagedRequestArgs
    {
        public SaveTraitScreeningRequestArgs()
        {
            TraitScreeningRelation = new List<RelationTraitScreening>();
        }
        public List<RelationTraitScreening> TraitScreeningRelation { get; set; }
        public class RelationTraitScreening
        {
            public int TraitScreeningID { get; set; }
            public int ScreeningFieldID { get; set; }
            public int CropTraitID { get; set; }
            public string Action { get; set; }
            public bool PrefferredValue { get; set; }
            public bool SameValue { get; set; }
        }
        public DataTable ToRelationTraitScreeningTVP()
        {
            var dt = new DataTable("TVP_RelationTraitScreening");
            dt.Columns.Add("TraitScreeningID", typeof(int));
            dt.Columns.Add("ScreeningFieldID", typeof(int));
            dt.Columns.Add("CropTraitID", typeof(int));
            dt.Columns.Add("Action", typeof(string));            
            dt.Columns.Add("SameValue", typeof(bool));
            dt.Columns.Add("PrefferredValue", typeof(bool));
            foreach (var item in TraitScreeningRelation)
            {
                var dr = dt.NewRow();
                dr["TraitScreeningID"] = item.TraitScreeningID;
                dr["ScreeningFieldID"] = item.ScreeningFieldID;
                dr["CropTraitID"] = item.CropTraitID;
                dr["Action"] = item.Action;
                dr["SameValue"] = item.SameValue;
                dr["PrefferredValue"] = item.PrefferredValue;                
                dt.Rows.Add(dr);
            }
            return dt;
        }
    }
}
