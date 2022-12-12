namespace Enza.PtoV.Entities.Results
{
    public class VarietyInfo
    {
        public int VarietyID { get; set; }
        public int GID { get; set; }
        public string SyncCode { get; set; }
        public string CropCode { get; set; }
        public string BrStationCode { get; set; }
        public int? FemaleParent { get; set; }
        public int? MaleParent { get; set; }
        public int? Maintainer { get; set; }
        public string TransferType { get; set; }
        public string PONumber { get; set; }
        public string MaintainerPONr { get; set; }
        public string VarmasStatus { get; set; }
    }
}
