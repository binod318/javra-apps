using System.Collections.Generic;

namespace Enza.UTM.Entities.Results
{
    public class RequestSampleTestLD
    {
        public string Crop { get; set; }
        public string BrStation { get; set; }
        public int RequestID { get; set; }
        public string Site { get; set; }
        public string RequestingSystem { get; set; }
        public int SampleTestDetID { get; set; }
        public int SampleID { get; set; }
        public int DeterminationID { get; set; }
        public string MethodCode { get; set; }
    }

    public class SampleDetermination
    {
        public int SampleTestDetID { get; set; }
        public int SampleID { get; set; }
        public int DeterminationID { get; set; }
        public string MethodCode { get; set; }
    }

    public class RequestSampleTestLDRequest
    {
        public string Crop { get; set; }
        public string BrStation { get; set; }
        public int RequestID { get; set; }
        public string Site { get; set; }
        public string RequestingUser { get; set; }
        public string RequestingName { get; set; }
        public string RequestingSystem { get; set; }
        public List<SampleDetermination> SampleDeterminations { get; set; }
    }

    public class RequestSampleTestLDResult
    {
        public string Success { get; set; }
        public string ErrorMsg { get; set; }
    }
}
