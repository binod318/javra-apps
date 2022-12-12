using Enza.DataAccess;
using SQLite;
using TrialApp.Common;
using TrialApp.Entities.Master;

namespace TrialApp.DataAccess
{
    public class CropGroupRepository : Repository<CropGroup>
    {
        public CropGroupRepository() : base(DbPath.GetMasterDbPath())
        {
        }

        public CropGroupRepository(SQLiteAsyncConnection connection) : base(connection)
        {
        }

    }
}
