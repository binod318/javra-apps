using Enza.DataAccess;
using SQLite;
using TrialApp.Common;
using TrialApp.Entities.Master;

namespace TrialApp.DataAccess
{
    public class TraitTypeRepository : Repository<TraitType>
    {
        public TraitTypeRepository() : base(DbPath.GetMasterDbPath())
        {
        }

        public TraitTypeRepository(SQLiteAsyncConnection connection) : base(connection)
        {
        }

    }
}
