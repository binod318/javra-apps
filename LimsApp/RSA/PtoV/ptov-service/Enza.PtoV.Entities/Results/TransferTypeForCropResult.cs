namespace Enza.PtoV.Entities.Results
{
    public class TransferTypeForCropResult
    {
        public string CropCode { get; set; }
        public bool HasHybrid { get; set; }
        public bool HasCms { get; set; }
        public bool HasOp { get; set; }
        public bool HasBulb { get; set; }
        public bool UsePONr { get; set; }
    }
}
