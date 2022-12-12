using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using Enza.PAC.Common.Extensions;
using Enza.PAC.DataAccess.Abstract;
using Enza.PAC.DataAccess.Data.Interfaces;
using Enza.PAC.DataAccess.Interfaces;
using Enza.PAC.Entities.Args;

namespace Enza.PAC.DataAccess.Data.Repositories
{
    public class VarietyRepository : Repository<object>, IVarietyRepository
    {
        private readonly IUserContext userContext;
        public VarietyRepository(IPACDatabase dbContext, IUserContext userContext) : base(dbContext)
        {
            this.userContext = userContext;
        }

        public async Task<DataSet> GetMarkerPerVarietiesAsync(GetMarkerPerVarietyRequestArgs requestArgs)
        {
            var ds = await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_MARKER_PER_VARIETIES, CommandType.StoredProcedure, args => {
                args.Add("@PageNr", requestArgs.PageNr);
                args.Add("@PageSize", requestArgs.PageSize);
                args.Add("@SortBy", requestArgs.SortBy);
                args.Add("@SortOrder", requestArgs.SortOrder);
                foreach (var filter in requestArgs.Filters)
                {
                    args.Add(filter.Key, filter.Value);
                }
            });
            var dt = ds.Tables[0];
            if (dt.Rows.Count > 0)
            {
                requestArgs.TotalRows = dt.Rows[0]["TotalRows"].ToInt32();
                dt.Columns.Remove("TotalRows");
            }
            return ds;
        }

        public Task SaveMarkerPerVarietiesAsync(IEnumerable<SaveMarkerPerVarietyRequestArgs> requestArgs)
        {
            var dataAsJson = requestArgs.ToJson();
            return DbContext.ExecuteNonQueryAsync(DataConstants.PR_SAVE_MARKER_PER_VARIETIES,
               CommandType.StoredProcedure, args =>
               {
                   args.Add("@DataAsJson", dataAsJson);
                   args.Add("@ModifiedBy", userContext.GetContext().Name);
               });
        }
    }    
}
