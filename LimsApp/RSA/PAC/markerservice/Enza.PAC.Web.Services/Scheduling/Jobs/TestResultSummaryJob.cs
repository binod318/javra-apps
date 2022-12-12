using Enza.PAC.BusinessAccess.Interfaces;
using Enza.PAC.BusinessAccess.Services;
using Enza.PAC.Common.Exceptions;
using Enza.PAC.Common.Handlers;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights.Extensibility;
using Quartz;
using System;
using System.Configuration;
using System.Data;
using System.Threading.Tasks;

namespace Enza.PAC.Web.Services.Scheduling.Jobs
{
    [DisallowConcurrentExecution]
    public class TestResultSummaryJob : IJob
    {
        private readonly UELService uelService = new UELService();
        private readonly ITestService _testService;
        public TestResultSummaryJob(ITestService testService)
        {
            _testService = testService;
        }
        public async Task Execute(IJobExecutionContext context)
        {
            //Initialize Telemetry Initializer
            TelemetryConfiguration.Active.ConnectionString = ConfigurationManager.AppSettings["AIConnectionString"];
            TelemetryConfiguration.Active.TelemetryInitializers.Add(new CustomRequestResponseInitializer());

            //Initialize Telemetry Processor
            var telemetrybuilder = TelemetryConfiguration.Active.DefaultTelemetrySink.TelemetryProcessorChainBuilder;
            telemetrybuilder.Use((next) => new SuccessfulDependencyFilter(next));
            telemetrybuilder.Build();

            var telemetryClient = new TelemetryClient();

            try
            {
                using (var operation = telemetryClient.StartOperation<RequestTelemetry>("SummaryCalculation"))
                {
                    var ds = await _testService.ProcessAllTestResultSummaryAsync();

                    //run completed without error
                    if (ds.Tables[0].Rows.Count == 0)
                        telemetryClient.TrackTrace("Summary calculation completed for all batches without error.");

                    //Log if there is exception for certain test/determinationid
                    foreach (DataRow row in ds.Tables[0].Rows)
                    {
                        var id = row["DetAssignmentID"].ToString();
                        var msg = row["ErrorMessage"].ToString();

                        var exception = new BusinessException("DetAssignmentID : " + id + " - " + msg);

                        telemetryClient.TrackTrace("DetAssignmentID : " + id + " - " + msg);

                        uelService.LogError(exception, out _);
                    }
                }

                // Explicitly call Flush() followed by sleep is required in Console Apps.
                // This is to ensure that even if application terminates, telemetry is sent to the back-end.
                telemetryClient.Flush();
                await Task.Delay(5000);
            }
            catch (Exception ex)
            {
                telemetryClient.TrackException(ex);

                uelService.LogError(ex, out _);
            }
        }
    }
}