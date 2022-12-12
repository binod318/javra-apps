using Enza.UTM.Common.Attributes;
using Enza.UTM.Entities.Args.Abstract;

namespace Enza.UTM.Entities.Args
{
    public class LabOverviewRequestArgs : PagedRequestArgs
    {
        public int Year { get; set; }
        public int? PeriodID { get; set; } = null;
        public int SiteID { get; set; }
        [SwaggerExclude]
        public bool ExportToExcel { get; set; }
    }
}
