using System.Collections.Generic;
using System.Threading.Tasks;
using Enza.DataAccess;
using SQLite;
using TrialApp.Common;
using TrialApp.Entities.Master;

namespace TrialApp.DataAccess
{
    public class CropSegmentRepository : Repository<CropSegment>
    {
        public CropSegmentRepository() : base(DbPath.GetMasterDbPath())
        {
        }

        public CropSegmentRepository(SQLiteAsyncConnection connection) : base(connection)
        {
        }

        public async Task<List<CropSegment>> GetCropSegmentListAsync(string downloadedList)
        {
            var data = await DbContextAsync().QueryAsync<CropSegment>("select * from CropSegment where CropSegmentCode in ( " + downloadedList + ")");
            return data;
        }
    }
}
