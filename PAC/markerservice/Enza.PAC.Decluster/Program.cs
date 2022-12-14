using Autofac;
using Enza.PAC.BusinessAccess.Interfaces;
using Enza.PAC.Common;
using Enza.PAC.Common.Extensions;
using Enza.PAC.Common.Handlers;
using log4net;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights.Extensibility;
using System;
using System.Configuration;
using System.IO;

namespace Enza.PAC.Decluster
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
                //Initialize Telemetry Initializer
                TelemetryConfiguration.Active.ConnectionString = ConfigurationManager.AppSettings["AIConnectionString"];
                TelemetryConfiguration.Active.TelemetryInitializers.Add(new CustomRequestResponseInitializer());

                //Initialize Telemetry Processor
                var telemetrybuilder = TelemetryConfiguration.Active.DefaultTelemetrySink.TelemetryProcessorChainBuilder;
                telemetrybuilder.Use((next) => new SuccessfulDependencyFilter(next));
                telemetrybuilder.Build();


                log4net.Config.XmlConfigurator.Configure();

                var builder = new ContainerBuilder();
                AutofacConfig.Register(builder);
                Container = builder.Build();

                _logger.Info("Declustering started : " + System.DateTime.Now);

                var success = false;
                var telemetryClient = new TelemetryClient();
                using (var operation = telemetryClient.StartOperation<RequestTelemetry>("Decluster"))
                {
                    using (var scope = Container.BeginLifetimeScope())
                    {
                        success = AsyncHelper.RunSync(async () =>
                        {
                            var service = scope.Resolve<IDeterminationAssignmentService>();
                            //exception has already been handled inside this method.
                            var ok = await service.DeclusterAsync()
                            .ExecuteSafe(err =>
                            {
                                ErrorLog(err);
                            });
                            if (!ok)
                            {
                                //in case error 
                                var root = Path.Combine(Environment.CurrentDirectory, "Logs");
                                var logFile = _logger.GetLogCurrentFile(root);
                            }

                            //Trigger ReservePlates
                            var serviceTest = scope.Resolve<ITestService>();
                            ok = await serviceTest.AutomateReservePlatesAsync()
                            .ExecuteSafe(err =>
                            {
                                ErrorLog(err);
                            });
                            if (!ok)
                            {
                                //in case error 
                                var root = Path.Combine(Environment.CurrentDirectory, "Logs");
                                var logFile = _logger.GetLogCurrentFile(root);
                            }
                            return ok;
                        });                        
                    }
                }

                // Explicitly call Flush() followed by sleep is required in Console Apps.
                // This is to ensure that even if application terminates, telemetry is sent to the back-end.
                telemetryClient.Flush();
                System.Threading.Tasks.Task.Delay(5000).Wait();

                return success ? 0 : 1;
            }
            catch (Exception ex2)
            {
                ErrorLog(ex2);
                return 1;
            }
        }

        private static void ErrorLog(Exception ex)
        {
            _logger.Error(ex);
            Console.WriteLine(ex.Message);
        }
    }
}
