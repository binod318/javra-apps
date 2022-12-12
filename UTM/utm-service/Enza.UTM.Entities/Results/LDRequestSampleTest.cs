using System.Collections.Generic;

namespace Enza.UTM.Entities.Results
{
    public class LDRequestSampleTest
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
        public string SampleName { get; set; }
        public string ReferenceCode { get; set; }
        public int NrOfPlants { get; set; }
    }

    public class SampleDetermination
    {
        public int SampleTestDetID { get; set; }
        public int SampleID { get; set; }
        public int DeterminationID { get; set; }
        public string MethodCode { get; set; }
    }

    public class LDRequestSampleTestRequest
    {
        public string Crop { get; set; }
        public string BrStation { get; set; }
        public int RequestID { get; set; }
        public string Site { get; set; }
        public string RequestingUser { get; set; }
        public string RequestingName { get; set; }
        public string RequestingSystem { get; set; }
        public List<SampleDetermination> SampleDeterminations { get; set; }
        public List<SampleInfo> SamplesInfo { get; set; }

    }

    public class LDRequestSampleTestResult
    {
        public string Success { get; set; }
        public string ErrorMsg { get; set; }
    }
    public class SampleInfo
    {
        public int SampleID { get; set; }
        public List<Dictionary<string, string>> Info { get; set; }
        
    }
}
