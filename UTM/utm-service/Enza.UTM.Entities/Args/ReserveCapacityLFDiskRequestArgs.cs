using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Enza.UTM.Entities.Args
{
    public class ReserveCapacityLFDiskRequestArgs
    {
        public string BreedingStationCode { get; set; }
        public string CropCode { get; set; }
        public int TestTypeID { get; set; }
        public int MaterialTypeID { get; set; }        
        public DateTime PlannedDate { get; set; }
        public string Remark { get; set; }
        public bool Forced { get; set; }
        public int ProtocolID { get; set; }
        public int NrOfSample { get; set; }
        public int SiteID { get; set; }
    }
}
