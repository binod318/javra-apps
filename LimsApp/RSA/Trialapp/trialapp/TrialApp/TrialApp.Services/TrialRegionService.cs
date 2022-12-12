using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SQLite;
using TrialApp.Common;
using TrialApp.DataAccess;
using TrialApp.Entities.Master;

namespace TrialApp.Services
{
    public class TrialRegionService
    {
        private readonly TrialRegionRepository _repoAsync;
        private readonly TrialRegionRepository _repoSync;

        public TrialRegionService()
        {
            _repoAsync = new TrialRegionRepository(new SQLiteAsyncConnection(DbPath.GetMasterDbPath()));
            _repoSync = new TrialRegionRepository();
        }

        public async Task<List<TrialRegion>> GetTrialRegionListAsync(string trialregionList)
        {
            return await _repoAsync.GetTrialRegionListAsync(trialregionList);
        }
    }
}
