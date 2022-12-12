using Enza.PtoV.BusinessAccess.Interfaces;
using Enza.PtoV.DataAccess.Data.Interfaces;
using Enza.PtoV.Entities.Args;
using System.Data;
using System.Threading.Tasks;
using System;

namespace Enza.PtoV.BusinessAccess.Services
{
    public class TraitScreeningService : ITraitScreeningService
    {
        private readonly ITraitScreeningRepository _repo;
        public TraitScreeningService(ITraitScreeningRepository repo)
        {
            _repo = repo;
        }
        public async Task<DataTable> GetTraitScreeningAsync(TraitScreeningRequestArgs args)
        {
            return await _repo.GetTraitScreeningAsync(args);

        }
        public async Task<DataTable> GetTraitScreeningResultAsync(TraitScreeningRequestArgs args)
        {
            return await _repo.GetTraitScreeningResultAsync(args);
        }
        public async Task<DataTable> GetTraitsAsync(string traitName, string cropCode)
        {
            return await _repo.GetTraitsAsync( traitName,  cropCode);
        }
        public async Task<DataTable> GetScreeningAsync(string ScreeningName, string cropCode)
        {
            return await _repo.GetScreeningAsync(ScreeningName, cropCode);
        }

        public async Task<DataTable> SaveTraitScreeningAsync(SaveTraitScreeningRequestArgs requestargs)
        {
            return await _repo.SaveTraitScreeningAsync(requestargs);
        }

        public async Task<DataTable> GetTraitLOVAsync(int traitID)
        {
            return await _repo.GetTraitLOVAsync(traitID);
        }

        public async Task<DataTable> GetScreeningLOVAsync(int screeningFieldID)
        {
            return await _repo.GetScreeningLOVAsync(screeningFieldID);
        }

        public async Task<DataTable> GetTraitsWithScreeningAsync(string traitName, string cropCode)
        {
            return await _repo.GetTraitsWithScreeningAsync(traitName, cropCode);
        }

        public async Task<DataTable> SaveTraitScreeningResultAsync(SaveTraitScreeningResultArgs args)
        {
            return await _repo.SaveTraitScreeningResultAsync(args);
        }

        public async Task<bool> RemoveUnmappedColumns(RemoveColumnsRequestArgs args)
        {
            return await _repo.RemoveUnmappedColumns(args);
        }
    }
}
