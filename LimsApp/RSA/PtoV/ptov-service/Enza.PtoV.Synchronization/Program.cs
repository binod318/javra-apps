using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Autofac;
using Enza.PtoV.BusinessAccess.Interfaces;
using Enza.PtoV.Common;
using Enza.PtoV.Common.Extensions;
using log4net;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights.Extensibility;

namespace Enza.PtoV.Synchronization
{
    class Program
    {
        private static readonly ILog _logger =
            LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);
        private static IContainer Container { get; set; }
        static int Main(string[] args)
        {
            try
            {
                log4net.Config.XmlConfigurator.Configure();

                var builder = new ContainerBuilder();
                AutofacConfig.Register(builder);
                Container = builder.Build();

                // Initialize Telemetry Initializer
                TelemetryConfiguration.Active.ConnectionString = ConfigurationManager.AppSettings["AIConnectionString"];
                TelemetryConfiguration.Active.TelemetryInitializers.Add(new CustomRequestResponseInitializer());

                //Initialize Telemetry Processor
                var telemetrybuilder = TelemetryConfiguration.Active.DefaultTelemetrySink.TelemetryProcessorChainBuilder;
                telemetrybuilder.Use((next) => new SuccessfulDependencyFilter(next));
                telemetrybuilder.Build();

                var telemetryClient = new TelemetryClient();
                using (var operation = telemetryClient.StartOperation<RequestTelemetry>("PtoVSync"))
                {


                    using (var scope = Container.BeginLifetimeScope())
                    {
                        var success = AsyncHelper.RunSync(async () =>
                        {
                            var syncService = scope.Resolve<ISynchronizationService>();
                            var emalConfigService = scope.Resolve<IEmailConfigService>();
                            var emailService = scope.Resolve<IEmailService>();

                            var response = await syncService.SyncGermplasmsAsync();
                            var emailTriggerTime = TimeSpan.Parse(ConfigurationManager.AppSettings["ErrorEmailTriggerTime"]);
                            var scheduleInterval = ConfigurationManager.AppSettings["ScheduleInterval"].ToInt32();

                        //check if execution is happening withn specified time
                        var today = DateTime.Now;
                            var from = today.Date.Add(emailTriggerTime);
                            var to = from.AddMinutes(scheduleInterval + 1);//add additional 1 minutes so that event should not be missed
                        if (today >= from && today <= to)
                            {
                                var dataErrors = response
                                .Where(x => !x.Success && x.ErrorType.EqualsIgnoreCase("data"))
                                .GroupBy(x => x.CropCode);
                                foreach (var dataError in dataErrors)
                                {
                                    var errors = dataError.ToList();
                                    await SendDataErrorMailAsync(emalConfigService, emailService, errors);
                                }
                            }

                            var exceptionError = response.Where(x => !x.Success && x.ErrorType.EqualsIgnoreCase("exception"));
                            if (exceptionError.Any())
                            {
                            //send error mail with log file attached.
                            var root = Path.Combine(Environment.CurrentDirectory, "Logs");
                                var logFile = _logger.GetLogCurrentFile(root);
                                await SendErrorEmailAsync(emalConfigService, emailService, logFile);
                            }
                            return !response.Any();
                        });

                        // Explicitly call Flush() followed by sleep is required in Console Apps.
                        // This is to ensure that even if application terminates, telemetry is sent to the back-end.
                        telemetryClient.Flush();
                        Task.Delay(5000).Wait();

                        return success ? 0 : 1;
                    }
                }
            }
            catch (Exception ex)
            {
                ErrorLog(ex);
                return 1;
            }
        }

        private static void ErrorLog(Exception ex)
        {
            _logger.Error(ex);
            Console.WriteLine(ex.Message);
        }

        private static async Task SendErrorEmailAsync(IEmailConfigService emailConfigService, IEmailService emailService, Stream logFile)
        {
            try
            {
                var config = await emailConfigService.GetEmailConfigAsync(EmailConfigGroups.EXE_ERROR, "*");
                var recipients = config?.Recipients;
                if (string.IsNullOrWhiteSpace(recipients))
                {
                    config = await emailConfigService.GetEmailConfigAsync(EmailConfigGroups.DEFAULT_EMAIL_GROUP, "*");
                    recipients = config?.Recipients;
                }
                if (string.IsNullOrWhiteSpace(recipients))
                    return;

                var tos = recipients.Split(new[] { ',', ';' }, StringSplitOptions.RemoveEmptyEntries)
                    .Where(o => !string.IsNullOrWhiteSpace(o))
                    .Select(o => o.Trim());
                if (tos.Any())
                {
                    await emailService.SendEmailAsync(tos,
                        "PtoVSync.exe execution error".AddEnv(),
                        "Please find the error log file attached herewith.",
                        attachments =>
                        {
                            attachments.Add(new System.Net.Mail.Attachment(logFile, "ErrorsLog.txt"));
                        });
                }
            }
            catch (Exception ex)
            {
                ErrorLog(ex);
            }
        }

        private static async Task<bool> SendDataErrorMailAsync(IEmailConfigService emalConfigService, IEmailService emailService, List<Entities.ExecutableError> dataError)
        {
            try
            {
                var cropCode = dataError.FirstOrDefault().CropCode;
                var config = await emalConfigService.GetEmailConfigAsync(EmailConfigGroups.PtoV_SYNC_DATA_ERROR, cropCode);
                var recipients = config?.Recipients;
                if (string.IsNullOrWhiteSpace(recipients))
                {
                    config = await emalConfigService.GetEmailConfigAsync(EmailConfigGroups.PtoV_SYNC_DATA_ERROR, "*");
                    recipients = config?.Recipients;
                }
                if (string.IsNullOrWhiteSpace(recipients))
                {
                    config = await emalConfigService.GetEmailConfigAsync(EmailConfigGroups.EXE_ERROR, "*");
                    recipients = config?.Recipients;
                }
                if (string.IsNullOrWhiteSpace(recipients))
                {
                    config = await emalConfigService.GetEmailConfigAsync(EmailConfigGroups.DEFAULT_EMAIL_GROUP, "*");
                    recipients = config?.Recipients;
                }
                if (string.IsNullOrWhiteSpace(recipients))
                    return false;

                var tos = recipients.Split(new[] { ',', ';' }, StringSplitOptions.RemoveEmptyEntries)
                    .Where(o => !string.IsNullOrWhiteSpace(o))
                    .Select(o => o.Trim());
                if (tos.Any())
                {
                    var message = string.Join("\n", dataError.Select(x => x.ErrorMessage));
                    await emailService.SendEmailAsync(tos,
                        $"PtoVSync.exe execution error for Crop {cropCode}".AddEnv(),
                        message);
                }
                return true;
            }
            catch (Exception ex)
            {
                ErrorLog(ex);
                return false;
            }
        }
    }
}
