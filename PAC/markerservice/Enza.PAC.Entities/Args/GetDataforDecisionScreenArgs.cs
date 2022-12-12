using Enza.PAC.Entities.Args.Abstracts;

namespace Enza.PAC.Entities.Args
{
    public class GetDataforDecisionScreenArgs : RequestArgs
    {
        public int DeterminationAssignmentID { get; set; }
    }
}
