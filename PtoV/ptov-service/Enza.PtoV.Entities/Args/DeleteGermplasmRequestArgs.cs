using System.Collections.Generic;
using System.Data;

namespace Enza.PtoV.Entities.Args
{
    public class DeleteGermplasmRequestArgs
    {
        public DeleteGermplasmRequestArgs()
        {
            Germplasm = new List<int>();
        }
        public List<int> Germplasm { get; set; }
        public bool DeleteParent { get; set; }
    }
}
