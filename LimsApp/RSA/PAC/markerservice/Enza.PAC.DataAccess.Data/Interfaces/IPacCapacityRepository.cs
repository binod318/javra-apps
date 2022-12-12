using Enza.PAC.DataAccess.Interfaces;
using Enza.PAC.Entities.Args;
using System.Collections.Generic;
using System.Data;
using System.Net.Http;
using System.Threading.Tasks;

namespace Enza.PAC.DataAccess.Data.Interfaces
{
    public interface IPacCapacityRepository : IRepository<object>
    {
        Task<DataSet> GetPlanningCapacityAsync(int year);
        Task SaveLabCapacityAsync(List<SaveCapacityRequestArgs> args);
        Task<DataSet> GetPACPlanningCapacitySOAsync(int periodID);
        Task<DataSet> SavePACPlanningCapacitySOAsync(List<SavePlanningCapacitySOArgs> args);
    }
}
