using Enza.DataAccess;
using SQLite;
using TrialApp.Common;
using TrialApp.Entities.Master;

namespace TrialApp.DataAccess
{
    public class CropTraitRepository : Repository<CropTrait>
    {
        public CropTraitRepository(SQLiteAsyncConnection connection) : base(connection)
        {
        }

        public CropTraitRepository() : base(DbPath.GetMasterDbPath())
        {
        }

    }
}
