namespace Enza.PtoV.Entities.VtoP
{
    public class VtoPSyncConfig
    {
        public int SyncConfigID { get; set; }
        public string CropCode { get; set; }
        public string SyncCode { get; set; }
        public int GermplasmSetID { get; set; }
        public int GBTHExternalLotFolderID { get; set; }
        public int ABSLotFolderID { get; set; }
        //public int ABSLotSetID { get; set; }
        public string Level { get; set; }
        public int LotNr { get; set; }
        public int SelfingFieldSetID { get; set; }
        public bool HasOp { get; set; }
    }
}
