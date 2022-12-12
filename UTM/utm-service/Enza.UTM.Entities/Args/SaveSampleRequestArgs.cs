namespace Enza.UTM.Entities.Args
{
    public class SaveSampleRequestArgs
    {
        public int TestID { get; set; }
        public int? SampleID { get; set; }
        public string SampleName { get; set; }
        public int? NrOfSamples { get; set; }
    }

}
