using Enza.UTM.Entities.Args.Abstract;
using System.Collections.Generic;

namespace Enza.UTM.Entities.Args
{
    public class LFDiskAssignMarkersRequestArgs : FilteredRequestArgs
    {
        public LFDiskAssignMarkersRequestArgs()
        {
            Determinations = new List<int>();
            SampleIDs = new List<int>();
        }
        public int TestID { get; set; }        
        public List<int> Determinations { get; set; }
        public List<int> SampleIDs { get; set; }
    }
}
