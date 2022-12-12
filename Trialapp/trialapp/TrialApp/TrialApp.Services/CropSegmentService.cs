using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SQLite;
using TrialApp.Common;
using TrialApp.DataAccess;
using TrialApp.Entities.Master;

namespace TrialApp.Services
{
    public class CropSegmentService
    {
        private readonly CropSegmentRepository _repoAsync;
        private readonly CropSegmentRepository _repoSync;

        public CropSegmentService()
        {
            _repoAsync = new CropSegmentRepository(new SQLiteAsyncConnection(DbPath.GetMasterDbPath()));
            _repoSync = new CropSegmentRepository();
        }

        public async Task<List<CropSegment>> GetCropSegmentListAsync(string downloadedList)
        {
            return await _repoAsync.GetCropSegmentListAsync(downloadedList);
        }
    }
}
