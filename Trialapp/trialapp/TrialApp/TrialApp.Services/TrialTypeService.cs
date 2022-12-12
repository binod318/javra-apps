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
    public class TrialTypeService
    {
        private readonly TrialTypeRepository _repoAsync;
        private readonly TrialTypeRepository _repoSync;

        public TrialTypeService()
        {
            _repoAsync = new TrialTypeRepository(new SQLiteAsyncConnection(DbPath.GetMasterDbPath()));
            _repoSync = new TrialTypeRepository();
        }

        public async Task<List<TrialType>> GetTrialTypeListAsync(string downloadedTrialTypeList)
        {
            return await _repoAsync.GetTrialTypeListAsync(downloadedTrialTypeList);
        }
    }
}
