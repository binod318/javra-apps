using Enza.UTM.DataAccess.Abstract;
using Enza.UTM.DataAccess.Interfaces;
using Enza.UTM.DataAccess.Data.Planning.Interfaces;
using System;
using System.Data;
using System.Threading.Tasks;
using Enza.UTM.Entities.Args;
using Enza.UTM.Entities.Results;
using System.Collections.Generic;
using Enza.UTM.Common.Extensions;

namespace Enza.UTM.DataAccess.Data.Planning.Repositories
{
    public class LeafDiskCapacityRepository : Repository<object>, ILeafDiskCapacityRepository
    {
        private readonly IUserContext userContext;
        public LeafDiskCapacityRepository(IDatabase dbContext, IUserContext userContext) : base(dbContext)
        {
            this.userContext = userContext;
        }

        public async Task<DataSet> GetCapacityAsync(int year, int siteLocation)
        {
            var dataset =  await DbContext.ExecuteDataSetAsync(DataConstants.PR_LFDISK_GET_CAPACITY, CommandType.StoredProcedure, args =>
            {                
                args.Add("@Year",year);
                args.Add("@SiteLocation", siteLocation);
            });
            dataset.Tables[0].TableName = "Data";
            dataset.Tables[1].TableName = "Columns";
            return dataset;
            
        }

        public async Task<bool> SaveCapacityAsync(SaveCapacityRequestArgs request)
        {
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_LFDISK_SAVE_CAPACITY,
                CommandType.StoredProcedure, args =>
                {
                    args.Add("@TVP_Capacity", request.ToTVPCapacity());
                    args.Add("@SiteID", request.SiteID);
                });

            return true;
        }        

        public async Task<DataSet> GetPlanApprovalListForLabAsync(int periodID, int siteID)
        {
            var ds = await DbContext.ExecuteDataSetAsync(DataConstants.PR_LFDISK_GET_PLAN_APPROVAL_LIST_FOR_LAB,
                CommandType.StoredProcedure,
                args => { 
                    args.Add("@SiteID", siteID); 
                    args.Add("@periodID", periodID); 
                }
            );
            ds.Tables[0].TableName = "Standard";
            ds.Tables[1].TableName = "Current";
            ds.Tables[2].TableName = "Columns";
            ds.Tables[3].TableName = "Details";
            return ds;
        }
        public async Task<bool> MoveSlotAsync(MoveSlotRequestArgs args)
        {
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_PLAN_MOVE_CAPACITY_SLOT,
                CommandType.StoredProcedure, param =>
                {
                    param.Add("@SlotID", args.SlotID);
                    param.Add("@PlannedDate", args.PlannedDate);
                    param.Add("@ExpectedDate", args.ExpectedDate);
                });
            return true;
        }

        public async Task<bool> DeleteSlotAsync(DeleteSlotRequestArgs args)
        {
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_PLAN_REMOVE_SLOT,
                CommandType.StoredProcedure, param =>
                {
                    param.Add("@SlotID", args.SlotID);
                    param.Add("@User", userContext.GetContext().FullName);
                    param.Add("@Crops", args.Crops);
                    param.Add("@IsSuperUser", args.IsSuperUser);

                });
            return true;

        }

    }
}
