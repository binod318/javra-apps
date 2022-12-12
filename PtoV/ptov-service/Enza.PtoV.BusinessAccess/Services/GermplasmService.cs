using Enza.PtoV.BusinessAccess.Interfaces;
using Enza.PtoV.DataAccess.Data.Interfaces;
using Enza.PtoV.Entities.Args;
using System.Threading.Tasks;
using Enza.PtoV.Entities.Results;
using System;
using System.Collections.Generic;
using System.Data;

namespace Enza.PtoV.BusinessAccess.Services
{
    public class GermplasmService : IGermplasmService
    {
        private readonly IGermplasmRepository _repo;
        public GermplasmService(IGermplasmRepository repo)
        {
            _repo = repo;
        }

        public async Task<GermplasmsImportResult> GetGermplasmAsync(GetGermplasmRequestArgs args)
        {
            return await _repo.GetGermplasmAsync(args);
        }

        public async Task<GermplasmsImportResult> GetMappedGermplasmAsync(GetGermplasmRequestArgs args)
        {
            return await _repo.GetMappedGermplasmAsync(args);
        }
        public async Task<bool> DeleteGermplasmAsync(DeleteGermplasmRequestArgs args)
        {
            return await _repo.DeleteGermplasmAsync(args);
        }

        public Task<IEnumerable<CropResult>> GetCropsAsync()
        {
            return _repo.GetCropsAsync();
        }

        public Task<IEnumerable<ColumnInfo>> GetPhenomeObjectDetailAsync(string cropCode)
        {
            return _repo.GetPhenomeObjectDetailAsync(cropCode);
        }

        public Task<IEnumerable<int>> GetImportedGIDsAsync(string cropCode)
        {
            return _repo.GetImportedGIDsAsync(cropCode);
        }

        public Task SynchonizePhoneAsync(DataTable tvp)
        {
            return _repo.SynchonizePhoneAsync(tvp);
        }

        public Task<IEnumerable<VarmasDataResult>> GetVarmasDataToSyncAsync(string cropCode)
        {
            return _repo.GetVarmasDataToSyncAsync(cropCode);
        }

        public async Task UpdateModifiedData(string cellIDs)
        {
            await _repo.UpdateModifiedData(cellIDs);
        }

        public Task Raciprocate(List<int> varietyIDs)
        {
            return _repo.Raciprocate(varietyIDs);
        }

        public Task UpdateSyncedDateTimeAsync(string cropCode, DateTime currentUTCTime)
        {
            return _repo.UpdateSyncedDateTimeAsync(cropCode, currentUTCTime);
        }

        //public Task<IEnumerable<ColumnResult>> GetColumnsAsync(int fileID)
        //{
        //    return _repo.GetColumnsAsync(fileID);
        //}
    }
}
