using Enza.PtoV.Common.Attributes;
using System.Collections.Generic;
using System.Net.Http;

namespace Enza.PtoV.Entities.Args
{
    public class GetPedigreeRequestArgs
    {
        public GetPedigreeRequestArgs()
        {
            //Columns = new List<string>();
            //Filters = new PedigreeFilters();
        }
        /// <summary>
        /// GID for which we want to get pedigree information
        /// </summary>
        public int GID { get; set; }
        /// <summary>
        /// This GID First GID that is selected to fetch pedigree data for first time.
        /// </summary>
        public int BaseGID { get; set; }

        [SwaggerExclude]
        public HttpRequestMessage Request { get; set; }
        public int BackwardGen { get; set; }
        public int ForwardGen { get; set; }
        //public List<string> Columns { get; set; }
        //public PedigreeFilters Filters { get; set; }
    }

    public class PedigreeFilterCondition
    {
        public string Col { get; set; }
        public string Value { get; set; }
        public string Expr { get; set; }
    }

    public class PedigreeFilters
    {
        public PedigreeFilters()
        {
            Conditions = new List<PedigreeFilterCondition>();
        }
        public string Operator { get; set; }
        public List<PedigreeFilterCondition> Conditions { get; set; }
    }

}
