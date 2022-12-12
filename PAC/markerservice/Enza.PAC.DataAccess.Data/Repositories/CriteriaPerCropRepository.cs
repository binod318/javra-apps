using System.Data;
using System.Threading.Tasks;
using Enza.PAC.Common.Extensions;
using Enza.PAC.DataAccess.Abstract;
using Enza.PAC.DataAccess.Data.Interfaces;
using Enza.PAC.Entities.Args;

namespace Enza.PAC.DataAccess.Data.Repositories
{
    public class CriteriaPerCropRepository : Repository<object>, ICriteriaPerCropRepository
    {
        public CriteriaPerCropRepository(IPACDatabase dbContext) : base(dbContext)
        {
            
        }

        public async Task<DataSet> GetAllCriteriaPerCropAsync(GetCriteriaPerCropRequestArgs requestArgs)
        {
            var ds = await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_ALL_CRITERIA_PER_CROP, CommandType.StoredProcedure, args => {
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

        public async Task PostAsync(CriteriaPerCropRequestArgs requestArgs)
        {
            var dataAsJson = requestArgs.ToJson();
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_SAVE_CRITERIA_PER_CROP,
               CommandType.StoredProcedure, args =>
               {
                   args.Add("@DataAsJson", dataAsJson);
               });
        }

    }
}
