using Enza.UTM.Entities.Args.Abstract;
using System.Collections.Generic;

namespace Enza.UTM.Entities.Args
{
    public class LeafDiskManageMarkersRequestArgs : PagedRequestArgs
    {
        public LeafDiskManageMarkersRequestArgs()
        {
            SampleInfo = new List<LeafDiskManageSampleInfo>();
            Determinations = new List<int>();
            SampleIDs = new List<int>();
        }
        public int TestID { get; set; }
        /// <summary>
        /// only needed when we do update from grid
        /// </summary>
        public List<LeafDiskManageSampleInfo> SampleInfo { get; set; }
        /// <summary>
        /// Possible values=> Add / Update / delete
        /// </summary>
        public string Action { get; set; }        
        /// <summary>
        /// only needed when value is Add
        /// </summary>
        public List<int> Determinations { get; set; }
        /// <summary>
        /// only needed when value is Add.
        /// </summary>
        public List<int> SampleIDs { get; set; }
    }
    public class LeafDiskManageSampleInfo
    {
        public int SampleTestID { get; set; }
        public string Key { get; set; }
        /// <summary>
        /// if key is determiantion then value is true/false or can be 1/0, other values cannot be parsed
        /// </summary>
        public string Value { get; set; }
    }
}
