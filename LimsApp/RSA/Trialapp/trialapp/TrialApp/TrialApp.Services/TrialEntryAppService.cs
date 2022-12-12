using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SQLite;
using TrialApp.Common;
using TrialApp.DataAccess;
using TrialApp.Entities.Transaction;

namespace TrialApp.Services
{
    public class TrialEntryAppService
    {
        private readonly TrialEntryAppRepository _repoAsync;
        private readonly TrialEntryAppRepository _repoSync;
        private readonly TrialService _trialService;

        public TrialEntryAppService()
        {
            _repoAsync = new TrialEntryAppRepository(new SQLiteAsyncConnection(DbPath.GetTransactionDbPath()));
            _repoSync = new TrialEntryAppRepository();
            _trialService = new TrialService();
        }

        public async Task<List<TrialEntryApp>> GetVarietiesListAsync(int ezid)
        {
            var varietyList = await _repoAsync.GetVarietiesListAsync(ezid);
            return varietyList;
        }

        public async Task<int> AddVariety(TrialEntryApp TE, Relationship R)
        {
            var operation = await _repoAsync.AddTrialEntryWithRelationshipAsync(TE, R);
            if (operation > 0)
                _trialService.UpdateTrialStatus(R.EZID1);
            return operation;
        }

        public async Task<TrialEntryApp> GetVarietiesInfoAsync(string ezid)
        {
            var variety = await _repoAsync.GetVarietiesInfoAsync(ezid);
            return variety;
        }

        public async Task<List<TrialEntryApp>> GetTrialEntriesByNameAsync(string ezid, string fieldnr, string name)
        {
            var variety = await _repoAsync.GetTrialEntriesByNameAsync(ezid, fieldnr, name);
            return variety;
        }

        public async Task<bool> DeleteVarietyAsync(string ezid)
        {
            return await _repoAsync.DeleteVarietyAsync(ezid);
            
        }
        public async Task<bool> HideVarietyAsync(string ezid, int trialezid)
        {
            return await _repoAsync.HideVarietyAsync(ezid, trialezid);

        }
    }
}
