using Enza.PAC.Common;
using Enza.PAC.Common.Exceptions;
using Enza.PAC.Common.Extensions;
using Enza.PAC.DataAccess.Services.Abstract;
using Enza.PAC.Entities.Args;
using Enza.PAC.Entities.Results;
using Microsoft.ApplicationInsights;
using System;
using System.Data;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;

namespace Enza.PAC.DataAccess.Services.Proxies
{
    public class ABSServiceSoapClient : SoapClient
    {
        public object Model { get; set; }

        public static DataTable GetTVPDeterminationAssignment()
        {
            #region TVP Preparation

            var tvp = new DataTable("TVP_DeterminationAssignment");
            tvp.Columns.Add("DetAssignmentID", typeof(int));
            tvp.Columns.Add("SampleNr", typeof(int));
            tvp.Columns.Add("PriorityCode", typeof(int));
            tvp.Columns.Add("MethodCode", typeof(string));
            tvp.Columns.Add("ABSCropCode", typeof(string));
            tvp.Columns.Add("VarietyNr", typeof(int));
            tvp.Columns.Add("BatchNr", typeof(int));
            tvp.Columns.Add("RepeatIndicator", typeof(bool));
            tvp.Columns.Add("Process", typeof(string));
            tvp.Columns.Add("ProductStatus", typeof(string));
            tvp.Columns.Add("Remarks", typeof(string));
            tvp.Columns.Add("PlannedDate", typeof(DateTime));
            tvp.Columns.Add("UtmostInlayDate", typeof(DateTime));
            tvp.Columns.Add("ExpectedReadyDate", typeof(DateTime));
            tvp.Columns.Add("ReceiveDate", typeof(DateTime));
            tvp.Columns.Add("ReciprocalProd", typeof(bool));
            tvp.Columns.Add("BioIndicator", typeof(bool));
            tvp.Columns.Add("LogicalClassificationCode", typeof(string));
            tvp.Columns.Add("LocationCode", typeof(string));
            tvp.Columns.Add("IsLabPriority", typeof(bool));

            #endregion

            return tvp;
        }

        public async Task<DataTable> GetDeterminationAssignmentAsync()
        {
            // Log Dependency telemetry
            var actionName = "http://www.agrosolutions.nl/QualityConnect/20170301/IABSQualityConnectEnza/GetDeterminationAssignment";
            var response = "";
            var isSuccess = false;
            var startTime = DateTime.UtcNow;
            var timer = System.Diagnostics.Stopwatch.StartNew();
            try
            {
                var tpl = typeof(ABSServiceSoapClient).Assembly.GetString(
                "Enza.PAC.DataAccess.Services.Requests.GetDeterminationAssignmentRequest.st");
                var body = Template.Render(tpl, Model);
                response = await ExecuteAsync(actionName, body);

                XNamespace ns = "http://schemas.agrosolutions.nl/QualityConnect/20170301";

                var doc = XDocument.Parse(response);
                var errorMessage = doc.Descendants(ns + "ErrorMessage").FirstOrDefault()?.Value;

                if (!string.IsNullOrWhiteSpace(errorMessage))
                {
                    response = errorMessage;
                    throw new SoapException(errorMessage);
                }

                var tvp = GetTVPDeterminationAssignment();
                var items = doc.Descendants(ns + "GetDeterminationAssignment");
                var allowedPriorities = new int[] { 0, 1, 2, 3, 4 };

                tvp.BeginLoadData();
                foreach (var x in items)
                {
                    //get data based on only allowed priorities
                    var priorityCode = x.Element(ns + "Prio").Value.ToInt32();
                    if (!allowedPriorities.Contains(priorityCode))
                        continue;

                    var dr = tvp.NewRow();
                    dr["DetAssignmentID"] = x.Element(ns + "DeterminationAssignment").Value.ToInt32();
                    dr["SampleNr"] = x.Element(ns + "Sample").Value.ToInt32();
                    dr["PriorityCode"] = x.Element(ns + "Prio").Value.ToInt32();
                    dr["MethodCode"] = x.Element(ns + "MethodCode").Value;
                    dr["ABSCropCode"] = x.Element(ns + "ABScrop").Value;
                    dr["VarietyNr"] = x.Element(ns + "VarietyNumber").Value.ToInt32();
                    dr["BatchNr"] = x.Element(ns + "BatchNumber").Value.ToInt32();
                    dr["RepeatIndicator"] = x.Element(ns + "RepeatIndicator").Value.ToUBoolean();
                    dr["Process"] = x.Element(ns + "Process").Value;
                    dr["ProductStatus"] = x.Element(ns + "ProductStatus").Value;
                    dr["Remarks"] = x.Element(ns + "Remarks").Value;
                    dr["PlannedDate"] = DateTime.Today;
                    dr["UtmostInlayDate"] = x.Element(ns + "UtmostInlayDate").Value.ToDateTimeOrDbNull();
                    dr["ExpectedReadyDate"] = x.Element(ns + "ExpectedReadyDate").Value.ToDateTimeOrDbNull();
                    dr["ReceiveDate"] = x.Element(ns + "ReceiveDate").Value.ToDateTimeOrDbNull();
                    dr["ReciprocalProd"] = x.Element(ns + "ReciprocalProd").Value.ToUBoolean();
                    dr["BioIndicator"] = x.Element(ns + "BioIndicator").Value.ToUBoolean();
                    dr["LogicalClassificationCode"] = x.Element(ns + "LogicalClassificationCode").Value;
                    dr["LocationCode"] = x.Element(ns + "LocationCode").Value;
                    dr["IsLabPriority"] = false;
                    tvp.Rows.Add(dr);
                }
                tvp.EndLoadData();

                return tvp;
            }
            finally
            {
                timer.Stop();

                response = !string.IsNullOrEmpty(response) ? response
                           : (StatusCode == 0) ? "Unable to get response from server." //This is the case of request timeout
                           : (StatusCode == 401) ? "Unauthorized" //Unauthorized exception
                           : "Failed"; // Other exceptions
                StatusCode = (StatusCode == 0) ? 500 : StatusCode; // If no statuscode then fill 500

                if (StatusCode == 200)
                    isSuccess = true;

                var data = Model.ToJson() + "|||" + response;
                var telemetryClient = new TelemetryClient();
                telemetryClient.TrackDependency("HTTP", Url, actionName, data, startTime, timer.Elapsed, StatusCode.ToString(), isSuccess);
            }            
        }

        public async Task<UpdateDeterminationStatusCodeResult> UpdateDeterminationStatusCodeAsync()
        {
            // Log Dependency telemetry
            var actionName = "http://www.agrosolutions.nl/ABSConnect/2017/01/01/ABSConnectService/Quality_Connect";
            var response = "";
            var isSuccess = false;
            var startTime = DateTime.UtcNow;
            var timer = System.Diagnostics.Stopwatch.StartNew();

            try
            {
                var tpl = typeof(ABSServiceSoapClient).Assembly.GetString(
                "Enza.PAC.DataAccess.Services.Requests.UpdateDeterminationStatusCode.st");
                var body = Template.Render(tpl, Model);
                response = await ExecuteAsync(actionName, body);
                XNamespace ns = "http://www.agrosolutions.nl/ABSConnect/2017/01/01";

                var doc = XDocument.Parse(response);

                var data = doc.Descendants(ns + "Quality_ConnectResult").Select(x => new UpdateDeterminationStatusCodeResult
                {
                    ABSConnectTransactionID = x.Element(ns + "ABS_connect_transaction_id") == null ? 0 : x.Element(ns + "ABS_connect_transaction_id").Value.ToInt32(),
                    GuID = x.Element(ns + "Guid") == null ? 0 : x.Element(ns + "Guid").Value.ToInt32(),
                    Message = x.Element(ns + "Message")?.Value
                }).FirstOrDefault();

                return data;
            }
            finally
            {
                timer.Stop();

                response = !string.IsNullOrEmpty(response) ? response
                           : (StatusCode == 0) ? "Unable to get response from server." //This is the case of request timeout
                           : (StatusCode == 401) ? "Unauthorized" //Unauthorized exception
                           : "Failed"; // Other exceptions
                StatusCode = (StatusCode == 0) ? 500 : StatusCode; // If no statuscode then fill 500

                if (StatusCode == 200)
                    isSuccess = true;

                var data = Model.ToJson() + "|||" + response;
                var telemetryClient = new TelemetryClient();
                telemetryClient.TrackDependency("HTTP", Url, actionName, data, startTime, timer.Elapsed, StatusCode.ToString(), isSuccess);
            }
        }

        public async Task<UpdateDAResult> UpdateDAAsync()
        {
            // Log Dependency telemetry
            var actionName = "http://www.agrosolutions.nl/ABSConnect/2017/01/01/ABSConnectService/Quality_Connect";
            var response = "";
            var isSuccess = false;
            var startTime = DateTime.UtcNow;
            var timer = System.Diagnostics.Stopwatch.StartNew();

            try
            {
                var tpl = typeof(ABSServiceSoapClient).Assembly.GetString("Enza.PAC.DataAccess.Services.Requests.UpdateDARequest.st");

                var body = Template.Render(tpl, Model, new CultureInfo("en-US"));

                response = await ExecuteAsync(actionName, body);

                XNamespace ns = "http://www.agrosolutions.nl/ABSConnect/2017/01/01";
                var doc = XDocument.Parse(response);
                var data = doc.Descendants(ns + "Quality_ConnectResult")
                    .Select(x => new UpdateDAResult
                    {
                        ABSConnectTransactionID = x.Element(ns + "ABS_connect_transaction_id").Value.ToInt32(),
                        Message = x.Element(ns + "Message").Value
                    }).FirstOrDefault();

                return data;
            }
            finally
            {
                timer.Stop();

                response = !string.IsNullOrEmpty(response) ? response
                           : (StatusCode == 0) ? "Unable to get response from server." //This is the case of request timeout
                           : (StatusCode == 401) ? "Unauthorized" //Unauthorized exception
                           : "Failed"; // Other exceptions
                StatusCode = (StatusCode == 0) ? 500 : StatusCode; // If no statuscode then fill 500

                if (StatusCode == 200)
                    isSuccess = true;

                var data = Model.ToJson() + "|||" + response;
                var telemetryClient = new TelemetryClient();
                telemetryClient.TrackDependency("HTTP", Url, actionName, data, startTime, timer.Elapsed, StatusCode.ToString(), isSuccess);
            }
        }
    }
}
