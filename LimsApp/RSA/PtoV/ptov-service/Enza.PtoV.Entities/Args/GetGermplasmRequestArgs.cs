using Enza.PtoV.Common.Attributes;
using Enza.PtoV.Entities.Args.Abstract;

namespace Enza.PtoV.Entities.Args
{
    public class GetGermplasmRequestArgs : PagedRequestArgs
    {
        public string FileName { get; set; }
        [SwaggerExclude]
        public bool ForSendToVarmas { get; set; }
        public string ObjectType { get; set; }
        public string ObjectID { get; set; }
        public bool IsHybrid { get; set; }
    }
}
