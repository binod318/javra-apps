using System;
using System.Collections;
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
    
    public class CropRdService
    {
        private CropRdRepository _repoAsync;
        private readonly CropRdRepository _repoSync;

        public CropRdService()
        {
            _repoAsync = new CropRdRepository(new SQLiteAsyncConnection(DbPath.GetMasterDbPath()));
            _repoSync = new CropRdRepository();
        }

        public CropRD GetCropRd(string crop)
        {
            return _repoSync.GetCropRd(crop);
        }

        public async Task<List<CropRD>> GetCropListAsync(string downloadedCropList)
        {
            return await _repoAsync.GetCropListAsync(downloadedCropList);
        }
    }
}
