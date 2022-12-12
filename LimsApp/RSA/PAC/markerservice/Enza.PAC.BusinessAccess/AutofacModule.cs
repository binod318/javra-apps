using Autofac;
using Enza.PAC.BusinessAccess.Interfaces;
using Enza.PAC.BusinessAccess.Services;
using Enza.PAC.DataAccess.Data.Interfaces;
using Enza.PAC.DataAccess.Data.Repositories;
using Enza.PAC.DataAccess.Databases;
using Enza.PAC.DataAccess.Interfaces;

namespace Enza.PAC.BusinessAccess
{
    public class AutofacModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            //Database
            builder.RegisterType<UserContext>().As<IUserContext>().InstancePerLifetimeScope();
            builder.RegisterType<PACDatabase>().As<IPACDatabase>()
                .WithParameter("nameOrConnectionString", "ConnectionString").InstancePerLifetimeScope();

            builder.RegisterType<PacCapacityRepository>().As<IPacCapacityRepository>().InstancePerLifetimeScope();
            builder.RegisterType<PacCapacityService>().As<IPacCapacityService>().InstancePerLifetimeScope();

            builder.RegisterType<MasterRepository>().As<IMasterRepository>().InstancePerLifetimeScope();
            builder.RegisterType<MasterService>().As<IMasterService>().InstancePerLifetimeScope();

            builder.RegisterType<DeterminationAssignmentRepository>().As<IDeterminationAssignmentRepository>().InstancePerLifetimeScope();
            builder.RegisterType<DeterminationAssignmentService>().As<IDeterminationAssignmentService>().InstancePerLifetimeScope();

            builder.RegisterType<VarietyRepository>().As<IVarietyRepository>().InstancePerLifetimeScope();
            builder.RegisterType<VarietyService>().As<IVarietyService>().InstancePerLifetimeScope();

            builder.RegisterType<TestRepository>().As<ITestRepository>().InstancePerLifetimeScope();
            builder.RegisterType<TestService>().As<ITestService>().InstancePerLifetimeScope();

            builder.RegisterType<LimsRepository>().As<ILimsRepository>().InstancePerLifetimeScope();
            builder.RegisterType<LimsService>().As<ILimsService>().InstancePerLifetimeScope();

            builder.RegisterType<CriteriaPerCropRepository>().As<ICriteriaPerCropRepository>().InstancePerLifetimeScope();
            builder.RegisterType<CriteriaPerCropService>().As<ICriteriaPerCropService>().InstancePerLifetimeScope();

            builder.RegisterType<ExternalApiRepository>().As<IExternalApiRepository>().InstancePerLifetimeScope();
            builder.RegisterType<ExternalApiService>().As<IExternalApiService>().InstancePerLifetimeScope();
        }
    }
}
