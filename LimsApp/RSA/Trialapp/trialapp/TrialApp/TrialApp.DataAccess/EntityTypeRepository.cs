using Enza.DataAccess;
using SQLite;
using TrialApp.Common;
using TrialApp.Entities.Master;

namespace TrialApp.DataAccess
{
    public class EntityTypeRepository : Repository<EntityType>
    {
        public EntityTypeRepository() : base(DbPath.GetMasterDbPath())
        {
        }

        public EntityTypeRepository(SQLiteAsyncConnection connection) : base(connection)
        {
        }

    }
}
