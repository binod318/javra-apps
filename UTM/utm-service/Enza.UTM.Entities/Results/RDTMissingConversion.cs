using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection.Emit;
using System.Text;
using System.Threading.Tasks;

namespace Enza.UTM.Entities.Results
{
    public class RDTMissingConversion
    {
        public string CropCode { get; set; }
        public string TestName { get; set; }
        public string TraitName { get; set; }
        public string DeterminationName { get; set; }
        public string DeterminationValue { get; set; }
        public string MappingColumn { get; set; }
        public int RDTTestResultID { get; set; }

    }
}
