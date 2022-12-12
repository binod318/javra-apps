using Enza.PtoV.Common.Attributes;
using Enza.PtoV.Entities.Args.Abstract;

namespace Enza.PtoV.Entities.Args
{
    public class GermplasmsImportRequestArgs 
    {
        //this crop id is equivalent to research group id in phenome.
        public int CropID { get; set; }
        public string ObjectType { get; set; }
        public string ObjectID { get; set; }
        public string GridID { get; set; }
        public string PositionStart { get; set; }
        public int PageNumber { get; set; }
        public int PageSize { get; set; }

        [SwaggerExclude]
        public int TotalRows { get; set; }
        public int FolderID { get; set; }
        public string FolderObjectType { get; set; }
        public string ResearchGroupObjectType { get; set; }
    }
}
