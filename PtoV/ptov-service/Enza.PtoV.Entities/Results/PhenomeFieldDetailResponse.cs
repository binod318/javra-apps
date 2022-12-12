using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Enza.PtoV.Entities.Results
{
    public class PhenomeFieldDetailResponse: GermplasmResult
    {
        public PhenomeFieldDetailResponse()
        {
            Info = new PhenomeFieldInfo();
        }
        public PhenomeFieldInfo Info { get; set; }

    }
    public class PhenomeFieldInfo
    {
        public string Code { get; set; }
        public string Description { get; set; }
        public string Name { get; set; }
    }
}
