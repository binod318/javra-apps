using System;

namespace Enza.PAC.Entities.Args
{
    public class GetDeterminationAssignmentsRequestArgs
    {
        public int PeriodID { get; set; }
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public bool IncludeUnplanned { get; set; }
    }

    public class GetDeterminationAssignmentsServiceRequest
    {
        public string ABScrop { get; set; }
        public DateTime? DateFrom { get; set; }
        public DateTime? DateTo { get; set; }
        public int DeterminationAssignment { get; set; }
        public string MethodCode { get; set; }
        public int PageNumber { get; set; }
        public int PageSize { get; set; }
        public string Planner { get; set; }
        public string Priority { get; set; }
        public string StatusCode { get; set; }
    }
}
