using Enza.DataAccess;
using SQLite;
using TrialApp.Common;
using TrialApp.Entities.Master;

namespace TrialApp.DataAccess
{
    public class PropertyOfEntityRepository : Repository<PropertyOfEntity>
    {
        public PropertyOfEntityRepository() : base(DbPath.GetMasterDbPath())
        {
        }

        public PropertyOfEntityRepository(SQLiteAsyncConnection connection) : base(connection)
        {
        }

    }
}
