using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Enza.PtoV.Entities.Args.Abstract;

namespace Enza.PtoV.Entities
{
    public class MaintainerInfo
    {
        public int GID { get; set; }
        public int MaintainerGID { get; set; }
        public string MaintainerGen { get; set; }
        public string MaintainerPONr { get; set; }
    }
}
