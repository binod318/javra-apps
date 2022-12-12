using Enza.PAC.Entities.Args.Abstracts;

namespace Enza.PAC.Entities.Args
{
    public class GetDataForDecisionDetailRequestArgs : PagedRequestArgs
    {
        public int DetAssignmentID { get; set; }
    }
}
