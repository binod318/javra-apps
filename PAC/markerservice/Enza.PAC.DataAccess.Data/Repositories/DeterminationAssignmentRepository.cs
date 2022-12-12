using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Globalization;
using System.Linq;
using System.Net;
using System.Runtime.Caching;
using System.Threading.Tasks;
using Enza.PAC.Common;
using Enza.PAC.Common.Exceptions;
using Enza.PAC.Common.Extensions;
using Enza.PAC.DataAccess.Abstract;
using Enza.PAC.DataAccess.Data.Interfaces;
using Enza.PAC.DataAccess.Interfaces;
using Enza.PAC.DataAccess.Services.Proxies;
using Enza.PAC.Entities.Args;
using Enza.PAC.Entities.Results;

namespace Enza.PAC.DataAccess.Data.Repositories
{
    public class DeterminationAssignmentRepository : Repository<object>, IDeterminationAssignmentRepository
    {
        readonly IUserContext _userContext;
        public DeterminationAssignmentRepository(IPACDatabase dbContext, IUserContext userContext) : base(dbContext)
        {
            _userContext = userContext.GetContext();
        }

        public async Task<JsonResponse> GetDeterminationAssignmentsAsync(GetDeterminationAssignmentsRequestArgs requestArgs)
        {
            var hybridAsParentCrop = ConfigurationManager.AppSettings["HybridAsParentCrop"];
            var tvp = ABSServiceSoapClient.GetTVPDeterminationAssignment();
            if (requestArgs.IncludeUnplanned)
            {
                //get unplanned data from ABS service call and pass into parameter of storedprocedure.
                tvp = await GetAssignmentsFromABSAsync(new GetABSAssignmentsRequestArgs
                {
                    StartDate = requestArgs.StartDate,
                    EndDate = requestArgs.EndDate
                });

                //Cache unplanned items for use in automatic planning
                var cache = MemoryCache.Default;
                var key = $"DET_{_userContext.Name}";

                if (cache.Contains(key))
                    cache.Remove(key);

                cache.Add(key, tvp, new CacheItemPolicy
                {
                    AbsoluteExpiration = DateTimeOffset.Now.AddMinutes(10)
                });
            }
            //get UTM database name from connection string specified in web.config
            DbContext.CommandTimeout = 180;
            var p1 = DbContext.CreateOutputParameter("@InvalidIDs", DbType.String, 256); //output varaible for Invalid DeterminationAssignments
            var p2 = DbContext.CreateOutputParameter("@TotalUsed", DbType.Decimal ); //output varaible for Invalid DeterminationAssignments
            p2.Precision = 10;
            p2.Scale = 2;
            var p3 = DbContext.CreateOutputParameter("@TotalReserved", DbType.Decimal); //output varaible for Invalid DeterminationAssignments
            p3.Precision = 10;
            p3.Scale = 2;
            var ds = await DbContext.ExecuteDataSetAsync(DataConstants.PR_PAC_GET_DETERMINATION_ASSIGNMENTS,
                CommandType.StoredProcedure, args =>
                {
                    args.Add("@PeriodID", requestArgs.PeriodID);
                    args.Add("@DeterminationAssignment", tvp);
                    args.Add("@HybridAsParentCrop", hybridAsParentCrop);
                    args.Add("@InvalidIDs", p1);
                    args.Add("@TotalUsed", p2);
                    args.Add("@TotalReserved", p3);
                });
            ds.Tables[0].TableName = "Groups"; 
            ds.Tables[1].TableName = "Details";

            var result = new JsonResponse
            {
                Data = new
                {
                    Groups = ds.Tables[0],
                    Details = ds.Tables[1],
                    TotalUsed = p2.Value.ToDecimal32(),
                    TotalReserved = p3.Value.ToDecimal32()
                },
                Message = p1.Value.ToText()
            };

            return result;
        }

        public async Task<DataTable> GetAssignmentsFromABSAsync(GetABSAssignmentsRequestArgs requestArgs)
        {
            var rs = new GetDeterminationAssignmentsServiceRequest
            {
                PageNumber = 1,
                PageSize = 99999,
                Planner = "PAC",
                StatusCode = "1"
            };
            var dt = await ExecuteGetDeterminationAssignmentAsync(rs);
            return dt;
        }

        public async Task<DataTable> ConfirmPlanningAsync(ConfirmPlanningRequestArgs requestArgs)
        {
            var weekDifference = ConfigurationManager.AppSettings["ExpWeekDifference"];
            var weekDifferenceLab = ConfigurationManager.AppSettings["ExpWeekDifferenceLab"];
            var maxPlatesPerFolder = ConfigurationManager.AppSettings["MaxPlatesPerFolder"];
            var hybridAsParentCrop = ConfigurationManager.AppSettings["HybridAsParentCrop"];
            var dataAsJson = requestArgs.Details.Select(x => new
            {
                x.DetAssignmentID,
                x.MethodCode,
                x.ABSCropCode,
                x.SampleNr,
                PlannedDate = x.PlannedDate.ToSqlDateTime(),
                UtmostInlayDate = x.UtmostInlayDate.ToSqlDateTime(),
                ExpectedReadyDate = x.ExpectedReadyDate.ToSqlDateTime(),
                x.PriorityCode,
                x.BatchNr,
                x.RepeatIndicator,
                x.VarietyNr,
                x.Process,
                x.ProductStatus,
                x.Remarks,
                x.IsLabPriority,
                x.Action
            }).ToJson();
            var ds = await DbContext.ExecuteDataSetAsync(DataConstants.PR_PAC_CONFIRM_PLANNING,
               CommandType.StoredProcedure, args =>
               {
                   args.Add("@PeriodID", requestArgs.PeriodID);
                   args.Add("@ExpWeekDifference", weekDifference);
                   args.Add("@ExpWeekDifferenceLab", weekDifferenceLab);
                   args.Add("@MaxPlatesInFolder", maxPlatesPerFolder);
                   args.Add("@DataAsJson", dataAsJson);
                   args.Add("@HybridAsParentCrop", hybridAsParentCrop);
               });
            if (ds.Tables.Count > 0)
                return ds.Tables[0];

            return null;
        }

        public async Task PlanDeterminationAssignmentsAsync(AutomaticalPlanRequestArgs requestArgs)
        {
            //Retrieve data from cache
            var cache = MemoryCache.Default;
            var key = $"DET_{_userContext.Name}"; 

            DataTable tvp = null;
            if (cache.Contains(key))
            {
                tvp = cache.Get(key) as DataTable;
            }
            if (tvp == null)
            {
                //get unplanned data from ABS service call and pass into parameter of storedprocedure.
                tvp = await GetAssignmentsFromABSAsync(new GetABSAssignmentsRequestArgs
                {
                    StartDate = requestArgs.StartDate,
                    EndDate = requestArgs.EndDate
                });
            }
            var weekDifference = ConfigurationManager.AppSettings["ExpWeekDifference"];
            var hybridAsParentCrop = ConfigurationManager.AppSettings["HybridAsParentCrop"];
            DbContext.CommandTimeout = 180;
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_PLAN_AUTO_DETERMINATION_ASSIGNMENTS,
               CommandType.StoredProcedure, args =>
               {
                   args.Add("@PeriodID", requestArgs.PeriodID);
                   args.Add("@ExpWeekDifference", weekDifference);
                   args.Add("@ABSData", tvp);
                   args.Add("@HybridAsParentCrop", hybridAsParentCrop);
               });
        }

        public async Task<bool> DeclusterAsync()
        {
            var hybridAsParentCrop = ConfigurationManager.AppSettings["HybridAsParentCrop"];

            DbContext.CommandTimeout = 300;
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_IGNITE_DECLUSTER, CommandType.StoredProcedure, args =>
            {
                args.Add("@HybridAsParentCrop", hybridAsParentCrop);
            });
            return true;
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Performance", "CA1822:Mark members as static", Justification = "<Pending>")]
        private async Task<DataTable> ExecuteGetDeterminationAssignmentAsync(GetDeterminationAssignmentsServiceRequest data)
        {
            var credentials = Credentials.GetCredentials();
            using (var svc = new ABSServiceSoapClient
            {
                Url = ConfigurationManager.AppSettings["ABSServiceUrlGet"],
                Credentials = new NetworkCredential(credentials.UserName, credentials.Password)
            })
            {
                svc.Model = data;
                return await svc.GetDeterminationAssignmentAsync();
            }
        }

        public async Task<DataSet> GetDAOverviewAsync(BatchOverviewRequestArgs requestargs)
        {
            var hybridAsParentCrop = ConfigurationManager.AppSettings["HybridAsParentCrop"];
            var ds = await DbContext.ExecuteDataSetAsync(DataConstants.PR_PAC_GET_DETERMINATION_ASSIGNMENTS_OVERVIEW, CommandType.StoredProcedure, args => {
                args.Add("@PageNr", requestargs.PageNr);
                args.Add("@PageSize", requestargs.PageSize);
                args.Add("@HybridAsParentCrop", hybridAsParentCrop);
                args.Add("@SortBy", requestargs.SortBy);
                args.Add("@SortOrder", requestargs.SortOrder);
                foreach (var filter in requestargs.Filters)
                {
                    args.Add(filter.Key, filter.Value);
                }
            });
            var dt = ds.Tables[1];
            if (dt.Rows.Count > 0)
            {
                requestargs.TotalRows = dt.Rows[0]["TotalRows"].ToInt32();
                dt.Columns.Remove("TotalRows");
            }
            return ds;
        }

        public async Task<IEnumerable<DeterminationAssignment>> GetDAForStatusUpdateAsync(GetDAOverviewRequestArgs requestArgs)
        {
            var data = await DbContext.ExecuteReaderAsync(DataConstants.PR_PAC_GET_DETERMINATION_ASSIGNMENTS_FOR_SETABS,
               CommandType.StoredProcedure,
               args => args.Add("@PeriodID", requestArgs.PeriodID),
               reader => new DeterminationAssignment
               {
                   DetAssignmentID = reader.Get<int>(0),
                   ProductStatus = reader.Get<int>(1),
                   ExpectedReadyDate = reader.Get<string>(2)
               });

            return data;
        }

        public async Task<DataSet> GetDataForDecisionScreenAsync(int id)
        {
            var qualityThresholdPercentage = ConfigurationManager.AppSettings["QualityThresholdPercentage"];

            var ds = await DbContext.ExecuteDataSetAsync(DataConstants.PR_PAC_GET_DATA_FOR_DECISION_SCREEN,
                CommandType.StoredProcedure, args =>
                {
                    args.Add("@DetAssignmentID", id);
                    args.Add("@QualityThresholdPercentage", qualityThresholdPercentage);
                });
            ds.Tables[0].TableName = "TestInfo";
            ds.Tables[1].TableName = "DetAssignmentInfo";
            ds.Tables[2].TableName = "ResultInfo";
            ds.Tables[3].TableName = "ValidationInfo";
            ds.Tables[4].TableName = "VarietyInfoData";
            ds.Tables[5].TableName = "VarietyInfoColumn";
            return ds;
        }

        public async Task<DataSet> GetDataForDecisionDetailScreenAsync(GetDataForDecisionDetailRequestArgs requestArgs)
        {
            var ds = await DbContext.ExecuteDataSetAsync(DataConstants.PR_PAC_GET_DATA_FOR_DECISIONDETAIL_SCREEN,
                CommandType.StoredProcedure, args =>
                {
                    args.Add("@DetAssignmentID", requestArgs.DetAssignmentID);
                    args.Add("@SortBy", requestArgs.SortBy);
                    args.Add("@SOrtOrder", requestArgs.SortOrder);
                });
            ds.Tables[0].TableName = "Detail";
            ds.Tables[1].TableName = "Columns";
            return ds;
        }
        public async Task<DataSet> GetPlatesAndPositionsForPatternAsync(int id)
        {
            var ds = await DbContext.ExecuteDataSetAsync(DataConstants.PR_PAC_GET_PLATES_AND_POSITIONS_FOR_PATTERN,
                CommandType.StoredProcedure, args =>
                {
                    args.Add("@PatternID", id);
                });
            ds.Tables[0].TableName = "Detail";
            ds.Tables[1].TableName = "Columns";
            return ds;
        }

        public async Task<bool> SavePatternRemarksAsync(List<UpdatePatternRemarksRequestArgs> requestArgs)
        {
            var ds = await DbContext.ExecuteDataSetAsync(DataConstants.PR_UPDATE_PATTERN_REMARKS,
                CommandType.StoredProcedure, args =>
                {
                    args.Add("@Json", requestArgs.ToJson());
                });
            return true;
        }

        public async Task<bool> SendResultToABSAsync(SendResultToABSRequestArgs requestArgs)
        {
            var hybridAsParentCrop = ConfigurationManager.AppSettings["HybridAsParentCrop"];

            var data = await DbContext.ExecuteReaderAsync(DataConstants.PR_GET_INFO_FOR_UPDATE_DA,
                CommandType.StoredProcedure, args =>
                {
                    args.Add("@DetAssignmentID", requestArgs.ID);
                    args.Add("@HybridAsParentCrop", hybridAsParentCrop);
                },
                reader => new UpdateDAArgs
                {
                    DetAssignmentID = reader.Get<int>(0),
                    ValidatedOn = reader.Get<string>(1),
                    ResultPercentage = reader.Get<decimal>(2),
                    QualityClass = reader.Get<int>(3),
                    ValidatedBy = reader.Get<string>(4),
                    NrOfWells = reader.Get<int>(5),
                    NrOfInbreds = reader.Get<int>(6),
                    NrOfDeviating = reader.Get<int>(7),
                    Remarks = reader.Get<string>(8),
                    SendToABS = reader.Get<int>(9),
                });

            //when calculation per criteria record for crop is present for hyb/parent then skip sending to ABS because
            //for such data background calculation is skipped and result is not there
            if (data.FirstOrDefault().SendToABS == 0)
                return true;

            return await ExecuteUpdateDAAsync(data.FirstOrDefault());

        }

        private async Task<bool> ExecuteUpdateDAAsync(UpdateDAArgs data)
        {
            if (string.IsNullOrWhiteSpace(data.ValidatedOn))
            {
                data.ValidatedOn = DateTime.UtcNow.ToString("yyyy-MM-dd", new CultureInfo("en-US"));
                data.ValidatedBy = _userContext.Name;
            }

            var credentials = Credentials.GetCredentials();
            using (var svc = new ABSServiceSoapClient
            {
                Url = ConfigurationManager.AppSettings["ABSServiceUrlSet"],
                Credentials = new NetworkCredential(credentials.UserName, credentials.Password)
            })
            {
                var appUrl = ConfigurationManager.AppSettings["ApplicationUrl"];
                //var daResult = new List<DAResult>
                //{ 
                //    new DAResult
                //    {
                //        Result = 1, ReplicateNumber = 0, ApprovedBy = data.ValidatedBy, DeterminationCode = data.QualityClass
                //    }
                //};
                //var determinationAssignment = new List<DADetail>
                //{
                //    new DADetail
                //    {
                //        DetAssignmentID = data.DetAssignmentID,
                //        Remarks = $"{appUrl}/lab_result/{data.DetAssignmentID}",
                //        Result = 1,
                //        ApprovedDate = data.ValidatedOn,
                //        ResultPercentage = data.ResultPercentage,
                //        Results = daResult
                //    }
                //};

                svc.Model = new
                {
                    Username = credentials.UserName.Split('\\')[1],
                    DeterminationAssignments = new[]
                    {
                        new
                        {
                            data.DetAssignmentID,
                            data.NrOfWells,
                            data.NrOfInbreds,
                            data.NrOfDeviating,
                            Remarks = $"{appUrl}/lab_result/{data.DetAssignmentID} - {data.Remarks}",
                            Results = new[]
                            {
                                new
                                {
                                    Percentage = data.ResultPercentage,
                                    ResultCode = data.QualityClass
                                }
                            }
                        }
                    }
                };

                var result = await svc.UpdateDAAsync();

                if (result.Message.EqualsIgnoreCase("S"))
                    return true;
                else
                    throw new BusinessException(result.Message);
            }
        }

        public async Task<bool> ApproveDeterminationAsync(int detAssignmentID)
        {
            var request = new SendResultToABSRequestArgs() { ID = detAssignmentID };
            var response = await SendResultToABSAsync(request);
            if (!response)
                return false;

            //Update determination status only if success sending result to ABS
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_APPROVE_DETERMINATION, CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@ID", detAssignmentID);
                    args.Add("@User", _userContext.Name);
                }
                );
            return true;

        }
        public async Task<bool> RetestDetAssignmentAsync(int detAssignmentID)
        {
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_RETEST_DETERMINATION, CommandType.StoredProcedure, args => args.Add("@ID", detAssignmentID));
            return true;
        }

        public async Task<bool> UpdateRemarksAsync(UpdateRemarksRequestArgs requestargs)
        {
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_UPDATE_REMARKS, CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@DetAssignmentID", requestargs.DetAssignmentID);
                    args.Add("@Remarks", requestargs.Remarks);
                });
            return true;
        }

    }
}
