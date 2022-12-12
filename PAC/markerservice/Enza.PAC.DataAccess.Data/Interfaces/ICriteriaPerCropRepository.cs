using Enza.PAC.DataAccess.Interfaces;
using Enza.PAC.Entities.Args;
using System.Data;
using System.Threading.Tasks;

namespace Enza.PAC.DataAccess.Data.Interfaces
{
    public interface ICriteriaPerCropRepository : IRepository<object>
    {
        Task<DataSet> GetAllCriteriaPerCropAsync(GetCriteriaPerCropRequestArgs requestArgs);
        Task PostAsync(CriteriaPerCropRequestArgs requestArgs);
    }
}
