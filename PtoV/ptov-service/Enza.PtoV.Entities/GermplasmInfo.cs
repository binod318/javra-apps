using System;
using System.Collections;
using System.Collections.Generic;

namespace Enza.PtoV.Entities
{
    public class GermplasmInfo
    {
        public GermplasmInfo()
        {
            Values = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        }
        public int GID { get; set; }
        public IDictionary<string, string> Values { get; set; }
    }
}
