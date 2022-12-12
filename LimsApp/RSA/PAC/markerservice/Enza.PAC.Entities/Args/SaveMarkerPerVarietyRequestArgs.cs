using Enza.PAC.Entities.Args.Abstracts;

namespace Enza.PAC.Entities.Args
{
    public class SaveMarkerPerVarietyRequestArgs : RequestArgs
    {
        public int? MarkerPerVarID { get; set; }
        public int MarkerID { get; set; }
        public int VarietyNr { get; set; }
        public string Action { get; set; }
        public string Remarks { get; set; }
        public string ExpectedResult { get; set; }
    }
}
