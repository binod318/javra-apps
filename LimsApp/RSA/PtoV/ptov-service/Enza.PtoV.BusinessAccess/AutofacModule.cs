
using Autofac;
using Enza.PtoV.BusinessAccess.Interfaces;
using Enza.PtoV.BusinessAccess.Services;
using Enza.PtoV.DataAccess.Data.Interfaces;
using Enza.PtoV.DataAccess.Data.Repositories;
using Enza.PtoV.DataAccess.Databases;
using Enza.PtoV.DataAccess.Interfaces;
using System.Configuration;
using Enza.PtoV.Services.Interfaces;

namespace Enza.PtoV.BusinessAccess
{
    public class AutofacModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            //Database
            builder.RegisterType<UserContext>().As<IUserContext>().InstancePerLifetimeScope();
            builder.RegisterType<SqlDatabase>().As<IDatabase>().WithParameter("nameOrConnectionString", "ConnectionString").InstancePerLifetimeScope();

            //Repositories
            builder.RegisterType<TraitScreeningRepository>().As<ITraitScreeningRepository>().InstancePerLifetimeScope();
            builder.RegisterType<GermplasmRepository>().As<IGermplasmRepository>().InstancePerLifetimeScope();
            builder.RegisterType<VtoPRepository>().As<IVtoPRepository>().InstancePerLifetimeScope();
            builder.RegisterType<MasterRepository>().As<IMasterRepository>().InstancePerLifetimeScope();
            builder.RegisterType<VarietyRepository>().As<IVarietyRepository>().InstancePerLifetimeScope();
            builder.RegisterType<EmailConfigRepository>().As<IEmailConfigRepository>().InstancePerLifetimeScope();
            builder.RegisterType<PedigreeRepository>().As<IPedigreeRepository>().InstancePerLifetimeScope();

            ////Services
            builder.RegisterType<TraitScreeningService>().As<ITraitScreeningService>().InstancePerLifetimeScope();
            builder.RegisterType<GermplasmService>().As<IGermplasmService>().InstancePerLifetimeScope();
            builder.RegisterType<PhenomeServices>().As<IPhenomeServices>().InstancePerLifetimeScope();
            builder.RegisterType<MasterService>().As<IMasterService>().InstancePerLifetimeScope();
            builder.RegisterType<VarietyService>().As<IVarietyService>().InstancePerLifetimeScope();
            builder.RegisterType<EmailConfigService>().As<IEmailConfigService>().InstancePerLifetimeScope();
            builder.RegisterType<EmailService>().As<IEmailService>().InstancePerLifetimeScope();
            builder.RegisterType<PedigreeService>().As<IPedigreeService>().InstancePerLifetimeScope();


            //UEL
            builder.RegisterType<UELService>().As<IUELService>().InstancePerLifetimeScope();

            //builder.RegisterType<PhenomeServices>().As<IPhenomeServices>()
            //    .WithParameter("baseServiceUrl", ConfigurationManager.AppSettings["BasePhenomeServiceUrl"])
            //    .InstancePerLifetimeScope();


            var env = ConfigurationManager.AppSettings["App:Environment"];
            if (env == "DEV")
            {
                //builder.RegisterType<Mocks.ScaleServiceMock>().As<IScaleService>().InstancePerRequest();
                //builder.RegisterType<Mocks.MasterDataServiceMock>().As<IMasterDataService>().InstancePerRequest();
                //builder.RegisterType<Mocks.EazyServiceMock>().As<IEazyService>().InstancePerRequest();
            }
            else
            {
                //builder.RegisterType<ExcelDataService>().As<IExcelDataService>().InstancePerRequest();
                //builder.RegisterType<MasterDataService>().As<IMasterDataService>().InstancePerRequest();
                //builder.RegisterType<EazyService>().As<IEazyService>().InstancePerRequest();
            }
        }
    }
}
