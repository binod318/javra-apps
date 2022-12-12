﻿using System.Collections.Generic;
using System.Data;
using System.Linq;
using Enza.UTM.Common.Attributes;
using Enza.UTM.Entities.Args.Abstract;

namespace Enza.UTM.Entities.Args
{
    public class LeafDiskOverviewRequestArgs : PagedRequestArgs
    {
        public bool? Active { get; set; }
        [SwaggerExclude]
        public string Crops { get; set; }
        [SwaggerExclude]
        public bool ExportToExcel { get; set; }
    }
}
