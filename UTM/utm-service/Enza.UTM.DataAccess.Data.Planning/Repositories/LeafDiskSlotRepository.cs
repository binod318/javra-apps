using System;
using System.Data;
using System.Linq;
using System.Threading.Tasks;
using Enza.UTM.DataAccess.Abstract;
using Enza.UTM.DataAccess.Data.Planning.Interfaces;
using Enza.UTM.DataAccess.Interfaces;
using Enza.UTM.Entities.Args;
using Enza.UTM.Entities.Results;
using Enza.UTM.Common.Extensions;
using Enza.UTM.Entities;
using Enza.UTM.Common;
using System.Net.Mail;
using System.Net;
using System.Collections.Generic;
using Enza.UTM.Entities.Args.Abstract;

namespace Enza.UTM.DataAccess.Data.Planning.Repositories
{
    public class LeafDiskSlotRepository : Repository<object>, ILeafDiskSlotRepository
    {
        private readonly IUserContext userContext;
        public LeafDiskSlotRepository(IDatabase dbContext, IUserContext userContext) : base(dbContext)
        {
            this.userContext = userContext;
        }

        public async Task<GetAvailSample> GetAvailSampleAsync(GetAvailSampleRequestArgs request)
        {
            var p1 = DbContext.CreateOutputParameter("@DisplayPlannedWeek", DbType.String, 100);
            var p2 = DbContext.CreateOutputParameter("@AvailSample", DbType.Int32);

            await DbContext.ExecuteReaderAsync(DataConstants.PR_LFDISK_PLAN_GET_AVAIL_TESTS,
                CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@TestProtocolID", request.TestProtocolID);
                    args.Add("@PlannedDate", request.PlannedDate.ToDateTime());
                    args.Add("@SiteID", request.SiteID);
                    args.Add("@DisplayPlannedWeek", p1);
                    args.Add("@AvailPlates", p2);
                });

            var data = new GetAvailSample();
            data.DisplayPlannedWeek = p1.Value.ToString();
            if (int.TryParse(p2.Value.ToString(), out var availSample))
                data.AvailSample = availSample;
            else
                data.AvailSample = 0;
            return data;

        }

        public async Task<SlotLookUp> GetSlotDataAsync(int id)
        {
            var data = await DbContext.ExecuteReaderAsync(DataConstants.PR_LFDISK_GET_SLOT_DATA, CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@SlotID", id);
                }, reader => new SlotLookUp()
                {
                    SlotID = reader.Get<int>(0),
                    SlotName = reader.Get<string>(1),
                    BreedingStationCode = reader.Get<string>(2),
                    CropCode = reader.Get<string>(3),
                    RequestUser = reader.Get<string>(4),
                    TestType = reader.Get<string>(5),
                    MaterialType = reader.Get<string>(6),
                    MaterialState = reader.Get<string>(7),
                    Isolated = reader.Get<bool>(8),
                    TestProtocolName = reader.Get<string>(9),
                    NrOfTests = reader.Get<int>(10),
                    PlannedDate = reader.Get<DateTime>(11),
                    ExpectedDate = reader.Get<DateTime>(12)
                });

            return data.FirstOrDefault();
        }

        public async Task<EmailDataArgs> UpdateSlotPeriodAsync(UpdateSlotPeriodRequestArgs request)
        {
            var data = await DbContext.ExecuteReaderAsync(DataConstants.PR_LFDISK_CHANGE_SLOT, CommandType.StoredProcedure,
               args =>
               {
                   args.Add("@SlotID", request.SlotID);
                   args.Add("@PlannedDate", request.PlannedDate);
               }, reader => new EmailDataArgs
               {
                   ReservationNumber = reader.Get<string>(0),
                   SlotName = reader.Get<string>(1),
                   PeriodName = reader.Get<string>(2),
                   ChangedPeriodName = reader.Get<string>(3),
                   PlannedDate = reader.Get<DateTime>(4),
                   ChangedPlannedDate = reader.Get<DateTime>(5),
                   RequestUser = reader.Get<string>(6),
                   TestTypeID = reader.Get<int>(7),
                   SiteName = reader.Get<string>(8),
                   Action = "Changed"             
               });
            return data.FirstOrDefault();
        }

        
        
        //public async Task<ApproveSlotResult> ApproveSlotAsync(ApproveSlotRequestArgs requestArgs)
        //{
        //    //logic to approve request here
        //    var p1 = DbContext.CreateOutputParameter("@IsSuccess", DbType.Boolean);
        //    var p2 = DbContext.CreateOutputParameter("@Message", DbType.String, 2000);
        //    var data = await DbContext.ExecuteReaderAsync(DataConstants.PR_PLAN_APPROVE_SLOT, CommandType.StoredProcedure,
        //       args =>
        //       {
        //           args.Add("@SlotID", requestArgs.SlotID);

        //       }, reader => new ApproveSlotResult
        //       {
        //           ReservationNumber = reader.Get<string>(0),
        //           SlotName = reader.Get<string>(1),
        //           PeriodName = reader.Get<string>(2),
        //           ChangedPeriodName = reader.Get<string>(3),
        //           PlannedDate = reader.Get<DateTime>(4),
        //           ChangedPlannedDate = reader.Get<DateTime>(5),
        //           RequestUser = reader.Get<string>(6),
        //           Action = "Approved"
        //       });
        //    var result = data.FirstOrDefault();
        //    result.Success = true;
        //    return result;


        //    //if(result !=null && Convert.ToBoolean(p1?.Value))
        //    //{
        //    //    return result;

        //    //}
        //    //else
        //    //{
        //    //    return new ApproveSlotResult
        //    //    {
        //    //        Message = p2.Value.ToString(),
        //    //        Success = false
        //    //    };
                
        //    //}
           
        //    //send email
        //    //return await SendMail(data.FirstOrDefault());
        //}


        //public async Task<EmailDataArgs> DenySlotAsync(int SlotID)
        //{
        //    //logic to approve request here
        //    var data = await DbContext.ExecuteReaderAsync(DataConstants.PR_PLAN_REJECT_SLOT, CommandType.StoredProcedure,
        //       args =>
        //       {
        //           args.Add("@SlotID", SlotID);
        //       }, reader => new EmailDataArgs
        //       {
        //           ReservationNumber = reader.Get<string>(0),
        //           SlotName = reader.Get<string>(1),
        //           PeriodName = reader.Get<string>(2),
        //           ChangedPeriodName = reader.Get<string>(3),
        //           PlannedDate = reader.Get<DateTime>(4),
        //           ChangedPlannedDate = reader.Get<DateTime>(5),
        //           RequestUser = reader.Get<string>(6),
        //           Action = "Rejected"

        //       });
        //    return data.FirstOrDefault();
        //    //send email
        //    //return await SendMail(data.FirstOrDefault());
        //}

        public async Task<DataSet> GetPlannedOverviewAsync(LabOverviewRequestArgs reqArgs)
        {
            var result = await DbContext.ExecuteDataSetAsync(DataConstants.PR_LFDISK_GET_PLANNED_OVERVIEW,
                CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@Year", reqArgs.Year);
                    args.Add("@PeriodID", reqArgs.PeriodID);
                    args.Add("@SiteID", reqArgs.SiteID);
                    args.Add("@Filter", reqArgs.ToFilterString());
                    args.Add("@ExportToExcel", reqArgs.ExportToExcel);
                });

            result.Tables[0].TableName = "Data";
            result.Tables[1].TableName = "Columns";
            return result;
        }

        

        public async Task<BreedingOverviewResult> GetBreedingOverviewAsync(BreedingOverviewRequestArgs requestArgs)
        {
            var ds = await DbContext.ExecuteDataSetAsync(DataConstants.PR_LFDISK_GET_SLOTS_FOR_BREEDER,
                CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@CropCode", requestArgs.CropCode);
                    args.Add("@BrStationCode", requestArgs.BrStationCode);
                    args.Add("@Page", requestArgs.PageNumber);
                    args.Add("@PageSize", requestArgs.PageSize);
                    args.Add("@Filter", requestArgs.ToFilterString());
                    //args.Add("@ColumnRequired", requestArgs.ExportToExcel);
                    args.Add("@ExportToExcel", requestArgs.ExportToExcel);
                });

            var result = new BreedingOverviewResult();
            if (ds.Tables.Count > 0)
            {
                var table0 = ds.Tables[0];
                if (table0.Columns.Contains("TotalRows"))
                {
                    if (table0.Rows.Count > 0)
                    {
                        result.Total = table0.Rows[0]["TotalRows"].ToInt32();
                    }
                    table0.Columns.Remove("TotalRows");
                }
                result.Data = table0;
            }
            return result;
        }

        public async Task<EditSlotResult> EditSlotAsync(EditSlotRequestArgs args)
        {
            var p1 = DbContext.CreateOutputParameter("@Message", DbType.String, 2000);
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_LFDISK_EDIT_SLOT,
                CommandType.StoredProcedure, param =>
                {
                    param.Add("@SlotID", args.SlotID);
                    param.Add("@NrOfTests", args.NrOfTests);
                    param.Add("@PlannedDate", args.PlannedDate);
                    param.Add("@Forced", args.Forced);
                    param.Add("@Message", p1);
                });
            return new EditSlotResult
            {
                Success = string.IsNullOrWhiteSpace(p1.Value.ToText()) ? true : false,
                Message = p1.Value.ToText(),
                Data = data
            };
        }
        
        public async Task<DataTable> GetApprovedSlotsAsync(string userName, string slotName, string crops)
        {
            var ds = await DbContext.ExecuteDataSetAsync(DataConstants.PR_LFDISK_GET_APPROVED_SLOTS,
                CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@UserName", userName);
                    args.Add("@SlotName", slotName);
                    args.Add("@Crops", crops);
                });
            return ds.Tables[0];
        }

        public async Task<DataSet> ReserveCapacityLookupAsync(IEnumerable<string> cropCodes)
        {            
            var crops = string.Join(",", cropCodes);
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_LFDISK_GETRESERVECAPACITYLOOKUP, CommandType.StoredProcedure, args=>
            {
                args.Add("@Crops", crops);
            });
            data.Tables[0].TableName = "BreedingStation";
            data.Tables[1].TableName = "TestType";
            data.Tables[2].TableName = "MaterialType";
            data.Tables[3].TableName = "TestProtocol";
            data.Tables[4].TableName = "CurrentPeriod";
            data.Tables[5].TableName = "Columns";
            data.Tables[6].TableName = "Crop";
            data.Tables[7].TableName = "SiteLocation";
            return data;
        }

        public async Task<ReserveCapacityResult> ReserveCapacityAsync(ReserveCapacityLFDiskRequestArgs args)
        {
            var p1 = DbContext.CreateOutputParameter("@IsSuccess", DbType.Boolean);
            var p2 = DbContext.CreateOutputParameter("@Message", DbType.String, 2000);
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_LFDISK_RESERVE_CAPACITY,
                CommandType.StoredProcedure, param =>
                {
                    param.Add("@BreedingStationCode", args.BreedingStationCode);
                    param.Add("@CropCode", args.CropCode);
                    param.Add("@TestTypeID", args.TestTypeID);
                    param.Add("@MaterialTypeID", args.MaterialTypeID);
                    param.Add("@PlannedDate", args.PlannedDate);
                    param.Add("@TestProtocolID", args.ProtocolID);
                    param.Add("@NrOfSample", args.NrOfSample);
                    param.Add("@User", userContext.GetContext().FullName);
                    param.Add("@Forced", args.Forced);
                    param.Add("@Remark", args.Remark);
                    param.Add("@SiteID", args.SiteID);
                    param.Add("@IsSuccess", p1);
                    param.Add("@Message", p2);
                });
            return new ReserveCapacityResult
            {
                Success = Convert.ToBoolean(p1.Value),
                Message = p2.Value.ToString()
            };
        }

    }
}
