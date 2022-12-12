using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using Enza.UTM.DataAccess.Interfaces;
using Enza.UTM.Entities.Args;
using Enza.UTM.Entities.Results;

namespace Enza.UTM.DataAccess.Data.Planning.Interfaces
{
    public interface ILeafDiskCapacityRepository : IRepository<object>
    {
        Task<DataSet> GetCapacityAsync(int year, int siteLocation);
        Task<bool> SaveCapacityAsync(SaveCapacityRequestArgs request);
        Task<DataSet> GetPlanApprovalListForLabAsync(int periodID, int siteID);
        Task<bool> MoveSlotAsync(MoveSlotRequestArgs args);
        Task<bool> DeleteSlotAsync(DeleteSlotRequestArgs args);
    }
}
