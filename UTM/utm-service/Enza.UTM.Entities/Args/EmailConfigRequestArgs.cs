using Enza.UTM.Common.Attributes;
using Enza.UTM.Entities.Args.Abstract;

namespace Enza.UTM.Entities.Args
{
    public class EmailConfigRequestArgs : PagedRequestArgs
    {
        [SwaggerExclude]
        public string ConfigGroup { get; set; }
        [SwaggerExclude]
        public string CropCode { get; set; }
        [SwaggerExclude]
        public string BrStationCode { get; set; }
        public string UsedForMenu { get; set; }
    }
}
