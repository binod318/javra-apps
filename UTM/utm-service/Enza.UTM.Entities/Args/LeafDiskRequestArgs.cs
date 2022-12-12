using Enza.UTM.Common.Attributes;
using System;

namespace Enza.UTM.Entities.Args
{
    public class LeafDiskRequestArgs
    {        
        public int TestID { get; set; }
        public string TestName { get; set; }
        public string FilePath { get; set; }       
        public string ObjectID { get; set; }
        public int TestProtocolID { get; set; }
        public string FolderID { get; set; }
        public string CropID { get; set; }
        /// <summary>
        /// describe from where user want to import data.
        ///
        /// 24 => list/nursery (list/plants)
        /// 25=> maps
        /// 26=> Plots
        /// 27=> crosses
        /// 28=> selections
        /// 29=> observations
        /// </summary>
        public string ObjectType { get; set; }
        public string GridID { get; set; }
        public string CropCode { get; set; }
        public bool ForcedImport { get; set; }
        public int FileID { get; set; }
        public DateTime? PlannedDate { get; set; }
        public int MaterialTypeID { get; set; }
        public int SiteID { get; set; }
    }

    public class LDImportFromConfigRequestArgs
    {
        public int TestID { get; set; }
        public int SourceID { get; set; }
        public string TestName { get; set; }
        //public string FilePath { get; set; }
        //public string ObjectID { get; set; }
        public int TestProtocolID { get; set; }
        //public string FolderID { get; set; }
        //public string CropID { get; set; }
        //public string ObjectType { get; set; }
        //public string GridID { get; set; }
        //public string CropCode { get; set; }
        public bool ForcedImport { get; set; }
        //public int FileID { get; set; }
        public DateTime? PlannedDate { get; set; }
        public int MaterialTypeID { get; set; }
        public int SiteID { get; set; }
    }
}
