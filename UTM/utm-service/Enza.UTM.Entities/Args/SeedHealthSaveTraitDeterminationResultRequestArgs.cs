using System.Collections.Generic;
using System.Data;
using Enza.UTM.Common.Attributes;
using Enza.UTM.Entities.Args.Abstract;

namespace Enza.UTM.Entities.Args
{
    public class SeedHealthSaveTraitDeterminationResultRequestArgs : PagedRequestArgs
    {
        [SwaggerExclude]
        public string Crops { get; set; }
        public SeedHealthSaveTraitDeterminationResultRequestArgs()
        {
            Data = new List<SeedHealthTraitDeterminationResult>();
        }
        public string CropCode { get; set; }
        public List<SeedHealthTraitDeterminationResult> Data { get; set; }

        public DataTable ToTvp()
        {
            var dt = new DataTable("TVP_SHTraitDeterminationResult");
            dt.Columns.Add("SHTraitDetResultID", typeof(int));
            dt.Columns.Add("RelatioID", typeof(int));            
            dt.Columns.Add("SampleType");
            dt.Columns.Add("MappingCol");
            dt.Columns.Add("Action");

            foreach (var item in Data)
            {
                var dr = dt.NewRow();
                dr["SHTraitDetResultID"] = item.ID;
                dr["RelatioID"] = item.RelationID;
                dr["SampleType"] = item.SampleType;
                dr["MappingCol"] = item.MappingCol;
                dr["Action"] = item.Action;
                dt.Rows.Add(dr);
            }
            return dt;
        }
    }

    public class SeedHealthTraitDeterminationResult
    {
        public int ID { get; set; }
        public int RelationID { get; set; }     
        
        public string SampleType { get; set; }
        public string MappingCol { get; set; }
        public string Action { get; set; }

        
    }
}
