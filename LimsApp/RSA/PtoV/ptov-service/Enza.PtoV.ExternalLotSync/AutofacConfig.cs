﻿using System.Reflection;
using Autofac;
using Enza.PtoV.BusinessAccess.Interfaces;
using Enza.PtoV.BusinessAccess.Services;
using Enza.PtoV.DataAccess.Data.Interfaces;
using Enza.PtoV.DataAccess.Data.Repositories;
using Enza.PtoV.DataAccess.Databases;
using Enza.PtoV.DataAccess.Interfaces;
using Enza.PtoV.Services.Interfaces;

namespace Enza.PtoV.ExternalLotSync
{
    public static class AutofacConfig
    {
        public static void Register(ContainerBuilder builder)
        {
            //Database
            builder.RegisterType<UserContext>().As<IUserContext>().InstancePerLifetimeScope();
            builder.RegisterType<SqlDatabase>().As<IDatabase>()
                .WithParameter("nameOrConnectionString", "ConnectionString").InstancePerLifetimeScope();

            //UEL
            builder.RegisterType<UELService>().As<IUELService>().InstancePerLifetimeScope();

            builder.RegisterType<VtoPRepository>().As<IVtoPRepository>().InstancePerLifetimeScope();
            builder.RegisterType<VtoPService>().As<IVtoPService>().InstancePerLifetimeScope();
            builder.RegisterType<PhenomeServiceRespsitory>().As<IPhenomeServiceRespsitory>().InstancePerLifetimeScope();


            ////Repo
            //builder.RegisterType<GermplasmRepository>().As<IGermplasmRepository>().InstancePerLifetimeScope();
            ////Sync
            //builder.RegisterType<GermplasmService>().As<IGermplasmService>().InstancePerLifetimeScope();
            //builder.RegisterType<SynchronizationService>().As<ISynchronizationService>().InstancePerLifetimeScope();

            builder.RegisterType<EmailConfigRepository>().As<IEmailConfigRepository>().InstancePerLifetimeScope();
            builder.RegisterType<EmailConfigService>().As<IEmailConfigService>().InstancePerLifetimeScope();
            builder.RegisterType<EmailService>().As<IEmailService>().InstancePerLifetimeScope();
        }
    }
}
