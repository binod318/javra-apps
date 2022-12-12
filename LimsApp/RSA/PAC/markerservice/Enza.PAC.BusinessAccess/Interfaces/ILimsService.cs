using Enza.PAC.Entities.Args;
using System.Threading.Tasks;

namespace Enza.PAC.BusinessAccess.Interfaces
{
    public interface ILimsService
    {
        Task<bool> ReservePlateplansInLIMSCallbackAsync(ReservePlateplansInLIMSCallbackRequestArgs requestArgs);
        Task ReceiveResultsinKscoreCallbackAsync(ReceiveResultsinKscoreRequestArgs args);
    }
}
