using System.Threading.Tasks;
using Enza.UTM.BusinessAccess.Interfaces;
using Enza.UTM.DataAccess.Data.Interfaces;
using Enza.UTM.Entities.Args;
using System.Net.Http;
using Enza.UTM.Entities.Results;
using System.Data;
using System.Collections.Generic;
using System.IO;
using NPOI.XSSF.UserModel;
using NPOI.SS.UserModel;
using Enza.UTM.Common.Extensions;
using System.Linq;
using Enza.UTM.Services.Abstract;
using System.Configuration;
using log4net;
using System;
using Enza.UTM.Entities;
using Newtonsoft.Json;
using Enza.UTM.Common;
using Enza.UTM.Services.Proxies;
using System.Net;
using Enza.UTM.DataAccess.Interfaces;
using Enza.UTM.Services.EmailTemplates;
using Enza.UTM.Common.Exceptions;

namespace Enza.UTM.BusinessAccess.Services
{
    public class SeedHealthService : ISeedHealthService
    {
        private readonly string BASE_SVC_URL = ConfigurationManager.AppSettings["BasePhenomeServiceUrl"];
        private static readonly ILog _logger = LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);

        private readonly ISeedHealthRepository _seedHealthRepository;
        private readonly ITestService _testService;
        private readonly IEmailService _emailService;
        private readonly IEmailConfigService _emailConfigService;
        private readonly IUserContext _userContext;
        private readonly IDataValidationService _validationService;
        private readonly UELService uelService = new UELService();

        public SeedHealthService(ISeedHealthRepository seedHealthRepository, ITestService testService, IEmailService emailService, IEmailConfigService emailConfigService, IUserContext userContext, IDataValidationService validationService)
        {
            _seedHealthRepository = seedHealthRepository;
            _testService = testService;
            _emailService = emailService;
            _emailConfigService = emailConfigService;
            _userContext = userContext;
            _validationService = validationService;
        }

        public Task<ExcelDataResult> GetDataAsync(SeedHealthGetDataRequestArgs requestArgs)
        {
            return _seedHealthRepository.GetDataAsync(requestArgs);
        }

        public Task<PhenoneImportDataResult> ImportDataAsync(HttpRequestMessage request, SeedHealthRequestArgs args)
        {
            return _seedHealthRepository.ImportDataFromPhenomeAsync(request, args);
           
        }
        public Task AssignMarkersAsync(LFDiskAssignMarkersRequestArgs requestArgs)
        {
            return _seedHealthRepository.AssignMarkersAsync(requestArgs);
        }

        public Task ManageInfoAsync(LeafDiskManageMarkersRequestArgs requestArgs)
        {
            return _seedHealthRepository.ManageInfoAsync(requestArgs);
        }

        public Task<ExcelDataResult> getDataWithDeterminationsAsync(MaterialsWithMarkerRequestArgs args)
        {
            return _seedHealthRepository.getDataWithDeterminationsAsync(args);
        }

        public async Task<ExcelDataResult> GetSampleMaterialAsync(LeafDiskGetDataRequestArgs args)
        {
            return await _seedHealthRepository.GetSampleMaterialAsync(args);
        }

        public async Task<bool> SaveSampleAsync(SaveSampleRequestArgs args)
        {
            return await _seedHealthRepository.SaveSampleAsync(args);
        }

        public async Task<bool> SaveSampleMaterialAsync(SaveSampleLotRequestArgs args)
        {
            return await _seedHealthRepository.SaveSampleMaterialAsync(args);
        }

        public Task<IEnumerable<GetSampleResult>> GetSampleAsync(int testID)
        {
            return _seedHealthRepository.GetSampleAsync(testID);
        }

        //public Task<LeafDiskPunchlist> GetPunchlistAsync(int testID)
        //{
        //    return _leafDiskRepository.GetPunchlistAsync(testID);
        //}
        //public async Task<bool> UpdateMaterialAsync(UpdateMaterialRequestArgs requestArgs)
        //{
        //    return await _seedHealthRepository.UpdateMaterialAsync(requestArgs);
        //}

        public Task<ExcelDataResult> GetSHOverviewAsync(LeafDiskOverviewRequestArgs args)
        {
            return _seedHealthRepository.GetSHOverviewAsync(args);
        }

        public async Task<byte[]> SHOverviewToExcelAsync(int testID)
        {
            var data = await _seedHealthRepository.SHOverviewToExcelAsync(testID);

            //create excel
            var createExcel = CreateExcelFile(data);

            //apply formating 
            //CreateFormatting(createExcel, data.Columns.Count);

            //return created excel
            byte[] result = null;
            using (var ms = new MemoryStream())
            {
                createExcel.Write(ms);
                //ms.Seek(0, SeekOrigin.Begin);
                result = ms.ToArray();
            }
            return result;
        }

        public async Task<byte[]> ExcelForABSAsync(int testID)
        {
            var data = await _seedHealthRepository.ExcelForABSAsync(testID);

            //create excel
            var createExcel = CreateExcelFile(data);

            //apply formating 
            //CreateFormatting(createExcel, data.Columns.Count);

            //return created excel
            byte[] result = null;
            using (var ms = new MemoryStream())
            {
                createExcel.Write(ms);
                //ms.Seek(0, SeekOrigin.Begin);
                result = ms.ToArray();
            }
            return result;
        }

        public async Task<SHSendToABSResponse> SendToABSAsync(int testID)
        {
            await _seedHealthRepository.SendToABSAsync(testID);

            return new SHSendToABSResponse
            {
                Success = true,
                ErrorMsg = ""
            };

        }

        public async Task<bool> SendResult()
        {
            //Before sending result to Phenome a summary calculation should be done.
            LogInfo($"Summary calculation started");
            var dtable = await _seedHealthRepository.ProcessSummaryCalcuationAsync();
            LogInfo($"Summary calculation completed");

            //Log if there is exception for certain test
            foreach (DataRow row in dtable.Rows)
            {
                var id = row["TestID"].ToString();
                var msg = row["ErrorMessage"].ToString();

                var exception = new BusinessException("Unable to calculate summary for Leafdisk, TestID : " + id + " - " + msg);

                uelService.LogError(exception, out string uelId);
                LogInfo($"UEL LogID - {uelId}");
            }

            //Get list of tests eligile for sending result to LIMS
            var tests = await _seedHealthRepository.GetTests();
            var success = true;

            if (tests.Any())
            {

                //singin to pheonome
                using (var client = new RestClient(BASE_SVC_URL))
                {
                    var resp = await _testService.SignInAsync(client);

                    await resp.EnsureSuccessStatusCodeAsync();

                    var loginresp = await resp.Content.DeserializeAsync<PhenomeResponse>();
                    if (loginresp.Status != "1")
                        throw new Exception("Invalid user name or password");

                    LogInfo("logged in to Phenome successful for sending result of Seed health.");
                    foreach (var _test in tests)
                    {
                        try
                        {
                            //var errorIds = new List<int>();
                            var updateLotResult = new UpdateInventoryLotResult();
                            //get data
                            LogInfo($"Getting data for testID {_test.TestID}");

                            var data = await _seedHealthRepository.SHResult(_test.TestID);
                            if (data.Any())
                            {
                                //check conversion missing data with status not equals to 150
                                var conversionMissing = data.Where(x => string.IsNullOrWhiteSpace(x.ColumnLabel) && x.StatusCode != 150);
                                if(conversionMissing.Any())
                                {
                                    //send conversion missing email
                                    var distinctDeterminations1 = conversionMissing.GroupBy(g => new
                                    {
                                        g.DeterminationName,
                                        g.MappingColumn
                                    }).Select(x => new
                                    {
                                        x.Key.DeterminationName,
                                        x.Key.MappingColumn,
                                        SampleType = _test.SampleType
                                    }).ToList();

                                    var cropCode = _test.CropCode;
                                    var testName = _test.TestName;

                                    var tpl = EmailTemplate.GetMissingConversionMail("SH");
                                    var model = new
                                    {
                                        CropCode = cropCode,
                                        TestName = testName,
                                        Determinations = distinctDeterminations1,
                                    };
                                    var body = Template.Render(tpl, model);
                                    //send email to mapped recipients fo this crop
                                    await _validationService.SendEmailAsync(cropCode, body);                                    
                                    await _seedHealthRepository.UpdateTestResultStatusAsync(_test.TestID, string.Join(",", conversionMissing.Select(x => x.SHTestResultID).Distinct().ToList()), 150);
                                    continue;
                                }
                                //get objectID
                                LogInfo($"Get Research group ID using API.");
                                LogInfo($"/api/v1/entity/baseentity/getInfo/{data.FirstOrDefault().FieldID}");
                                var url = $"/api/v1/entity/baseentity/getInfo/{data.FirstOrDefault().FieldID}";
                                var treedata = await client.GetAsync(url);
                                await treedata.EnsureSuccessStatusCodeAsync();
                                var rs = await treedata.Content.ReadAsStringAsync();
                                var json = JsonConvert.DeserializeObject<PhenomeFieldDetailResponse>(rs);
                                var objectID = json.Info.ResearchGroupId.ToText();
                                LogInfo($"Research group ID is {objectID}");

                                var traits = new List<string>();
                                var groupedData = data.GroupBy(x => x.FieldID);
                                foreach (var _groupedData in groupedData)
                                {
                                    //completed = false;
                                    traits.Clear();
                                    var scoreData = _groupedData.ToList();
                                    
                                    if (!scoreData.Any())
                                    {
                                        LogInfo($"No data to sent to Phenome for fieldID {_groupedData.Key}.");
                                        //completed = true;
                                        continue;
                                    }

                                    //get columns of inventories from phenome
                                    var objectType = "5"; // for research group level value is 5 and for folder level value is 4  eg: breeding,NL,FR

                                    updateLotResult = await _seedHealthRepository.UpdateInventoryLotAsync(client, objectType, objectID, scoreData);

                                }

                                if(updateLotResult.ErrorIDs.Any() || updateLotResult.MissingColumns.Any())
                                {
                                    //send email for error updating result if status is not 200 
                                    if(data.Where(x => x.StatusCode < 200).Any())
                                    {
                                        var errorMessage = "";
                                        if (updateLotResult.MissingColumns.Any())
                                        {
                                            updateLotResult.ErrorIDs.AddRange(data.Select(x => x.SHTestResultID));
                                            errorMessage = $"Unable to find Following columns {string.Join(",", updateLotResult.MissingColumns)}";
                                        }                                            
                                        else
                                        {
                                            errorMessage = $"Unable to update record in phenome. Error: {updateLotResult.ErrorMessage}";
                                        }
                                            
                                        await SendErrorEmailAsync(_test, errorMessage);
                                    }

                                    LogInfo($"Logging Test result status 200(error) for SHTestResultIDs {string.Join(",", updateLotResult.ErrorIDs.Select(o => o).Distinct().ToList())}");
                                    //Update Testresult status to 200 (error)
                                    await _seedHealthRepository.UpdateTestResultStatusAsync(_test.TestID, string.Join(",", updateLotResult.ErrorIDs.Select(o => o).Distinct().ToList()), 200);
                                }

                                //if Success then complete the test and send email
                                else
                                {
                                    var determinations = string.Join(",", data.Select(o => o.DeterminationName).Distinct().ToList());
                                    //Send email
                                    await SendTestCompletionEmailAsync(_test, determinations);

                                    LogInfo($"Logging Test result status 300(completed) for SHTestResultIDs {string.Join(",", data.Select(o => o.SHTestResultID).Distinct().ToList())}");
                                    //Update Testresult status to 300 (completed)
                                    await _seedHealthRepository.UpdateTestResultStatusAsync(_test.TestID, string.Join(",", data.Select(o => o.SHTestResultID).Distinct().ToList()), 300);

                                    LogInfo($"Updating test status to 700 for testid {_test.TestID}");
                                    //Update test status to 700(Completed)
                                    await _testService.UpdateTestStatusAsync(new UpdateTestStatusRequestArgs
                                    {
                                        TestId = _test.TestID,
                                        StatusCode = 700
                                    });

                                    LogInfo($"Updating test status to 700 completed.");
                                }
                            }
                            else
                            {
                                //no result
                                //update test status to completed
                            }
                        }
                        catch (Exception e)
                        {
                            LogError(e.Message);
                            success = false;
                        }
                    }
                }
            }

            return success;
        }

        private async Task SendTestCompletionEmailAsync(TestLookup test, string determinations)
        {
            var summary = test.LDResultSummary?.ToLower();

            if (string.IsNullOrWhiteSpace(summary))
            {
                LogInfo($"Invalid summary result {test.LDResultSummary}");
                return;
            }

            var emailNotificationType = summary.Contains("positive") ? EmailConfigGroups.TEST_COMPLETE_POSITIVE : EmailConfigGroups.TEST_COMPLETE_NEGATIVE;

            //get sender
            var from = "lab1@enzazaden.nl";
            var configemails = ConfigurationManager.AppSettings["SH:EmailSender"];
            var email = configemails.Split(';');
            foreach (var _email in email)
            {
                var emailPerSite = _email.Split('|');
                if (emailPerSite.Length == 2)
                {
                    var site = emailPerSite[0];
                    if (test.SiteName.EqualsIgnoreCase(site))
                    {
                        from = emailPerSite[1];
                        break;
                    }

                }
            }
            //email config for email group per site
            var config = await _emailConfigService.GetEmailConfigAsync(emailNotificationType, test.CropCode,test.BreedingStationCode);
            var recipients = config?.Recipients;
            if (string.IsNullOrWhiteSpace(recipients))
            {
                config = await _emailConfigService.GetEmailConfigAsync(emailNotificationType, test.CropCode);
                recipients = config?.Recipients;
                if (string.IsNullOrWhiteSpace(recipients))
                {
                    //get default email
                    config = await _emailConfigService.GetEmailConfigAsync(emailNotificationType, "*");
                    recipients = config?.Recipients;
                }
            }

            if (string.IsNullOrWhiteSpace(recipients))
            {
                LogInfo($"No email recipients found.");
                return;
            }

            var emailList = recipients.Split(new[] { ',', ';' }, StringSplitOptions.RemoveEmptyEntries)
                .Where(o => !string.IsNullOrWhiteSpace(o))
                .Select(o => o.Trim());

            if (emailList.Any())
            {
                LogInfo($"Sending Test completion email of test {test.TestName} to following recipients: {string.Join(",", emailList)}");

                if (summary.EqualsIgnoreCase("positive"))
                {
                    var subject = $"{test.TestName} completed with positive result";
                    var body = $"Dear User,<br/><br/>The Seed Health test {test.TestName} with test {determinations} has changed to completed and the result is positive. Please take the actions needed.<br/><br/>Best Regards,<br/>Seed Health Lab";

                    await _emailService.SendEmailAsync(from, emailList, subject.AddEnv(), body, "high");
                }
                else if (summary.ToLower().Contains("negative"))
                {
                    var subject = $"{test.TestName} completed";
                    var body = $"Dear User,<br/><br/>The Seed Health test {test.TestName} with test {determinations} has changed to completed and the result is negative.<br/><br/>Best Regards,<br/>Seed Health Lab";

                    await _emailService.SendEmailAsync(from, emailList, subject.AddEnv(), body);
                }

                LogInfo($"Sending Test completion email completed.");
            }
        }
        private async Task SendMissingColumnEmailAsync(TestLookup test)
        {

        }

        private async Task SendErrorEmailAsync(TestLookup test, string errorMessage)
        {
            //email config for email group per site
            var config = await _emailConfigService.GetEmailConfigAsync(EmailConfigGroups.TEST_COMPLETE_POSITIVE, test.CropCode, test.BreedingStationCode);
            var recipients = config?.Recipients;
            if (string.IsNullOrWhiteSpace(recipients))
            {
                config = await _emailConfigService.GetEmailConfigAsync(EmailConfigGroups.TEST_COMPLETE_POSITIVE, test.CropCode);
                recipients = config?.Recipients;
                if (string.IsNullOrWhiteSpace(recipients))
                {
                    //get default email
                    config = await _emailConfigService.GetEmailConfigAsync(EmailConfigGroups.TEST_COMPLETE_POSITIVE, "*");
                    recipients = config?.Recipients;
                }
            }

            if (string.IsNullOrWhiteSpace(recipients))
            {
                LogInfo($"No email recipients found.");
                return;
            }

            var emailList = recipients.Split(new[] { ',', ';' }, StringSplitOptions.RemoveEmptyEntries)
                .Where(o => !string.IsNullOrWhiteSpace(o))
                .Select(o => o.Trim());

            if (emailList.Any())
            {
                //get sender
                var from = "lab1@enzazaden.nl";
                var configemails = ConfigurationManager.AppSettings["SH:EmailSender"];
                var email = configemails.Split(';');
                foreach (var _email in email)
                {
                    var emailPerSite = _email.Split('|');
                    if (emailPerSite.Length == 2)
                    {
                        var site = emailPerSite[0];
                        if (test.SiteName.EqualsIgnoreCase(site))
                        {
                            from = emailPerSite[1];
                            break;
                        }

                    }
                }

                LogInfo($"Sending Test error email of test {test.TestName} to following recipients: {string.Join(",", emailList)}");

                var subject = $"Error sending result to phenome for test: {test.TestName}";
               
                var body = $"Dear User,<br/><br/>Please take the actions needef for Seed Health test {test.TestName}.<br/> {errorMessage}.<br/><br/>Best Regards,<br/>Seed Health Lab";

                await _emailService.SendEmailAsync(from, emailList, subject.AddEnv(), body, "high");

                LogInfo($"Sending Test error email completed.");
            }
        }
        public async Task<PrintLabelResult> PrintStickerAsync(SHPrintStickerRequestArgs args)
        {
            //await _seedHealthRepository.PrintStickerAsync(args);
            //get data to print
            var data = await _seedHealthRepository.GetDataToPrintAsync(args);

            //print sticker using bartender
            return await ExecutePrintLabelsAsync(data);
        }

        public async Task<ReceiveSHResultsReceiveResult> ReceiveSHResultsAsync(ReceiveSHResultsRequestArgs args)
        {
            return await _seedHealthRepository.ReceiveSHResultsAsync(args);
        }

        private async Task<PrintLabelResult> ExecutePrintLabelsAsync(IEnumerable<SHDataToPrint> data)
        {
            var labelType = ConfigurationManager.AppSettings["SHPrinterLabelType"];
            if (string.IsNullOrWhiteSpace(labelType))
                throw new Exception("Please specify SHPrinterLabelType LabelType in Config file.");

            var loggedInUser = _userContext.GetContext().Name;
            var credentials = Credentials.GetCredentials();
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
                    Labels = data.Select(o => new
                    {
                        LabelData = new Dictionary<string, string>
                        {
                            {"Article name", o.TestName},
                            {"Determination", o.DeterminationName},
                            {"testID", o.TestID.ToText() },
                            {"SampleName",o.SampleName},
                            {"SampleID",o.SampleID.ToText() },
                            {"ABS test number",""}
                        }
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

        private XSSFWorkbook CreateExcelFile(DataTable data)
        {
            //create workbook 
            var wb = new XSSFWorkbook();
            //create sheet
            var sheet1 = wb.CreateSheet("Sheet1");

            var header = sheet1.CreateRow(0);
            foreach (DataColumn dc in data.Columns)
            {
                var cell = header.CreateCell(dc.Ordinal);
                cell.SetCellValue(dc.ColumnName);
            }
            //create data
            var rowNr = 1;
            foreach (DataRow dr in data.Rows)
            {
                var row = sheet1.CreateRow(rowNr);
                foreach (DataColumn dc in data.Columns)
                {
                    var cell = row.CreateCell(dc.Ordinal);
                    cell.SetCellType(CellType.String);
                    cell.SetCellValue(dr[dc.ColumnName].ToText());
                }
                rowNr++;
            }
            return wb;
        }

        private void LogInfo(string msg)
        {
            Console.WriteLine(msg);
            _logger.Info(msg);
        }
        private void LogError(string msg)
        {
            Console.WriteLine(msg);
            _logger.Error(msg);
        }        
    }
}
