using System.Collections.Generic;
using System.Data;

namespace Enza.PtoV.Entities.Args
{
    public class UpdateProductSegmentsRequestArgs : List<NewCropsAndProductSegment>
    {
        //public DataTable ToTVP()
        //{
        //    var dt = new DataTable("TVP_RelationTraitScreening");
        //    dt.Columns.Add("VarietyID", typeof(int));
        //    dt.Columns.Add("NewCropCode", typeof(string));
        //    dt.Columns.Add("ProdSegCode", typeof(string));
        //    dt.Columns.Add("CountryOfOrigin", typeof(string));
        //    foreach (var item in this)
        //    {
        //        var dr = dt.NewRow();
        //        dr["VarietyID"] = item.VarietyID;
        //        dr["NewCropCode"] = item.NewCropCode;
        //        dr["ProdSegCode"] = item.ProdSegCode;
        //        dr["ProdSegCode"] = item.CountryOfOrigin;
        //        dt.Rows.Add(dr);
        //    }
        //    return dt;
        //}
    }

    public class NewCropsAndProductSegment
    {
        public int VarietyID { get; set; }
        public string NewCropCode { get; set; }
        public string ProdSegCode { get; set; }
        public string CountryOfOrigin { get; set; }
    }
}
