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
    public class TrialTypeRepository : Repository<TrialType>
    {
        public TrialTypeRepository() : base(DbPath.GetMasterDbPath())
        {
        }

        public TrialTypeRepository(SQLiteAsyncConnection connection) : base(connection)
        {
        }

        public async Task<List<TrialType>> GetTrialTypeListAsync(string downloadedTrialTypeList)
        {
            var data = await DbContextAsync().QueryAsync<TrialType>("select * from TrialType where TrialTypeID in (" + downloadedTrialTypeList + ")");
            return data;
        }

        public async Task<List<TrialType>> GetAllTrialTypesAsync()
        {
            var data = await DbContextAsync().QueryAsync<TrialType>("select * from TrialType");
            return data;
        }

        public List<TrialType> GetAllTrialTypes()
        {
            var data = DbContext().Query<TrialType>("select * from TrialType");
            return data;
        }
    }
}
