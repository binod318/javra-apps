using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Enza.DataAccess;
using SQLite;
using TrialApp.Common;
using TrialApp.Entities.Master;

namespace TrialApp.DataAccess
{
    public class TrialRegionRepository : Repository<TrialRegion>
    {
        public TrialRegionRepository() : base(DbPath.GetMasterDbPath())
        {
        }

        public TrialRegionRepository(SQLiteAsyncConnection connection) : base(connection)
        {
        }

        public async Task<List<TrialRegion>> GetTrialRegionListAsync(string trialregionList)
        {
            var data = await DbContextAsync().QueryAsync<TrialRegion>("select * from TrialRegion where TrialRegionID in (" + trialregionList + ")");
            return data;
        }
    }
}
