using Enza.PtoV.DataAccess.Interfaces;
using Enza.PtoV.Entities.Results;
using Enza.PtoV.Entities.VtoP;
using Enza.PtoV.Services.Abstract;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Enza.PtoV.DataAccess.Data.Interfaces
{
    public interface IENumberSyncRepository : IRepository<object>
    {
        Task SignInToPhenomeAsync(RestClient client);

        Task<IEnumerable<GermplasmColumnInfo>> GetGermplasmColumnsAsync(RestClient client, int objectType, int objectID);
        Task UpdateGermplasmDataAsync(RestClient client, UpdateGermplasmDataArgs args);
        Task<IEnumerable<VarietyLogResult>> GetVarietyLogsAsync(string syncCode, string cropCode);
        Task UpdateVarietyENumbersAsnyc(string dataAsJson);
        Task UpdateVarietyStatusAsync(int varietyID);
        Task<IEnumerable<VarietySyncLog>> GetVarmasVarietySyncLogsAsync();
        Task<Services.Proxies.VtoPSyncClient.GetVarietyInfoResponse> GetVarmasVarietiesAsync(VarmasVarietiesArgs requestArgs);
        Task UpdateSyncedTimestampAsync(string cropCode, string syncCode, string timestamp);
        Task<IEnumerable<VarietyLogRelation>> GetVarietyLogsForVarietyAsync(string varietyList, string syncCode, string cropCode);
        Task ApplyLockVariablesAsync(RestClient client, int rgID, List<string> variables, string action);
        Task<IEnumerable<VarietyLogResult>> GetResearchGroupObjectID(string cropCode);
        Task<IEnumerable<StatusDetail>> GetStatusDetailAsync();
    }
}
