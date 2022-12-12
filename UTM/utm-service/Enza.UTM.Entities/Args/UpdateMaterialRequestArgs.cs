using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Enza.UTM.Entities.Args
{
    public class UpdateMaterialRequestArgs
    {
        public int TestID { get; set; }
        public List<MaterialInfo> Materials { get; set; }
    }

    public class MaterialInfo
    {
        public int MaterialID { get; set; }
        public int NrOfPlants { get; set; }
    }
}
