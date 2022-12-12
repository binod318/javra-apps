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
    public class CountryService
    {
        private readonly CountryRepository _repoAsync;
        private readonly CountryRepository _repoSync;

        public CountryService()
        {
            _repoAsync = new CountryRepository(new SQLiteAsyncConnection(DbPath.GetMasterDbPath()));
            _repoSync = new CountryRepository();
        }

        public async Task<List<Country>> GetCountryListAsync(string downloadedCountryList)
        {
            return await _repoAsync.GetCountryListAsync(downloadedCountryList);
        }
    }
}
