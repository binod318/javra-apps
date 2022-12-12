using System;
using System.Collections.Generic;

namespace Enza.PAC.Entities.Results
{
    public class ListQualityConnect
    {
        public List<DeterminationAssignment> DeterminationAssignments { get; set; }
        public string UserName { get; set; }
    }

    public class DeterminationAssignment
    {
        public int DetAssignmentID { get; set; }
        public int ProductStatus { get; set; }
        public string ExpectedReadyDate { get; set; }
    }
}
