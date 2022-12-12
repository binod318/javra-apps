using Enza.PtoV.Entities;
using Enza.PtoV.Entities.VtoP;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Enza.PtoV.BusinessAccess.Interfaces
{
    public interface IVtoPService 
    {
        Task<List<ExecutableError>> VtoPSynchronizeAsync();
    }
}
