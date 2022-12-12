using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using Enza.PAC.BusinessAccess.Interfaces;
using Enza.PAC.Common;
using Enza.PAC.Common.Extensions;
using Enza.PAC.DataAccess.Data.Interfaces;
using Enza.PAC.DataAccess.Interfaces;
using Enza.PAC.DataAccess.Services;
using Enza.PAC.DataAccess.Services.Proxies;
using Enza.PAC.Entities;
using Enza.PAC.Entities.Args;
using Enza.PAC.Entities.Results;
using log4net;

namespace Enza.PAC.BusinessAccess.Services
{
    public class TestService : ITestService
    {
        private static readonly ILog _logger =
           LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);
        private readonly ITestRepository _testRepository;
        private readonly IUserContext userContext;

        public TestService(IUserContext userContext, ITestRepository testRepository)
        {
            this.userContext = userContext;
            _testRepository = testRepository;
        }

        public Task GenerateFolderDetailsAsync(GenerateFolderDetailsRequestArgs requestArgs)
        {
            return _testRepository.GenerateFolderDetailsAsync(requestArgs);
        }

        public async Task<JsonResponse> GetDeclusterResultAsync(int periodID, int detAssignmentID)
        {
            var data = await _testRepository.GetDeclusterResultAsync(periodID, detAssignmentID);
            return new JsonResponse
            {
                Data = data
            };
        }

        public async Task<JsonResponse> GetFolderDetailsAsync(int periodID)
        {
            var ds = await _testRepository.GetFolderDetailsAsync(periodID);
            int? testStatusCode = null;
            int? daStatusCode = null;
            int? totalUsed = null;
            int? totalResered = null;

            if (ds.Tables[2].Rows.Count > 0)
                testStatusCode = ds.Tables[2].Rows[0]["TestStatusCode"].ToNInt32();
            if (ds.Tables[3].Rows.Count > 0)
                daStatusCode = ds.Tables[3].Rows[0]["DAStatusCode"].ToNInt32();
            if (ds.Tables[4].Rows.Count > 0)
                totalUsed = ds.Tables[4].Rows[0]["TotalUsed"].ToNInt32();
            if (ds.Tables[5].Rows.Count > 0)
                totalResered = ds.Tables[5].Rows[0]["TotalReserved"].ToNInt32();

            return new JsonResponse
            {
                Data = new
                {
                    Groups = ds.Tables[0],
                    Details = ds.Tables[1],
                    TestStatusCode = testStatusCode,
                    DAStatusCode = daStatusCode,
                    TotalUsed = totalUsed,
                    TotalReserved = totalResered
                }
            };
        }

        public async Task<int?> GetMinimumTestStatusPerPeriodAsync(int periodID)
        {
            return await _testRepository.GetMinimumTestStatusPerPeriodAsync(periodID);
        }

        public async Task<bool> ReservePlatesInLIMSAsync(int periodID)
        {
            var isSuccess = true;
            var data = await _testRepository.ReservePlatesInLIMSAsync(periodID);

            var count = data.Count();

            if (count == 0)
            {
                return isSuccess;
            }

            _logger.Info($"Total number of tests to reserve : {count}");

            var successTestIds = await ExecuteReservePlatesServiceAsync(data, 0);

            _logger.Info($"Total number of tests reserved : {successTestIds.Count()}");

            return isSuccess;

            //foreach (var _data in data)
            //{
            //    var result = await ExecuteReservePlatesServiceAsync(_data);
            //    if (!result.Success)
            //        return false;

            //    testList = testList + "," + _data.RequestID;
            //}

            ////Update test status to 200(PlateRequested)
            //var dt = await _testRepository.UpdateTestStatusAsync(testList.Trim(','), 200, 0);
            //if (!dt)
            //    return false;

            //return true;
        }

        public async Task<bool> SendToLIMSAsync(int periodID, int delay)
        {
            var isSuccess = true;
            var data = await _testRepository.GetInfoForSendToLIMSAsync(periodID);

            var count = data.GroupBy(o => o.RequestID).Count();

            if (count == 0)
            {
                _logger.Info($"There are no information to send to LIMS");
                return isSuccess;
            }

            _logger.Info($"Total number of tests to send to LIMS : {count}");

            var successTestIds = await ExecuteFillPlatesInLIMSAsync(data, delay);

            _logger.Info($"Total number of tests sent to LIMS : {successTestIds.Count()}");

            return isSuccess;
        }

        private async Task<List<int>> ExecuteReservePlatesServiceAsync(IEnumerable<TestForLIMS> data, int delay)
        {
            var credentials = Credentials.GetCredentials();
            using (var svc = new LimsServiceSoapClient
            {
                Url = ConfigurationManager.AppSettings["LimsServiceUrl"],
                Credentials = new NetworkCredential(credentials.UserName, credentials.Password)
            })
            {
                var testList = new List<int>();

                var user = userContext.GetContext().Name;

                if (string.IsNullOrWhiteSpace(user))
                    user = "PacUser";

                foreach (var folder in data)
                {
                    _logger.Info("ReservePlates started for TestID : " + folder.RequestID);

                    svc.Model = new
                    {
                        folder.ContainerType,
                        folder.CountryCode,
                        folder.CropCode,
                        folder.ExpectedDate,
                        folder.ExpectedWeek,
                        folder.ExpectedYear,
                        folder.Isolated,
                        folder.MaterialState,
                        folder.MaterialType,
                        folder.PlannedDate,
                        folder.PlannedWeek,
                        folder.PlannedYear,
                        folder.Remark,
                        folder.RequestID,
                        folder.RequestingSystem,
                        RequestingUserID = user,
                        RequestingUserName = user,
                        SynCode = folder.SynCode.ToUpper(),
                        folder.TotalPlates,
                        folder.TotalTests
                    };

                    var result = await svc.ReservePlatesInLIMSAsync();

                    if (!result.Success)
                    {
                        _logger.Error($"Reserve plates failed for TestID : {folder.RequestID} with error {result.Error}");

                        await Task.Delay(delay);
                        continue;
                    }

                    testList.Add(folder.RequestID);

                    _logger.Info($"Reserve plates completed for TestID : {folder.RequestID}");

                    //Update test status to 200(Reserved)
                    _logger.Info($"Update test status to 200 for TestID(s) : {folder.RequestID}");

                    var dt = await _testRepository.UpdateTestStatusAsync(folder.RequestID.ToText(), 200, 0);
                    if (!dt)
                        _logger.Error($"Update test status failed for TestID(s) : {folder.RequestID}");
                    else
                        _logger.Info($"Update test status completed for TestID(s) : {folder.RequestID}");

                    //Wait for few seconds before second call is done.
                    await Task.Delay(delay);
                }

                return testList;
            }
        }

        private async Task<List<int>> ExecuteFillPlatesInLIMSAsync(IEnumerable<FillPlatesInLIMS> data, int delay)
        {
            var credentials = Credentials.GetCredentials();
            using (var svc = new LimsServiceSoapClient
            {
                Url = ConfigurationManager.AppSettings["LimsServiceUrl"],
                Credentials = new NetworkCredential(credentials.UserName, credentials.Password)
            })
            {
                var testList = new List<int>();

                //group data by testid
                var groups = data.GroupBy(o => o.RequestID);

                //Loop service call in one instance of httpclient because it is an effecient way
                foreach (var group in groups)
                {
                    _logger.Info("Send to LIMS started for TestID : " + group.Key);

                    var items = group.ToList();

                    //prepare model
                    var plates = items.GroupBy(g => new { g.LimsPlateID })
                        .Select(o => new Plate
                        {
                            LimsPlateID = o.Key.LimsPlateID,
                            LimsPlateName = o.FirstOrDefault().LimsPlateName,
                            Wells = o.Where(x => x.LimsPlateID == o.Key.LimsPlateID).GroupBy(y => new { y.PlateRow, y.PlateColumn }).Select(w => new Well
                            {
                                PlateColumn = w.Key.PlateColumn,
                                PlateRow = w.Key.PlateRow,
                                PlantNr = w.FirstOrDefault().PlantNr,
                                PlantName = w.FirstOrDefault().PlantName,
                                BreedingStationCode = w.FirstOrDefault().BreedingStationCode
                            }).ToList(),
                            Markers = o.Where(x => x.LimsPlateID == o.Key.LimsPlateID).GroupBy(y => y.MarkerNr).Select(m => new Marker
                            {
                                MarkerNr = m.Key,
                                MarkerName = m.FirstOrDefault().MarkerName
                            }).ToList()
                        }).ToList();

                    var rs = new FillPlatesInLIMSService
                    {
                        CropCode = items.FirstOrDefault().CropCode,
                        LimsPlatePlanID = items.FirstOrDefault().LimsPlateplanID,
                        RequestID = items.FirstOrDefault().RequestID,
                        Plates = plates
                    };

                    svc.Model = rs;
                    var result = await svc.FillPlatesInLimsAsync();

                    if (!result.Success)
                    {
                        _logger.Error($"Send to LIMS failed for TestID : {group.Key} with error {result.Error}");

                        await Task.Delay(delay);
                        continue;
                    }

                    testList.Add(group.Key);

                    _logger.Info($"Send to LIMS completed for TestID : {group.Key}");

                    //Update test status to 400(Sent to LIMS)
                    _logger.Info($"Update test status to 400 for TestID(s) : {group.Key}");

                    var dt = await _testRepository.UpdateTestStatusAsync(group.Key.ToText(), 400, 400);
                    if (!dt)
                        _logger.Error($"Update test status failed for TestID(s) : {group.Key}");
                    else
                        _logger.Info($"Update test status completed for TestID(s) : {group.Key}");

                    //Wait for few seconds before second call is done.
                    await Task.Delay(delay);
                }

                return testList;

            }
        }
        public Task<DataSet> ProcessAllTestResultSummaryAsync()
        {
            return _testRepository.ProcessAllTestResultSummaryAsync();
        }

        public async Task<PrintLabelResult> PrintPlateLabelsAsync(PrintPlateLabelRequestArgs args)
        {
            return await _testRepository.PrintPlateLabelsAsync(args);
        }

        public async Task<byte[]> GetPlatePlanOverviewAsync(int periodID)
        {
            var ds =  await _testRepository.GetPlatePlanOverviewAsync(periodID);
            var path = System.Web.Hosting.HostingEnvironment.MapPath("~/Reports/PlatePlanPerWeek.rdl");
            using (var rpt = new PdfReport(path))
            {
                rpt.AddDataSource(ds.Tables[0]);
                var pdfBytes = rpt.SaveAs();
                return pdfBytes;                
            }

        }

        public Task<DataSet> GetBatchOverviewAsync(BatchOverviewRequestArgs args)
        {
            return _testRepository.GetBatchOverviewAsync(args);
        }

        public Task<byte[]> GetDataForExcelAsync(BatchOverviewRequestArgs args)
        {
            return _testRepository.GetDataForExcelAsync(args);
        }

        public async Task<bool> AutomateReservePlatesAsync()
        {
            //Get Tests to reserve
            var data = await _testRepository.ReservePlatesInLIMSAsync(0);

            var count = data.GroupBy(o => o.RequestID).Count();

            if (count == 0)
                return true;

            _logger.Info($"Total number of tests to reserve : {count}");

            var successTestIds = await ExecuteReservePlatesServiceAsync(data, 0);

            _logger.Info($"Total number of tests reserved : {successTestIds.Count()}");

            return true;
        }
    }
}
