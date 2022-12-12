using System.Threading.Tasks;
using Enza.UTM.BusinessAccess.Interfaces;
using Enza.UTM.DataAccess.Data.Interfaces;
using Enza.UTM.Entities.Args;
using System.Net.Http;
using Enza.UTM.Entities.Results;
using System.Data;
using System.Collections.Generic;
using Enza.UTM.Entities.Args.Abstract;
using System.IO;
using NPOI.XSSF.UserModel;
using NPOI.SS.UserModel;
using Enza.UTM.Common.Extensions;
using NPOI.SS.Util;
using Enza.UTM.Entities;
using System.Configuration;
using System;
using Enza.UTM.DataAccess.Interfaces;
using Enza.UTM.Common;
using Enza.UTM.Services.Proxies;
using System.Net;
using System.Linq;

namespace Enza.UTM.BusinessAccess.Services
{
    public class LeafDiskService : ILeafDiskService
    {
        private readonly ILeafDiskRepository _leafDiskRepository;
        private readonly IUserContext userContext;

        public LeafDiskService(ILeafDiskRepository leafDiskRepository, IUserContext userContext)
        {
            _leafDiskRepository = leafDiskRepository;
            this.userContext = userContext;
        }

        public Task<ExcelDataResult> GetDataAsync(LeafDiskGetDataRequestArgs requestArgs)
        {
            return _leafDiskRepository.GetDataAsync(requestArgs);
        }

        public async Task<DataTable> GetConfigurationListAsync(string crops)
        {
            return await _leafDiskRepository.GetConfigurationListAsync(crops);
        }

        public async Task<bool> SaveConfigurationNameAsync(SaveSampleConfigurationRequestArgs args)
        {
            return await _leafDiskRepository.SaveConfigurationNameAsync(args);
        }

        public Task<PhenoneImportDataResult> ImportDataAsync(HttpRequestMessage request, LeafDiskRequestArgs args)
        {
            return _leafDiskRepository.ImportDataFromPhenomeAsync(request, args);
        }

        public async Task<PhenoneImportDataResult> ImportDataFromConfigurationAsync(LDImportFromConfigRequestArgs args)
        {
            return await _leafDiskRepository.ImportDataFromConfigurationAsync(args);
        }

        public Task AssignMarkersAsync(LFDiskAssignMarkersRequestArgs requestArgs)
        {
            return _leafDiskRepository.AssignMarkersAsync(requestArgs);
        }

        public Task ManageInfoAsync(LeafDiskManageMarkersRequestArgs requestArgs)
        {
            return _leafDiskRepository.ManageInfoAsync(requestArgs);
        }

        public Task<ExcelDataResult> getDataWithDeterminationsAsync(MaterialsWithMarkerRequestArgs args)
        {
            return _leafDiskRepository.getDataWithDeterminationsAsync(args);
        }

        public async Task<ExcelDataResult> GetSampleMaterialAsync(LeafDiskGetDataRequestArgs args)
        {
            return await _leafDiskRepository.GetSampleMaterialAsync(args);
        }

        public async Task<bool> SaveSampleAsync(SaveSampleRequestArgs args)
        {
            return await _leafDiskRepository.SaveSampleAsync(args);
        }

        public async Task<bool> SaveSampleMaterialAsync(SaveSamplePlotRequestArgs args)
        {
            return await _leafDiskRepository.SaveSampleMaterialAsync(args);
        }

        public Task<IEnumerable<GetSampleResult>> GetSampleAsync(int testID)
        {
            return _leafDiskRepository.GetSampleAsync(testID);
        }

        public Task<LeafDiskPunchlist> GetPunchlistAsync(int testID)
        {
            return _leafDiskRepository.GetPunchlistAsync(testID);
        }

        public async Task<PrintLabelResult> GetPrintLabelsAsync(int testID)
        {
            var labels = await _leafDiskRepository.GetPrintLabelsAsync(testID);
            return await ExecutePrintLabelsAsync(labels);
        }

        private async Task<PrintLabelResult> ExecutePrintLabelsAsync(IEnumerable<PlateLabelLeafDisk> data)
        {
            var labelType = ConfigurationManager.AppSettings["LeafDiskPrinterLabelType"];
            if (string.IsNullOrWhiteSpace(labelType))
                throw new Exception("Please specify Leafdisk LabelType in settings.");

            var loggedInUser = userContext.GetContext().Name;
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
                            {"CropSampleName", o.CropCode + "-" + o.SampleName}
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

        public async Task<bool> UpdateMaterialAsync(UpdateMaterialRequestArgs requestArgs)
        {
            return await _leafDiskRepository.UpdateMaterialAsync(requestArgs);
        }

        public Task<ExcelDataResult> GetLeafDiskOverviewAsync(LeafDiskOverviewRequestArgs args)
        {
            return _leafDiskRepository.GetLeafDiskOverviewAsync(args);
        }

        public async Task<byte[]> LeafDiskOverviewToExcelAsync(int testID)
        {
            var data = await _leafDiskRepository.LeafDiskOverviewToExcelAsync(testID);

            //create excel
            var createExcel = CreateExcelFile(data);

            //apply formating 
            if (data.Columns.Count > 1)
                CreateFormatting(createExcel, data.Columns.Count);

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

        private void CreateFormatting(XSSFWorkbook wb, int columnCount)
        {
            var sheet1 = wb.GetSheetAt(0);

            //add formating
            XSSFSheetConditionalFormatting sCF = (XSSFSheetConditionalFormatting)sheet1.SheetConditionalFormatting;

            var dict = ColorForValue();
            foreach (var _dict in dict)
            {
                var a = "\"" + _dict.Key + "\"";
                XSSFConditionalFormattingRule cf1 =
                (XSSFConditionalFormattingRule)sCF.CreateConditionalFormattingRule(ComparisonOperator.Equal, a);

                XSSFPatternFormatting fill = (XSSFPatternFormatting)cf1.CreatePatternFormatting();
                fill.FillBackgroundColor = _dict.Value;
                fill.FillPattern = FillPattern.SolidForeground;
                //apply colouring from second column because first column contains sampleName
                CellRangeAddress[] cfRange1 = { new CellRangeAddress(0, sheet1.LastRowNum, 1, columnCount - 1) };
                sCF.AddConditionalFormatting(cfRange1, cf1);
            }
        }

        private Dictionary<string, short> ColorForValue()
        {
            var dict = new Dictionary<string, short>();
            dict.Add("3", IndexedColors.Red.Index); //3 is positive result
            dict.Add("1", IndexedColors.Green.Index); //1 is negative result
            return dict;

        }

        public async Task<LDRequestSampleTestResult> LDRequestSampleTestAsync(TestRequestArgs requestArgs)
        {
            return await _leafDiskRepository.LDRequestSampleTestAsync(requestArgs);
        }

        public async Task<ReceiveLDResultsReceiveResult> ReceiveLDResultsAsync(ReceiveLDResultsRequestArgs args)
        {
            return await _leafDiskRepository.ReceiveLDResultsAsync(args);
        }

        public async Task<DataSet> ProcessSummaryCalcuationAsync()
        {
            return await _leafDiskRepository.ProcessSummaryCalcuationAsync();
        }
    }
}
