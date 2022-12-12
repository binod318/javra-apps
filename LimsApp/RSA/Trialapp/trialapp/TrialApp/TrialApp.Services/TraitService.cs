using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Enza.DataAccess;
using SQLite;
using TrialApp.Common;
using TrialApp.DataAccess;
using TrialApp.Entities.Master;

namespace TrialApp.Services
{
    public class TraitService
    {
        private TraitRepository _repoAsync;
        private TraitRepository _repoSync;
        public TraitService()
        {
            _repoAsync = new TraitRepository(new SQLiteAsyncConnection(DbPath.GetMasterDbPath()));
            _repoSync = new TraitRepository();
        }

        public List<Trait> GetTraitList(int fieldsetId)
        {
            var traitInFieldsets = _repoSync.GetTraitsFromFieldset(fieldsetId);
            return traitInFieldsets;
        }
        /// <summary>
        /// Load Traits list by providing comma seperated TraitIDs
        /// </summary>
        /// <param name="traitIDs"> Comma seperated TraitIDs</param>
        /// <returns></returns>
        public async Task<List<Trait>> GetTraitsAsync(string traitIDs)
        {
            return await _repoAsync.GetTraitsAsync(traitIDs);
        }

        public async Task<List<Trait>> GetAllTraitsAsync(string cropCode)
        {
            return await _repoAsync.GetAllTraitsAsync(cropCode);
        }

        public async Task<List<Trait>> GetTraitsDetailAsync(string traitIDs)
        {
            return await _repoAsync.GetTraitsDetailAsync(traitIDs);
        }
        
    }
}

