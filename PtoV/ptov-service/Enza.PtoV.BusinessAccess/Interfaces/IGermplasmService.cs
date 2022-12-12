using Enza.PtoV.Entities.Args;
using Enza.PtoV.Entities.Results;
using System;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;

namespace Enza.PtoV.BusinessAccess.Interfaces
{
    public interface IGermplasmService
    {
        Task<GermplasmsImportResult> GetGermplasmAsync(GetGermplasmRequestArgs args);
        Task<GermplasmsImportResult> GetMappedGermplasmAsync(GetGermplasmRequestArgs args);
        Task<bool> DeleteGermplasmAsync(DeleteGermplasmRequestArgs args);
        Task<IEnumerable<CropResult>> GetCropsAsync();
        Task<IEnumerable<ColumnInfo>> GetPhenomeObjectDetailAsync(string cropCode);
        Task<IEnumerable<int>> GetImportedGIDsAsync(string cropCode);
        Task SynchonizePhoneAsync(DataTable tvp);
        Task<IEnumerable<VarmasDataResult>> GetVarmasDataToSyncAsync(string cropCode);
        Task UpdateModifiedData(string cellIDs);
        Task Raciprocate(List<int> varietyIDs);
        Task UpdateSyncedDateTimeAsync(string cropCode, DateTime currentUTCTime);
        //Task<IEnumerable<ColumnResult>> GetColumnsAsync(int fileID);

    }
}
