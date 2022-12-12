using System;

namespace Enza.PtoV.Entities.Results
{
    public class CropResult
    {
        public string CropCode { get; set; }
        public string ObjectID { get; set; }
        public string ObjectType { get; set; }
        public DateTime VarietySyncTIme { get; set; }
        public DateTime CurrentUTCTime { get; set; }
        public int FileID { get; set; }
    }
}
