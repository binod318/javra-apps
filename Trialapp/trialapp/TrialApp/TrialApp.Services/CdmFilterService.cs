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

    public class CdmFilterService
    {
        private readonly CdmFilterRepository _repoAsync;
        private readonly CdmFilterRepository _repoSync;

        public CdmFilterService()
        {
            _repoAsync = new CdmFilterRepository(new SQLiteAsyncConnection(DbPath.GetMasterDbPath()));
            _repoSync = new CdmFilterRepository();
        }

        public async Task<List<CDM_Filter>> GetFilterListAsync()
        {
            return await _repoAsync.GetCdmFilterList();
        }
    }
}
