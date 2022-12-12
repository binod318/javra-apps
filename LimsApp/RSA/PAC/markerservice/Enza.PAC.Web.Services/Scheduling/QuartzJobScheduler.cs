using Quartz;
using System;
using System.Threading.Tasks;

namespace Enza.PAC.Web.Services.Scheduling
{
    public class QuartzJobScheduler : IDisposable
    {
        private IScheduler _scheduler;
        public QuartzJobScheduler(IScheduler scheduler)
        {
            _scheduler = scheduler;
        }

        public async Task StartAsync()
        {
            await _scheduler.Start();
        }

        public async Task StopAsync()
        {
            await _scheduler.Shutdown(true);
        }

        public async Task ScheduleJobAsync<T>(string cronExpr) where T : IJob
        {
            var trigger = TriggerBuilder.Create()
                .StartNow()
                .WithCronSchedule(cronExpr)
                .Build();

            var job = JobBuilder
                .Create<T>()
                .Build();

            await _scheduler.ScheduleJob(job, trigger);
        }

        public async Task ScheduleOnDemandJobAsync<T>() where T : IJob
        {
            var jobName = typeof(T).FullName;
            var job = JobBuilder
                .Create<T>()
                .WithIdentity(jobName)
                .StoreDurably()
                .Build();
            await _scheduler.AddJob(job, true);
        }

        public async Task TriggerJobAsync<T>() where T: IJob
        {
            var jobName = typeof(T).FullName;
            await _scheduler.TriggerJob(new JobKey(jobName));
        }

        public void Dispose()
        {
            _scheduler = null;
        }
    }
}