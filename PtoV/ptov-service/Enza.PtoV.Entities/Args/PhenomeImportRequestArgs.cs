using Enza.PtoV.Entities.Args.Abstract;

namespace Enza.PtoV.Entities.Args
{
    public class PhenomeImportRequestArgs : RequestArgs
    {
        public string CropID { get; set; }
        public string ObjectType { get; set; }
        public string ObjectID { get; set; }
        public string GridID { get; set; }
        public string PositionStart { get; set; }
    }
}
