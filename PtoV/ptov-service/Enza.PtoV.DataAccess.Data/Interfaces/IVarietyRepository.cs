using System.Collections.Generic;
using System.Data;
using Enza.PtoV.DataAccess.Interfaces;
using System.Threading.Tasks;
using Enza.PtoV.Entities;
using Enza.PtoV.Entities.Args;
using Enza.PtoV.Entities.Results;

namespace Enza.PtoV.DataAccess.Data.Interfaces
{
    public interface IVarietyRepository : IRepository<object>
    {
        Task UpdateProductSegmentsAsync(UpdateProductSegmentsRequestArgs requestArgs);
        Task<IEnumerable<VarietyResult>> GetVarietyDetailsAsync(IEnumerable<int> varietyIDs);
        Task<UpdateVarmasResult> UpdateVarmasResponseAsync(UpdateVarmasResponse model);
        Task<bool> ReplaceLOTAsync(int gID, int lotGID);
        Task<bool> ReplaceLOTAsync(ReplaceLotRequestArgs args);
        Task<bool> UndoReplaceLOTAsync(UndoReplaceLotRequestArgs args);
        Task<DataTable> ReplaceLOTLookupAsync(int gID);
        Task<IEnumerable<VarietyResult>> GetVarietyDetailForReplacedLotAsync(string varietyIDS);
        Task<IEnumerable<ColumnInfo>> GetColumnDetailForGermplasm(int gID);
        Task ImportGermplasmFromPedigree(DataTable dtRowTVP, DataTable dtColumnsTVP, DataTable dtCellTVP,DataTable dtLotTVP, int gID);
        //Task<IEnumerable<int>> GetParents(int varietyID);
        Task<IEnumerable<LotDeteilResult>> PhenomeLotIDExistsAsync(int phenomeLotGID);

        Task<IEnumerable<VarietyInfo>> GetVarietiesAsync(IEnumerable<int> gids);
        Task<IEnumerable<VarietyResult>> GetVarietiesWithStemAsync(IEnumerable<int> varietyIDs);
        Task<bool> UpdateVarietyLinkAsync(int varietyID, string transferType, int newGID);
        Task<VarietyResult> GetVarietyNrOfParentAsync(int gID);
    }
}
