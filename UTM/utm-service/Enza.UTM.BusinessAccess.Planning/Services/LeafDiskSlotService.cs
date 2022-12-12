using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.IO;
using System.Threading.Tasks;
using Enza.UTM.BusinessAccess.Interfaces;
using Enza.UTM.BusinessAccess.Planning.Interfaces;
using Enza.UTM.Common;
using Enza.UTM.Common.Extensions;
using Enza.UTM.DataAccess.Data.Planning.Interfaces;
using Enza.UTM.DataAccess.Interfaces;
using Enza.UTM.Entities;
using Enza.UTM.Entities.Args;
using Enza.UTM.Entities.Results;
using NPOI.SS.UserModel;
using NPOI.XSSF.UserModel;

namespace Enza.UTM.BusinessAccess.Planning.Services
{
    public class LeafDiskSlotService : ILeafDiskSlotService
    {
        private readonly IUserContext _userContext;
        private readonly ILeafDiskSlotRepository _repository;
        private readonly IEmailService _emailService;
        public LeafDiskSlotService(IUserContext userContext, ILeafDiskSlotRepository repository, IEmailService emailService)
        {
            _userContext = userContext;
            _repository = repository;
            _emailService = emailService;
        }

        public async Task<GetAvailSample> GetAvailSampleAsync(GetAvailSampleRequestArgs args)
        {
            return await _repository.GetAvailSampleAsync(args);
        }

        public async Task<SlotLookUp> GetSlotDataAsync(int id)
        {
            return await _repository.GetSlotDataAsync(id);
        }

        public async Task<SlotApprovalResult> UpdateSlotPeriodAsync(UpdateSlotPeriodRequestArgs request)
        {            

            var res = new SlotApprovalResult
            {
                Message = "Slot updated successfully.",
                Success = true
            };
            EmailDataArgs item = null;
            SlotApprovalResult resp1 = new SlotApprovalResult();
            var slotData = await _repository.GetSlotDataAsync(request.SlotID);
            if (slotData != null)
            {
                if (request.PlannedDate != null)
                {
                    if (request.PlannedDate.Value.ToShortDateString() != slotData.PlannedDate.ToShortDateString())
                    {
                        item = await _repository.UpdateSlotPeriodAsync(request);
                    }
                }
                if (request.NrOfTests > 0 && request.NrOfTests != slotData.NrOfTests )
                {
                    resp1 = await EditSlotAsync(new EditSlotRequestArgs
                    {
                        Forced = request.Forced,
                        NrOfTests = request.NrOfTests,
                        SlotID = request.SlotID
                    });
                }

            }

            if (item != null)
                return await SendEmailAsync(item);

            if (!resp1.Success)
            {
                res.Message = resp1.Message;
                res.Success = false;

            };
            return res;
        }
        //public async Task<SlotApprovalResult> ApproveSlotAsync(ApproveSlotRequestArgs requestArgs)
        //{
        //    var item = await _repository.ApproveSlotAsync(requestArgs);
        //    if (item.Success)
        //        return await SendEmailAsync(item);
        //    else
        //    {
        //        return new SlotApprovalResult
        //        {
        //            Success = item.Success,
        //            Message = item.Message
        //        };
        //    }

        //}
        //public async Task<SlotApprovalResult> DenySlotAsync(int SlotID)
        //{
        //    var item = await _repository.DenySlotAsync(SlotID);
        //    return await SendEmailAsync(item);
        //}

        public async Task<DataSet> GetPlannedOverviewAsync(LabOverviewRequestArgs args)
        {
            var result = await _repository.GetPlannedOverviewAsync(args);

            //remove remarks columns on screen query: same query is used for excel export where remark is needed
            if (result.Tables[0].Columns.Contains("Remark"))
                result.Tables[0].Columns.Remove("Remark");

            return result;
        }

        public Task<BreedingOverviewResult> GetBreedingOverviewAsync(BreedingOverviewRequestArgs requestArgs)
        {
            return _repository.GetBreedingOverviewAsync(requestArgs);
        }

        public async Task<SlotApprovalResult> SendEmailAsync(EmailDataArgs args)
        {
            var res = new SlotApprovalResult
            {
                Message = "Error on sending mail",
                Success = false
            };
            var from = ConfigurationManager.AppSettings["LAB:EmailSender"];
            //var userName = LDAP.GetUserName(_userContext.GetContext().FullName);
            //var recipient = LDAP.GetEmail(args.RequestUser);
            var recipient = args.RequestUser;
            var body = string.Empty;
            switch (args.Action)
            {
                case "Approved":
                    body = "Your reservation request (" + args.SlotName + ") for planned " + args.PeriodName + " year " +
                        args.PlannedDate.Year + " is approved.";
                    //body = $"The slot {args.SlotName} for { args.PeriodName}/{args.PlannedDate.Year} has been approved by the lab.";
                    break;
                case "Rejected":
                    body = "Your reservation request (" + args.SlotName + ") for planned " + args.PeriodName + " year " +
                        args.PlannedDate.Year + " is rejected. Please contact the lab.";
                    //body = $"The slot {args.SlotName} for { args.PeriodName}/{args.PlannedDate.Year} has not been approved by the lab.";
                    break;
                case "Changed":
                    body = $"Your reservation request ({args.SlotName}) for Planned {args.PeriodName} year {args.PlannedDate.Year} and Expected {args.ExpectedPeriodName} year {args.ExpectedDate.Year} has been updated and approved: <br>" +
                        $"New Planned date: {string.Format("{0:yyyy-MM-dd}", args.ChangedPlannedDate)} ({args.ChangedPeriodName}  {args.ChangedPlannedDate.Year}) <br>" +
                        $"New Expected date:{string.Format("{0:yyyy-MM-dd}", args.ChangedExpectedDate)} ({args.ChangedExpectedPeriodName}  {args.ChangedPlannedDate.Year})";

                    //body = $"The slot modification {args.SlotName} for { args.PeriodName}/{args.PlannedDate.Year} has been approved by the lab.";
                    break;
            }

            await _emailService.SendEmailAsync(from, new[] { recipient }, "Slot Reservation".AddEnv(), body);

            res.Success = true;
            res.Message = "Email notification sent to " + recipient;
            return res;
        }

        public async Task<SlotApprovalResult> EditSlotAsync(EditSlotRequestArgs args)
        {
            var res = new SlotApprovalResult
            {
                Message = "Slot Updated Successfully.",
                Success = true
            };
            var resp = await _repository.EditSlotAsync(args);
            if (!resp.Success)
            {
                res.Message = resp.Message;
                res.Success = false;
            };
            
            //return message
            return res;
        }

        public async Task<DataTable> GetApprovedSlotsAsync(string userName, string slotName, string crops)
        {
            return await _repository.GetApprovedSlotsAsync(userName, slotName, crops);
        }

        public async Task<byte[]> ExportCapacityPlanningToExcel(BreedingOverviewRequestArgs args)
        {
            var result = await _repository.GetBreedingOverviewAsync(args);

            var rs = result.Data as DataTable;

            //remove unnecessary columns
            if (rs.Columns.Contains("SlotID"))
                rs.Columns.Remove("SlotID");
            if (rs.Columns.Contains("PeriodID"))
                rs.Columns.Remove("PeriodID");
            if (rs.Columns.Contains("TotalRows"))
                rs.Columns.Remove("TotalRows");

            using (var ms = new MemoryStream())
            {
                var book = new XSSFWorkbook();
                var sheet = book.CreateSheet("Sheet1");
                //add header row
                var header = sheet.CreateRow(0);
                for (var i = 0; i < rs.Columns.Count; i++)
                {
                    var column = rs.Columns[i];
                    var cell = header.CreateCell(i);
                    cell.SetCellValue(column.ColumnName);
                }
                //add data rows
                var rowNr = 1;
                foreach (DataRow dr in rs.Rows)
                {
                    var row = sheet.CreateRow(rowNr++);
                    for (var i = 0; i < rs.Columns.Count; i++)
                    {
                        var column = rs.Columns[i];
                        var cell = row.CreateCell(i);
                        cell.SetCellValue(dr[column.ColumnName].ToText());
                    }
                }
                book.Write(ms);

                return ms.ToArray();
            }
        }

        public async Task<byte[]> ExportLabOverviewToExcel(LabOverviewRequestArgs args)
        {
            args.ExportToExcel = true;
            var rs = await _repository.GetPlannedOverviewAsync(args);

            var data = rs.Tables[0];

            using (var ms = new MemoryStream())
            {
                var book = new XSSFWorkbook();
                var sheet = book.CreateSheet("Sheet1");
                //add header row
                var header = sheet.CreateRow(0);
                for (var i = 0; i < data.Columns.Count; i++)
                {
                    var column = data.Columns[i];
                    var cell = header.CreateCell(i);
                    cell.SetCellValue(column.ColumnName);
                }
                //add data rows
                var rowNr = 1;
                foreach (DataRow dr in data.Rows)
                {
                    var row = sheet.CreateRow(rowNr++);
                    for (var i = 0; i < data.Columns.Count; i++)
                    {
                        var column = data.Columns[i];
                        var cell = row.CreateCell(i);
                        cell.SetCellValue(dr[column.ColumnName].ToText());
                    }
                }
                book.Write(ms);

                return ms.ToArray();
            }
        }

        public async Task<DataSet> ReserveCapacityLookupAsync(IEnumerable<string> cropCodes)
        {
            return await _repository.ReserveCapacityLookupAsync(cropCodes);
        }

        public Task<ReserveCapacityResult> ReserveCapacityAsync(ReserveCapacityLFDiskRequestArgs args)
        {
            return _repository.ReserveCapacityAsync(args);
        }
    }
}
