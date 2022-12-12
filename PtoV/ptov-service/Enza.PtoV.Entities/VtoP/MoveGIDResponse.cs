using Enza.PtoV.Entities.Results;
using System.Collections.Generic;

namespace Enza.PtoV.Entities.VtoP
{
    public class MoveGIDResponse: GermplasmResult
    {
        public MoveGIDResponse()
        {
            rows_ids = new List<string>();
        }
        public List<string> rows_ids { get; set; }
    }
}
