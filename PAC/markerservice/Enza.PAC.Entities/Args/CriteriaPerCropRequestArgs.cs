namespace Enza.PAC.Entities.Args
{
    public class CriteriaPerCropRequestArgs
    {
        public string CropCode { get; set; }
        public int MaterialTypeID { get; set; }
        public decimal ThresholdA { get; set; }
        public decimal ThresholdB { get; set; }
        public bool CalcExternalAppHybrid { get; set; }
        public bool CalcExternalAppParent { get; set; }
        public string Action { get; set; }
    }
}
