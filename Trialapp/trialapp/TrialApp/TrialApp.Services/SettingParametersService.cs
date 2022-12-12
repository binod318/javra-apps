using SQLite;
using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;
using TrialApp.Common;
using TrialApp.DataAccess;
using TrialApp.Entities.Transaction;

namespace TrialApp.Services
{
    public class SettingParametersService
    {
        private SettingParametersRepository repo;
        private SettingParametersRepository repoAsync;

        public SettingParametersService()
        {
            repo = new SettingParametersRepository();
            repoAsync = new SettingParametersRepository(new SQLiteAsyncConnection(DbPath.GetTransactionDbPath()));
        }
        public async Task<List<SettingParameters>> GetAllAsync()
        {
            var orgiList = await repoAsync.GetAllAsync();
            return orgiList;
        }

        public List<SettingParameters> GetParamsList()
        {
            var settingparams = repo.GetList();
            return settingparams;
        }

        public void UpdateParams(string field, string endpoint)
        {
            repo.UpdateSettingParams(field, endpoint);
        }

        public bool CheckNotification()
        {
            var avail = repo.CheckNotification();
            return avail;
        }
        public void DeleteNotificationLog(string ezids)
        {
            repo.DeleteNotificationLog(ezids);
        }

        public List<int> GetEZIDsFromNotification()
        {
            return repo.GetEZIDsFromNotification();

        }
    }
}
