using System.Collections.Generic;

namespace Enza.UTM.Entities.Args
{
    public class ReceiveSHResultsRequestArgs
    {
        public string RequestingUser { get; set; }
        public string RequestingSystem { get; set; }
        public List<SHSample> Samples { get; set; }
    }

    public class SHSample
    {
        public int SampleTestID { get; set; }
        public List<SHDetermination> Determinations { get; set; }
    }

    public class SHDetermination
    {
        public int DeterminationID { get; set; }
        public List<SHResultPair> Results { get; set; }
    }

    public class SHResultPair
    {
        public string Key { get; set; }
        public string Value { get; set; }
    }

    public class ReceiveSHResultsReceiveResult
    {
        public string Success { get; set; }
        public string ErrorMsg { get; set; }
    }
}
