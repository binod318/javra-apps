using Enza.DataAccess;
using SQLite;
using TrialApp.Common;
using TrialApp.Entities.Master;

namespace TrialApp.DataAccess
{
    public class CropLovRepository : Repository<CropLov>
    {
        public CropLovRepository(SQLiteAsyncConnection connection) : base(connection)
        {
        }

        public CropLovRepository() : base(DbPath.GetMasterDbPath())
        {
        }

    }
}
