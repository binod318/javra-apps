using Enza.PAC.Entities.Args.Abstracts;
using System.Collections.Generic;

namespace Enza.PAC.Entities.Args
{
    public class GetMarkerPerVarietyRequestArgs : PagedRequestArgs
    {
        public GetMarkerPerVarietyRequestArgs()
        {
            Filters = new Dictionary<string, string>();
        }
        public Dictionary<string, string> Filters { get; set; }
    }
}
