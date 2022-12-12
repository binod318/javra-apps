using Enza.UTM.Common.Extensions;
using System.Collections.Generic;
using System.Linq;

namespace Enza.UTM.Entities.Args
{
    public class SaveSamplePlotRequestArgs
    {
        public int TestID { get; set; }
        public int SampleID { get; set; }
        public List<int> Materials { get; set; }
        public string Action { get; set; }

        public string ToMaterialJson()
        {
            var obj = Materials.Select(o => new { SampleID, MaterialID = o }).ToList(); 
            return obj.ToJson();
        }
    }
}
