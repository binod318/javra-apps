using Enza.PtoV.DataAccess.Interfaces;
using Enza.PtoV.Entities.Results;
using Enza.PtoV.Entities.VtoP;
using Enza.PtoV.Services.Abstract;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Enza.PtoV.DataAccess.Data.Interfaces
{
    public interface IPhenomeServiceRespsitory
    {
        Task SignInToPhenomeAsync(RestClient client);
        Task<GetSettingsResponse> GetSettingsAsync(RestClient client, int rgid);
        Task ApplylockVariablesAsync(RestClient client, int rgid, GetSettingsResponse settings, List<string> Variables, string action);
    }
}
