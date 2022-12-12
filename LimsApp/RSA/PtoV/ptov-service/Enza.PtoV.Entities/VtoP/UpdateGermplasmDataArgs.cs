using System;
using System.Collections.Generic;

namespace Enza.PtoV.Entities.VtoP
{
    public class UpdateGermplasmDataArgs
    {
        public UpdateGermplasmDataArgs()
        {
            Values = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        }
        public int ObjectType { get; set; }
        public int ObjectID { get; set; }
        public int GID { get; set; }
        public Dictionary<string, string> Values { get; set; }
    }
}
