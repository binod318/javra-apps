using System.IO;
using Enza.UTM.Entities.Args.Abstract;
using System;
using Enza.UTM.Common.Attributes;

namespace Enza.UTM.Entities.Args
{
    public class SeedHealthGetDataRequestArgs : PagedRequestArgs
    {        
        public int TestID { get; set; }
    }
}
