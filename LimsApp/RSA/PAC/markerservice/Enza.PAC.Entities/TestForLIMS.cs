namespace Enza.PAC.Entities
{
    public class TestForLIMS
    {
        public string CropCode { get; set; }
        public int? PlannedWeek { get; set; }
        public int? PlannedYear { get; set; }
        public int TotalPlates { get; set; }
        public int TotalTests { get; set; }
        public string SynCode { get; set; }
        public string Remark { get; set; }
        public string Isolated { get; set; }
        public string MaterialState { get; set; }
        public string MaterialType { get; set; }
        public string ContainerType { get; set; }
        public int? ExpectedWeek { get; set; }
        public int? ExpectedYear { get; set; }
        public string CountryCode { get; set; }
        public string PlannedDate { get; set; }
        public string ExpectedDate { get; set; }
        public int RequestID { get; set; }
        public string RequestingSystem { get; set; }
    }
}
