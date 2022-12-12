using System;
using System.Threading.Tasks;

namespace Enza.PtoV.Services.Interfaces
{
    public interface IUELService
    {
        bool LogError(Exception ex, out string logID);
        Task<int> LogAsync(Exception ex);
    }
}
