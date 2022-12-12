using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Enza.DataAccess;
using SQLite;
using TrialApp.Common;
using TrialApp.Entities.Master;

namespace TrialApp.DataAccess
{
    public class CropRdRepository : Repository<CropRD>
    {
        public CropRdRepository() : base(DbPath.GetMasterDbPath())
        {
        }

        public CropRdRepository(SQLiteAsyncConnection connection) : base(connection)
        {
        }

        public CropRD GetCropRd(string cropCode)
        {
            return DbContext().Query<CropRD>("select * from CropRD where CropCode = ?", cropCode).FirstOrDefault();
        }

        public async Task<List<CropRD>> GetCropListAsync(string downloadedCropList)
        {
            var data = await DbContextAsync().QueryAsync<CropRD>("select * from CropRD where CropCode in ( " + downloadedCropList + ")");
            return data;
        }
    }
}
