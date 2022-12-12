using Enza.PtoV.DataAccess.Interfaces;
using Enza.PtoV.Entities.Results;
using Enza.PtoV.Entities.VtoP;
using Enza.PtoV.Services.Abstract;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Enza.PtoV.DataAccess.Data.Interfaces
{
    public interface IVtoPRepository : IRepository<object>
    {
        Task SignInToPhenomeAsync(RestClient client);

        Task<IEnumerable<GermplasmColumnInfo>> GetGermplasmColumnsAsync(RestClient client, int objectType, int objectID);
        Task UpdateGermplasmDataAsync(RestClient client, UpdateGermplasmDataArgs args, int rgID);

        Task<CreateGermplasmResult> CreateGermplasmAsync(RestClient client, CreateGermplasmArgs args);
        Task<InventoryLotResult> GetInventoryLotAsync(RestClient client, int gid, string lotreference, int folderID, List<Column> columnsToLoad, string objectType);
        Task<List<Column>> GetInventoryLotColumnsAsync(RestClient client, int objectType, int objectID);
        Task<List<Column>> GetAllGermplasmColumnsAsync(RestClient client, int objectType, int objectID);
        Task<string> CreateInventoryLotAsync(RestClient client, int objectID, string gid, List<VtoPColumnMapping> mappedCols);
        Task UpdateInventoryLotAsync(RestClient client, string lotID, int objectType, List<VtoPColumnMapping> mappedCols,
            List<Column> phenomeInventoryColumns, Services.Proxies.VtoPSyncClient.Lot data, Dictionary<string, string> additionalValues);

        Task<IEnumerable<VtoPSyncConfig>> GetSyncConfigsAsync();
        Task<IEnumerable<Services.Proxies.VtoPSyncClient.Lot>> GetVarmasLotsAndVarietiesAsync(VarmasLotsAndVarietiesArgs requestArgs);

        Task<List<VtoPColumnMapping>> GetMappedColumnsAsync();
        Task<bool> UpdateExtenalLotsToVarmasAsync(UpdateExternalLotsToVarmasArgs requestArgs);
        /// <summary>
        /// Creates or updates relationship into RelationPtoV table
        /// </summary>
        /// <param name="dataAsJson">Example: [{"GID": 123123, "VarietyNr": 32123}]</param>
        /// <returns></returns>
        Task UpdatePtoVRelationshipAsync(string dataAsJson);

        Task UpdateLastLotNrToSyncConfigTableAsync(int syncConfigID, int LotNr);

        Task<string> GetGermplasmNameFromVarietyNrAsync(int varietyNr);
        Task<int> GetPhenomeGIDFromVarietyNrAsync(int varietyNr);
        Task<VarietyWithLot> GetGIDDetailFromLotNrAsync(int LotNr);
        Task<VarietyWithLot> GetGIDDetailFromPhenomeGIDAsync(int PhenomeGID);
        Task<VarietyWithLot> GetGIDDetailFromVarietyNrAsync(int PhenomeGID);
    }
}
