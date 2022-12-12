using Enza.PAC.Entities.Args.Abstracts;
using System;

namespace Enza.PAC.Entities.Args
{
    public class GetABSAssignmentsRequestArgs : PagedRequestArgs
    {
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
    }
}
