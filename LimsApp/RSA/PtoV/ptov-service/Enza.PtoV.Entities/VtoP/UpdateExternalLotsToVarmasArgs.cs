using System.Collections.Generic;

namespace Enza.PtoV.Entities.VtoP
{
    public class UpdateExternalLotsToVarmasArgs
    {
        public UpdateExternalLotsToVarmasArgs()
        {
            Lots = new List<ExternalLotInfo>();
        }
        public string UserName { get; set; }
        public string SyncCode { get; set; }

        public List<ExternalLotInfo> Lots { get; set; }

    }

    public class ExternalLotInfo
    {
        public int LotNr { get; set; }
        public string PhenomeLotNr { get; set; }
        public int VarietyNr { get; set; }
        public string PhenomeGID { get; set; }
        public string EZID { get; set; }
        public string NewGID { get; set; }
    }
}
