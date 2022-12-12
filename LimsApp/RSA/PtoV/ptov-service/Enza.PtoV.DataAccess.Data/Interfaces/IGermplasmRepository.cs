using System.Collections.Generic;
using Enza.PtoV.Entities.Args;
using System.Threading.Tasks;
using Enza.PtoV.Entities.Results;
using System.Data;
using System;

namespace Enza.PtoV.DataAccess.Data.Interfaces
{
    public interface IGermplasmRepository
    {
        Task<GermplasmsImportResult> GetGermplasmAsync(GetGermplasmRequestArgs args);

        Task<GermplasmsImportResult> ImportGermplasmDataAsync(GetGermplasmRequestArgs args, DataTable dtCellTVP,
            DataTable dtColumnsTVP, DataTable dtRowTVP, DataTable dtLotTVP);

        Task<GermplasmsImportResult> GetMappedGermplasmAsync(GetGermplasmRequestArgs args);
        Task<bool> DeleteGermplasmAsync(DeleteGermplasmRequestArgs args);

        Task<IEnumerable<CropResult>> GetCropsAsync();
        Task<IEnumerable<ColumnInfo>> GetPhenomeObjectDetailAsync(string cropCode);
        /// <summary>
        /// Gets list of columns from Column table based on gid. 
        /// </summary>
        /// <param name="gid"></param>
        /// <returns></returns>
        Task<IEnumerable<string>> GetPhenomeColumnsAsync(int gid);

        Task<IEnumerable<int>> GetImportedGIDsAsync(string cropCode);

        Task SynchonizePhoneAsync(DataTable tvp);
        Task<IEnumerable<VarmasDataResult>> GetVarmasDataToSyncAsync(string cropCode);
        Task UpdateModifiedData(string cellIDs);
        Task Raciprocate(List<int> varietyIDs);
        Task<bool> CheckUsePoNr(string cropCode);

        Task<GermplasmsObjectResult> GetPhenomeColumnDetailsAsync(string cropCode);
        Task UpdateSyncedDateTimeAsync(string cropCode, DateTime currentUTCTime);
        //Task<IEnumerable<ColumnResult>> GetColumnsAsync(int fileID);
    }
}
