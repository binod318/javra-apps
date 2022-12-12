using Enza.PAC.DataAccess.Interfaces;
using Enza.PAC.Entities.Args;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Enza.PAC.DataAccess.Data.Interfaces
{
    public interface ILimsRepository : IRepository<object>
    {
        Task<bool> ReservePlateplansInLIMSCallbackAsync(ReservePlateplansInLIMSCallbackRequestArgs requestArgs);
        Task ReceiveResultsinKscoreCallbackAsync(ReceiveResultsinKscoreRequestArgs requestArgs);
    }
}
