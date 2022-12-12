using Enza.PtoV.Entities;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Enza.PtoV.BusinessAccess.Interfaces
{
    public interface IENumberSyncService
    {        
        Task<List<ExecutableError>> SynchronizeAsync();
    }
}
