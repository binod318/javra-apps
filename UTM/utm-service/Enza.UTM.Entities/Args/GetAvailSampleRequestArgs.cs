namespace Enza.UTM.Entities.Args
{
    public class GetAvailSampleRequestArgs
    {
        public int TestProtocolID { get; set; }        
        public string PlannedDate { get; set; }
        public int SiteID { get; set; }
    }
}
