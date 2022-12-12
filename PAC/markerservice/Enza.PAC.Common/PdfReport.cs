using System;
using System.Collections;
using System.Collections.Generic;
using System.Data;
using System.Text;
using Microsoft.Reporting.WebForms;
using System.IO;
using Enza.PAC.Common.Extensions;

namespace Enza.PAC.Common
{
    public sealed class PdfReport : IDisposable
    {
        private readonly LocalReport _report;

        public PdfReport(string fileName)
        {
            _report = new LocalReport
            {
                ReportPath = fileName
            };
            Parameters = new List<ReportParameter>();
        }

        public List<ReportParameter> Parameters { get; set; }

        public void AddParameter(string name, string value)
        {
            Parameters.Add(new ReportParameter(name, value));
        }

        public void AddDataSource(IEnumerable dataSource, string dataSetName = "DataSet1")
        {
            var ds = new ReportDataSource(dataSetName, dataSource);
            _report.DataSources.Add(ds);
        }

        public void AddDataSource(DataTable dataSource, string dataSetName = "DataSet1")
        {
            var ds = new ReportDataSource(dataSetName, dataSource);
            _report.DataSources.Add(ds);
        }

        public byte[] SaveAs(string extension = "pdf")
        {
            Warning[] warnings;
            string[] streams;
            string mimeType;
            string encoding;
            string fileNameExtension;

            var reportType = "pdf";
            string deviceInfo = GetDeviceInfo(reportType);
            //Set parameters before render
            if (Parameters.Count > 0)
            {
                _report.SetParameters(Parameters);
            }
            //Render the report
            var pdfBytes = _report.Render(reportType, deviceInfo, out mimeType, out encoding, out fileNameExtension,
                out streams, out warnings);
            return pdfBytes;
        }

        /// <summary>
        /// Use this method before calling AddDataSource Method.
        /// </summary>
        /// <param name="callback"></param>
        public void ProcessSubReport(SubreportProcessingEventHandler callback)
        {
            _report.SubreportProcessing -= callback;
            _report.SubreportProcessing += callback;
        }

        #region Private Methods

        private string GetDeviceInfo(string reportType = "PDF")
        {
            if (reportType.EqualsIgnoreCase("PDF"))
            {
                var sb = new StringBuilder("<DeviceInfo>");
                sb.Append("<OutputFormat>PDF</OutputFormat>");
                sb.Append("</DeviceInfo>");
                return sb.ToString();
            }
            return string.Empty;
        }

        #endregion
        public void Dispose()
        {
            if (_report != null)
                _report.Dispose();
        }
    }
}

