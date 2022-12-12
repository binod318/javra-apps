using Enza.DataAccess;
using TrialApp.Common;
using SQLite;
using System.Collections.Generic;
using TrialApp.Entities.Transaction;
using System.Threading.Tasks;
using System.Linq;

namespace TrialApp.DataAccess
{
    public class DefaultTraitsPerTrialRepository : Repository<DefaultTraitsPerTrial>
    {
        public DefaultTraitsPerTrialRepository() : base(DbPath.GetTransactionDbPath())
        {
        }
        public DefaultTraitsPerTrialRepository(SQLiteAsyncConnection connection) : base(connection)
        {
        }

        public async Task<List<DefaultTraitsPerTrial>> GetAsync(int ezid)
        {
            var data = await DbContextAsync().QueryAsync<DefaultTraitsPerTrial>("select * from DefaultTraitsPerTrial where EZID = ? order by [Order]", ezid);
            return data;
        }

        public async Task<bool> SaveAsync(List<DefaultTraitsPerTrial> args)
        {
            try
            {
                //Clear all and add new
                await DbContextAsync().ExecuteAsync("Delete from DefaultTraitsPerTrial Where EZID = ?", args.FirstOrDefault().EZID);
                await DbContextAsync().InsertAllAsync(args);

                return true;
            }
            catch
            {
                return false;
            }
        }
    }
}
