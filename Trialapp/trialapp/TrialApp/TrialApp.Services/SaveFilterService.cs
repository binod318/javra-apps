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
    public class SaveFilterService
    {
        private readonly SaveFilterRepository _repoAsync;
        private readonly SaveFilterRepository _repoSync;

        public SaveFilterService()
        {
            _repoAsync = new SaveFilterRepository(new SQLiteAsyncConnection(DbPath.GetTransactionDbPath()));
            _repoSync = new SaveFilterRepository();
        }

        public async Task<List<SaveFilter>> GetSaveFilterAsync()
        {
            return await _repoAsync.GetSaveFilterListAsync();
        }

        public async Task SaveFilterAsync(List<SaveFilter> savefilterList)
        {
            await _repoAsync.SaveFilterListAsync(savefilterList);
        }
    }
}
