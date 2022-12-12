using System;
using System.Reflection;
using System.Web.Http;
using Autofac;
using Autofac.Integration.WebApi;
using Enza.UTM.BusinessAccess;
using Owin;
using Quartz.Spi;

namespace Enza.UTM.Web.Services
{
    public static class AutofacConfig
    {
        //public static void Configure(HttpConfiguration config, Action<ContainerBuilder> registration, Action<ILifetimeScope> callback)
        //public static void Configure(HttpConfiguration config)
        //{
        //    var builder = new ContainerBuilder();
        //    builder.RegisterApiControllers(Assembly.GetExecutingAssembly());

        //    //register other types
        //    builder.RegisterModule<AutofacModule>();

        //    var container = builder.Build();
        //    config.DependencyResolver = new AutofacWebApiDependencyResolver(container);
        //}

        public static void Configure(HttpConfiguration config, IAppBuilder app)
        {
            var builder = new ContainerBuilder();
            builder.RegisterApiControllers(Assembly.GetExecutingAssembly());

            //register other types
            builder.RegisterModule<AutofacModule>();
            RegisterQuartz(builder);
            var container = builder.Build();
            config.DependencyResolver = new AutofacWebApiDependencyResolver(container);
            app.UseAutofacMiddleware(container);
            app.UseAutofacWebApi(config);

            ScheduleQuartzJobs(container);
        }

        private static void RegisterQuartz(ContainerBuilder builder)
        {
            builder.RegisterType<Scheduling.QuartzJobFactory>().As<IJobFactory>().SingleInstance();
            builder.RegisterType<Scheduling.QuartzJobScheduler>().AsSelf().SingleInstance();
            builder.Register(context =>
            {
                var scheduler = new Quartz.Impl.StdSchedulerFactory().GetScheduler()
                .ConfigureAwait(false).GetAwaiter().GetResult();

                scheduler.JobFactory = context.Resolve<IJobFactory>();
                return scheduler;
            }).SingleInstance();

            builder.RegisterType<Scheduling.Jobs.LeafDiskSummaryCalculationJob>().AsSelf().InstancePerDependency();
        }

        private static void ScheduleQuartzJobs(IContainer container)
        {
            var scheduler = container.Resolve<Scheduling.QuartzJobScheduler>();
            Action action = async () =>
            {
                //schedule job here
                await scheduler.ScheduleOnDemandJobAsync<Scheduling.Jobs.LeafDiskSummaryCalculationJob>();
                await scheduler.StartAsync();
            };
            action();
        }
    }
}
