using Enza.PtoV.Entities.Args.Abstract;
using System.Collections.Generic;
using System.Diagnostics;

namespace Enza.PtoV.Entities.VtoP
{
    public class GermplasmColumnResponse : PhenomeResponse
    {
        public GermplasmColumnResponse()
        {
            Available = new List<GermplasmColumnInfo>();
        }
        public List<GermplasmColumnInfo> Available { get; set; }
    }

    [DebuggerDisplay("id={id}, desc={desc}")]
    public class GermplasmColumnInfo
    {
        public string id { get; set; }
        public string desc { get; set; }
    }
}
