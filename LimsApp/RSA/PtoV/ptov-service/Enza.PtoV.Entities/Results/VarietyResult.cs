namespace Enza.PtoV.Entities.Results
{
    public class VarietyResult
    {
        public int VarietyID { get; set; }
        public string SyncCode { get; set; }
        public string CropCode { get; set; }
        public string BrStationCode { get; set; }
        public int GID { get; set; }
        public string TransferType { get; set; }
        public string ENumber { get; set; }
        public string NewCropCode { get; set; }
        public string ProdSegCode { get; set; }
        public int StatusCode { get; set; }
        public int Maintainer { get; set; }
        public int FemaleParent { get; set; }
        public int MaleParent { get; set; }
        public int Parent { get; set; }
        public int LotNr { get; set; }
        public int VarmasVarietyNr { get; set; }
        public bool ReplacingLot { get; set; }
        public string CountryOfOrigin { get; set; }
        public bool UsePoNr { get; set; }
        public int Linkedvariety { get; set; }
        public string Stem { get; set; }
        //this is used if replace is done by already sent variety.
        public int linkedlot { get; set; }
    }
}
