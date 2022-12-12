using Enza.PAC.Common.Attributes;
using System.Collections.Generic;
using System.Linq;

namespace Enza.PAC.Entities.Args.Abstracts
{
    public abstract class RequestArgs
    {
    }

    public abstract class PagedRequestArgs : RequestArgs
    {
        protected PagedRequestArgs()
        {
        }
        public int PageNr { get; set; }
        public int PageSize { get; set; }
        public string SortBy { get; set; }
        public string SortOrder { get; set; }

        [SwaggerExclude]
        public int TotalRows { get; set; }
    }
}