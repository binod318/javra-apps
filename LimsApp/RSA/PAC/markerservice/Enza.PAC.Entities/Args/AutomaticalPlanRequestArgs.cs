using System;

namespace Enza.PAC.Entities.Args
{
    public class AutomaticalPlanRequestArgs
    {
        public int PeriodID { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
    }
}
