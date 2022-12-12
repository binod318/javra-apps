using System.Collections.Generic;
using System.Threading.Tasks;
using SQLite;
using TrialApp.Common;
using TrialApp.DataAccess;
using TrialApp.Entities.Transaction;

namespace TrialApp.Services
{
    public class DefaultTraitsPerTrialService
    {
        private readonly DefaultTraitsPerTrialRepository _repoAsync;
        //private readonly DefaultTraitsPerTrialRepository _repoSync;

        public DefaultTraitsPerTrialService()
        {
            _repoAsync = new DefaultTraitsPerTrialRepository(new SQLiteAsyncConnection(DbPath.GetTransactionDbPath()));
            //_repoSync = new DefaultTraitsPerTrialRepository();
        }

        public async Task<List<DefaultTraitsPerTrial>> GetAsync(int ezid)
        {
            return await _repoAsync.GetAsync(ezid);
        }

        public async Task<bool> SaveAsync(List<DefaultTraitsPerTrial> args)
        {
            return await _repoAsync.SaveAsync(args);
        }
    }
}
