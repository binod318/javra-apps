using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Enza.PAC.Entities.Args
{
    public class ReservePlateplansInLIMSCallbackRequestArgs
    {
        public string SynchronisationCode { get; set; }
        public string RequestingUserID { get; set; }
        public int LIMSPlateplanID { get; set; }
        public string LIMSPlateplanName { get; set; }
        public string RequestingSystem { get; set; }
        public int RequestID { get; set; }
        public List<Plate> Plates { get; set; }
        public DataTable ToTVPPlates()
        {
            var dt = new DataTable("TVP_Plates");
            dt.Columns.Add("LIMSPlateID", typeof(int));
            dt.Columns.Add("LIMSPlateName", typeof(string));
            foreach (var item in Plates)
            {
                var dr = dt.NewRow();
                dr["LIMSPlateID"] = item.LIMSPlateID;
                dr["LIMSPlateName"] = item.LIMSPlateName;
                dt.Rows.Add(dr);
            }
            return dt;
        }

        public class Plate
        {
            public int LIMSPlateID { get; set; }
            public string LIMSPlateName { get; set; }
        }
    }
}
