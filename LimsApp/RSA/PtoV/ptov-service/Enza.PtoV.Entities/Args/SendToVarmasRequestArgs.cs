using System.Collections.Generic;

namespace Enza.PtoV.Entities.Args
{
    public class SendToVarmasRequestArgs 
    {
        public int VarietyID { get; set; }
        public bool OPAsParent { get; set; }
        public int MainGID { get; set; }
        public int NewGID { get; set; }
        public bool ForcedBit { get; set; }
        public List<int> SkipGID { get; set; }
    }    
}
