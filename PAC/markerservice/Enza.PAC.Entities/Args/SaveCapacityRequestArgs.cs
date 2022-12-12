using Enza.PAC.Entities.Args.Abstracts;

namespace Enza.PAC.Entities.Args
{
    public class SaveCapacityRequestArgs : RequestArgs
    {
        public int PeriodID { get; set; }
        public string PlatformID { get; set; }
        public string Value { get; set; }
    }
}
