using System.Collections.Generic;
using System.Threading.Tasks;
using Enza.DataAccess;
using SQLite;
using TrialApp.Common;
using TrialApp.Entities.Master;

namespace TrialApp.DataAccess
{
    public class CountryRepository : Repository<Country>
    {
        public CountryRepository() : base(DbPath.GetMasterDbPath())
        {
        }

        public CountryRepository(SQLiteAsyncConnection connection) : base(connection)
        {
        }

        public async Task<List<Country>> GetCountryListAsync(string downloadedCountryList)
        {
            return await DbContextAsync().QueryAsync<Country>("select * from Country where CountryCode in ( " + downloadedCountryList + ")");
        }
    }
}
