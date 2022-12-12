using Autofac;
using Quartz;
using Quartz.Spi;

namespace Enza.UTM.Web.Services.Scheduling
{
    public class QuartzJobFactory : IJobFactory
    {
        private readonly IComponentContext _container;
        public QuartzJobFactory(IComponentContext container)
        {
            _container = container;
        }
        public IJob NewJob(TriggerFiredBundle bundle, IScheduler scheduler)
        {
            return _container.Resolve(bundle.JobDetail.JobType) as IJob;
        }

        public void ReturnJob(IJob job)
        {
        }
    }
}