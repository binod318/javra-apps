using System.Configuration;
using Enza.PSC.BusinessAccess.Interfaces;
using Enza.PSC.BusinessAccess.Services;
using Enza.PSC.Common.Extensions;
using Enza.PSC.DataAccess.Data;
using Enza.PSC.DataAccess.Interfaces;
using Enza.PSC.DataAccess.Repositories;
using Enza.PSC.DataAccess.Repositories.Interfaces;
using Unity;

namespace Enza.PSC.BusinessAccess
{
    public class DependencyModule
    {
        public static void Register(IUnityContainer container)
        {
            var conString = ConfigurationManager.ConnectionStrings["ConnectionString"].ConnectionString;
            container.AddScoped<IDatabase, Database>(conString);
            container.AddScoped<IUserContext, UserContext>();
            container.AddScoped<IHistoryRepository, HistoryRepository>();
            container.AddScoped<IHistoryService, HistoryService>();
            container.AddScoped<IPlateApiService, PlateApiService>();
        }
    }
}
