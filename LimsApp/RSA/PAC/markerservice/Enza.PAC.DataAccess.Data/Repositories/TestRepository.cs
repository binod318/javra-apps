using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.IO;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using Enza.PAC.Common;
using Enza.PAC.Common.Exceptions;
using Enza.PAC.Common.Extensions;
using Enza.PAC.DataAccess.Abstract;
using Enza.PAC.DataAccess.Data.Interfaces;
using Enza.PAC.DataAccess.Interfaces;
using Enza.PAC.DataAccess.Services;
using Enza.PAC.DataAccess.Services.Proxies;
using Enza.PAC.Entities;
using Enza.PAC.Entities.Args;
using Enza.PAC.Entities.Results;

namespace Enza.PAC.DataAccess.Data.Repositories
{
    public class TestRepository : Repository<object>, ITestRepository
    {
        private readonly IUserContext userContext;
        public TestRepository(IPACDatabase dbContext, IUserContext userContext) : base(dbContext)
        {
            this.userContext = userContext;
        }

        public Task GenerateFolderDetailsAsync(GenerateFolderDetailsRequestArgs requestArgs)
        {
            return DbContext.ExecuteNonQueryAsync(DataConstants.PR_GENERATE_FOLDER_DETAILS, 
                CommandType.StoredProcedure,
                args => args.Add("@PeriodID", requestArgs.PeriodID));
        }

        public async Task<DataSet> GetDeclusterResultAsync(int periodID, int detAssignmentID)
        {
            var ds = await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_DECLUSTER_RESULT,
                CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@PeriodID", periodID);
                    args.Add("@DetAssignmentID", detAssignmentID);
                });

            ds.Tables[0].TableName = "Data";
            ds.Tables[1].TableName = "Columns";

            return ds;
        }

        public async Task<DataSet> GetFolderDetailsAsync(int periodID)
        {
            var hybridAsParentCrop = ConfigurationManager.AppSettings["HybridAsParentCrop"];
            var ds = await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_FOLDER_DETAILS, 
                CommandType.StoredProcedure, 
                args =>
                {
                    args.Add("@PeriodID", periodID);
                    args.Add("@HybridAsParentCrop", hybridAsParentCrop);
                });

            ds.Tables[0].TableName = "Groups";
            ds.Tables[1].TableName = "Details";

            return ds;
        }

        public async Task<int?> GetMinimumTestStatusPerPeriodAsync(int periodID)
        {
            var data = await DbContext.ExecuteScalarAsync(DataConstants.PR_GET_MIN_TEST_STATUS_PER_PERIOD,
               CommandType.StoredProcedure,
               args =>args.Add("@PeriodID", periodID));

            return data.ToNInt32();
        }

        public async Task<IEnumerable<TestForLIMS>> ReservePlatesInLIMSAsync(int periodID)
        {
            var hybridAsParentCrop = ConfigurationManager.AppSettings["HybridAsParentCrop"];
            var data = await DbContext.ExecuteReaderAsync(DataConstants.PR_GET_TESTINFO_FOR_LIMS,
               CommandType.StoredProcedure,
               args =>
               {
                   args.Add("@PeriodID", periodID);
                   args.Add("@HybridAsParentCrop", hybridAsParentCrop);
               }, reader => new TestForLIMS
               {
                   ContainerType = reader.Get<string>(0),
                   CountryCode = reader.Get<string>(1),
                   CropCode = reader.Get<string>(2),
                   ExpectedDate = reader.Get<string>(3),
                   ExpectedWeek = reader.Get<int?>(4),
                   ExpectedYear = reader.Get<int?>(5),
                   Isolated = reader.Get<string>(6),
                   MaterialState = reader.Get<string>(7),
                   MaterialType = reader.Get<string>(8),
                   PlannedDate = reader.Get<string>(9),
                   PlannedWeek = reader.Get<int?>(10),
                   PlannedYear = reader.Get<int?>(11),
                   Remark = reader.Get<string>(12),
                   RequestID = reader.Get<int>(13),
                   RequestingSystem = reader.Get<string>(14),
                   SynCode = reader.Get<string>(15),
                   TotalPlates = reader.Get<int>(16),
                   TotalTests = reader.Get<int>(17),
               });

            return data;
        }

        public async Task<IEnumerable<FillPlatesInLIMS>> GetInfoForSendToLIMSAsync(int periodID)
        {
            DbContext.CommandTimeout = 300;//5 minutes
            var data = await DbContext.ExecuteReaderAsync(DataConstants.PR_GET_INFO_FOR_FILL_PLATES_IN_LIMS,
               CommandType.StoredProcedure,
               args =>
               {
                   args.Add("@PeriodID", periodID);
               }, reader => new FillPlatesInLIMS
               {
                   LimsPlateplanID = reader.Get<int>(0),
                   RequestID = reader.Get<int>(1),
                   CropCode = reader.Get<string>(2),
                   LimsPlateID = reader.Get<int>(3),
                   LimsPlateName = reader.Get<string>(4),
                   MarkerNr = reader.Get<int>(5),
                   MarkerName = reader.Get<string>(6),
                   PlateColumn = reader.Get<int>(7),
                   PlateRow = reader.Get<string>(8),
                   PlantNr = reader.Get<string>(9),
                   PlantName = reader.Get<string>(10),
                   BreedingStationCode = reader.Get<string>(11)
               });

            return data;
        }

        public async Task<bool> UpdateTestStatusAsync(string testids, int statuscode, int daStatusCode)
        {
            await DbContext.ExecuteDataSetAsync(DataConstants.PR_UPDATE_TEST_STATUS,
                CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@TestIDs", testids);
                    args.Add("@StatusCode", statuscode);
                    args.Add("@DAStatusCode", daStatusCode);
                });

            return true;
        }
        public Task<DataSet> ProcessAllTestResultSummaryAsync()
        {
            var missingResultPercentage = ConfigurationManager.AppSettings["MissingResultPercentage"];
            var qualityThresholdPercentage = ConfigurationManager.AppSettings["QualityThresholdPercentage"];
            var hybridAsParentCrop = ConfigurationManager.AppSettings["HybridAsParentCrop"];

            DbContext.CommandTimeout = 600;
            return DbContext.ExecuteDataSetAsync(DataConstants.PR_PROCESS_ALL_TEST_RESULT_SUMMARY,
               CommandType.StoredProcedure,
               args =>
               {
                   args.Add("@MissingResultPercentage", missingResultPercentage);
                   args.Add("@QualityThresholdPercentage", qualityThresholdPercentage);
                   args.Add("@HybridAsParentCrop", hybridAsParentCrop);
               });

        }

        public async Task<PrintLabelResult> PrintPlateLabelsAsync(PrintPlateLabelRequestArgs requestargs)
        {
            var labels = await DbContext.ExecuteReaderAsync(DataConstants.PR_GET_PLATE_LABELS,
                CommandType.StoredProcedure,
                args =>
                {

                    args.Add("@PeriodID", requestargs.PeriodID);
                    args.Add("@TestID", requestargs.TestID);
                }, reader => new PlateLabel
                {
                    CropCode = reader.Get<string>(0),
                    PlateName = reader.Get<string>(1),
                    PlateNumber = reader.Get<int>(2),
                    Position = reader.Get<string>(3),
                    SampleNr = reader.Get<int>(4)
                });
            var labelType = ConfigurationManager.AppSettings["PrinterLabelType"];
            if (string.IsNullOrWhiteSpace(labelType))
                throw new BusinessException("Please specify LabelType in settings.");
            var loggedInUser = userContext.GetContext().Name;
            var credentials = Credentials.GetCredentials();

            //var mylabels = new List<Dictionary<string, string>>();
            //foreach (var _data in labels.GroupBy(o => o.PlateNumber).Select(p => p))
            //{
            //    var LabelData = new Dictionary<string, string>
            //    {
            //        { "Crop", _data.FirstOrDefault().CropCode },
            //        { "PlateName", _data.FirstOrDefault().PlateName },
            //        { "PlateNr", _data.FirstOrDefault().PlateNumber.ToText() }
            //    };

            //    foreach (var item in _data.Select((value, i) => new { index = i + 1, value }))
            //    {
            //        LabelData.Add("Position" + item.index, item.value.Position);
            //        LabelData.Add("SampleNumber" + item.index, item.value.SampleNr.ToText());
            //    }

            //    //Variable should always be 4 times
            //    var objCount = _data.Count();
            //    for (int i = objCount + 1; i <= 4; i++)
            //    {
            //        LabelData.Add("Position" + i, "");
            //        LabelData.Add("SampleNumber" + i, "");
            //    }

            //    mylabels.Add(LabelData);
            //}

            using (var svc = new BartenderSoapClient
            {
                Url = ConfigurationManager.AppSettings["BartenderServiceUrl"],
                Credentials = new NetworkCredential(credentials.UserName, credentials.Password)
            })
            {
                svc.Model = new
                {
                    User = loggedInUser,
                    LabelType = labelType,
                    Copies = 1,
                    Labels = labels.GroupBy(o => o.PlateNumber).ToList()
                                .Select(group => {
                                    var record = new
                                    {
                                        LabelData = new Dictionary<string, string>
                                        {
                                            { "Crop", group.FirstOrDefault().CropCode },
                                            { "PlateName", group.FirstOrDefault().PlateName },
                                            { "PlateNr", group.FirstOrDefault().PlateNumber.ToText() }
                                        }
                                    };

                                    foreach (var item in group.Select((value, i) => new { index = i + 1, value }))
                                    {
                                        record.LabelData.Add("Position" + item.index, item.value.Position);
                                        record.LabelData.Add("SampleNumber" + item.index, item.value.SampleNr.ToText());
                                    }

                                    //Position1 - Postion4 / SampleNumber1 - SampleNumber4 always should be there in the node. Following loop completes it in case previous loop couldn't complete
                                    var objCount = group.Count();
                                    for (int i = objCount + 1; i <= 4; i++)
                                    {
                                        record.LabelData.Add("Position" + i, "");
                                        record.LabelData.Add("SampleNumber" + i, "");
                                    }

                                    return record;
                                }).ToList()
                };

                var result = await svc.PrintToBarTenderAsync();
                return new PrintLabelResult
                {
                    Success = result.Success,
                    Error = result.Error,
                    PrinterName = labelType
                };
            }
        }

        public async Task<DataSet> GetPlatePlanOverviewAsync(int periodID)
        {
            return await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_PLATES_OVERVIEW,
                CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@PeriodID", periodID);
                });

        }

        public async Task<DataSet> GetBatchOverviewAsync(BatchOverviewRequestArgs requestargs)
        {
            var hybridAsParentCrop = ConfigurationManager.AppSettings["HybridAsParentCrop"];
            //var args = requestargs.Filters as IDictionary<string, object>;
            var ds = await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_BATCH, CommandType.StoredProcedure, args=> {
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
            var dt = ds.Tables[0];
            if (dt.Rows.Count > 0)
            {
                requestargs.TotalRows = dt.Rows[0]["TotalRows"].ToInt32();
                dt.Columns.Remove("TotalRows");
            } 
            return ds;
               
                
            
        }

        public async Task<byte[]> GetDataForExcelAsync(BatchOverviewRequestArgs requestargs)
        {
            var hybridAsParentCrop = ConfigurationManager.AppSettings["HybridAsParentCrop"];

            var ds = await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_BATCH, CommandType.StoredProcedure, args => {
                args.Add("@PageNr", 1);
                args.Add("@PageSize", 1000);
                args.Add("@HybridAsParentCrop", hybridAsParentCrop);
                foreach (var filter in requestargs.Filters)
                {
                    args.Add(filter.Key, filter.Value);
                }
            });
            var dt = ds.Tables[0];
            if (dt.Rows.Count > 0)
            {
                requestargs.TotalRows = dt.Rows[0]["TotalRows"].ToInt32();
                dt.Columns.Remove("TotalRows");
            }
            var columns = ds.Tables[1].AsEnumerable().Select((x, i) => new
            {
                ColumnName = x.Field<string>("ColumnID"),
                ColumnLabel = x.Field<string>("ColumnName"),
                Ordinal = i
            }).ToList();
            //create excel
            var wb = new NPOI.XSSF.UserModel.XSSFWorkbook();
            var sheet1 = wb.CreateSheet("Sheet1");
            //Create header
            var header = sheet1.CreateRow(0);
            foreach (var column in columns)
            {
                var cell = header.CreateCell(column.Ordinal);
                cell.SetCellValue(column.ColumnLabel);
            }

            //write data on excel
            var rowNr = 1;
            foreach (DataRow dr in dt.Rows)
            {
                var row = sheet1.CreateRow(rowNr++);
                foreach (var column in columns)
                {
                    var value = dr[column.ColumnName].ToText();
                    var cell = row.CreateCell(column.Ordinal);
                    cell.SetCellValue(value);
                }
            }
            byte[] result = null;
            using (var ms = new MemoryStream())
            {
                wb.Write(ms, true);
                result = ms.ToArray();
            }
            return result;
        }

        public async Task<IEnumerable<TestInfo>> GetTestsForReservePlates()
        {
            var data = await DbContext.ExecuteReaderAsync(DataConstants.PR_GET_PLATE_LABELS,
                CommandType.StoredProcedure, reader => new TestInfo
                {
                    PeriodID = reader.Get<int>(0),
                    TestID = reader.Get<int>(1)
                });
            
            return data;
        }
    }    
}
