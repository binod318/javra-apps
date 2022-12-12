using Enza.PtoV.Entities.Args.Abstract;

namespace Enza.PtoV.Entities.Args
{
    public class EmailConfigRequestArgs : PagedRequest2Args
    {
        public string ConfigGroup { get; set; }
        public string CropCode { get; set; }
    }
}
