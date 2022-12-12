using Enza.PAC.Entities.Args.Abstracts;

namespace Enza.PAC.Entities.Args
{
    public class SavePlanningCapacitySOArgs : RequestArgs
    {
        public int CropMethodID { get; set; }
        public int PeriodID { get; set; }
        public int Value { get; set; }
    }
}
