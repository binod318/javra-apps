using System.Collections.Generic;

namespace Enza.PtoV.Entities
{
    public class PhenomeFolderInfo
    {
        public PhenomeFolderInfo()
        {
            Info = new FolderInfo();
        }
        public string Status { get; set; }
        public string Message { get; set; }
        public FolderInfo Info { get; set; }
    }

    public class FolderInfo
    {
        public FolderInfo()
        {
            BO_Variables = new List<BOVariable>();
            RG_Variables = new List<RGVariable>();
        }
         public List<BOVariable> BO_Variables { get; set; }
        public List<RGVariable> RG_Variables { get; set; }
    }

    public class BOVariable
    {
        public string VID { get; set; }
        public string Value { get; set; }
    }

    public class RGVariable
    {
        public string VID { get; set; }
        public string Name { get; set; }
    }
}
