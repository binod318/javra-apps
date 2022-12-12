using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using Enza.PAC.Common.Extensions;
using Enza.PAC.DataAccess.Abstract;
using Enza.PAC.DataAccess.Data.Interfaces;
using Enza.PAC.Entities.Args;

namespace Enza.PAC.DataAccess.Data.Repositories
{
    public class PacCapacityRepository : Repository<object>, IPacCapacityRepository
    {
        public PacCapacityRepository(IPACDatabase dbContext) : base(dbContext)
        {
            
        }

        public async Task<DataSet> GetPlanningCapacityAsync(int year)
        {
            var dataset = await DbContext.ExecuteDataSetAsync(DataConstants.PR_PAC_GET_CAPACITY, CommandType.StoredProcedure, args =>
            {
                args.Add("@Year", year);
            });
            dataset.Tables[0].TableName = "Data";
            dataset.Tables[1].TableName = "Columns";
            return dataset;
        }

        public async Task SaveLabCapacityAsync(List<SaveCapacityRequestArgs> requestArgs)
        {
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_PAC_SAVE_CAPACITY,
               CommandType.StoredProcedure, args =>
               {
                   args.Add("@Json", requestArgs.ToJson());
               });
        }

        public async Task<DataSet> GetPACPlanningCapacitySOAsync(int periodID)
        {
            var dataset = await DbContext.ExecuteDataSetAsync(DataConstants.PR_PAC_GET_PLANNING_CAPACITY_SO_LS, CommandType.StoredProcedure, args =>
            {
                args.Add("@PeriodID", periodID);
            });
            dataset.Tables[0].TableName = "Data";
            dataset.Tables[1].TableName = "Columns";
            dataset.Tables[2].TableName = "CalculatedPlates";
            return dataset;
        }

        public Task<DataSet> SavePACPlanningCapacitySOAsync(List<SavePlanningCapacitySOArgs> requestArgs)
        {
             return DbContext.ExecuteDataSetAsync(DataConstants.PR_PAC_SAVE_PLANNING_CAPACITY_SO_LS,
              CommandType.StoredProcedure, args =>
              {
                  args.Add("@Json", requestArgs.ToJson());
              });
        }
    }    
}
