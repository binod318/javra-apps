using Enza.UTM.Common.Extensions;
using System.Collections.Generic;
using System.Data;
using System.Linq;

namespace Enza.UTM.Entities.Args
{
    public class ReceiveLDResultsRequestArgs
    {
        public int RequestID { get; set; }
        public string RequestingUser { get; set; }
        public string RequestingSystem { get; set; }
        public List<LDResult> Results { get; set; }
    }

    public class LDResult
    {
        public int SampleTestDetID { get; set; }
        public string Score { get; set; }
    }


    public class ReceiveLDResultsReceiveResult
    {
        public string Success { get; set; }
        public string ErrorMsg { get; set; }
    }
}
