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
    public class CdmFilterRepository : Repository<CDM_Filter>
    {
        public CdmFilterRepository() : base(DbPath.GetMasterDbPath())
        {
        }

        public CdmFilterRepository(SQLiteAsyncConnection connection) : base(connection)
        {
        }

        public async Task<List<CDM_Filter>> GetCdmFilterList()
        {
            var data = await DbContextAsync().QueryAsync<CDM_Filter>("select * from CDM_Filter where AppName = 'TrialApp'");
            return data;
        }
    }
}
