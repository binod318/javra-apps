using Enza.DataAccess;
using SQLite;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using TrialApp.Common;
using TrialApp.Entities.Transaction;

namespace TrialApp.DataAccess
{
    public class SettingParametersRepository : Repository<SettingParameters>
    {
        public SettingParametersRepository() : base(DbPath.GetTransactionDbPath())
        {
        }
        public SettingParametersRepository(SQLiteAsyncConnection connection) : base(connection)
        {
        }

        public async Task<List<SettingParameters>> GetAllAsync()
        {
            var settingparams = await DbContextAsync().QueryAsync<SettingParameters>("Select * from SettingParameters");
            return settingparams;
        }

        public List<SettingParameters> GetList()
        {
            var settingparams = DbContext().Query<SettingParameters>("select * from SettingParameters");
            return settingparams;
        }

        public void UpdateSettingParams(string field, string fieldvalue)
        {
            switch (field)
            {
                case "endpoint":
                    DbContext().Execute("update SettingParameters set Endpoint = ?", fieldvalue);
                    break;

                case "filter":
                    DbContext().Execute("update SettingParameters set Filter = ?", fieldvalue);
                    break;

                case "measuringsystem":
                    DbContext().Execute("update SettingParameters set UoM = ?", fieldvalue);
                    break;
                case "defaultlayout":
                    DbContext().Execute("update SettingParameters set DefaultLayout = ?", fieldvalue);
                    break;

                case "displaypropertyid":
                    DbContext().Execute("update SettingParameters set DisplayPropertyID = ?", fieldvalue);
                    break;
                case "loggedinuser":
                    DbContext().Execute("update SettingParameters set LoggedInUser = ?", fieldvalue);
                    break;
                case "IsRegistered":
                    DbContext().Execute("update SettingParameters set IsRegistered = ?", fieldvalue);
                    break;
            }

        }

        public List<int> GetEZIDsFromNotification()
        {
            var list = new List<int>();
            var result = DbContext().Query<NotificationLog>("select EZID from NotificationLog");

            foreach (var item in result) { list.Add(item.EZID); }
            return list;

        }

        public bool CheckNotification()
        {
            var avail = DbContext().ExecuteScalar<bool>("SELECT CASE WHEN (SELECT name FROM sqlite_master WHERE type='table' AND name='NotificationLog' ) IS NOT NULL THEN  1 ELSE 0 END");
            if (!avail)
                DbContext().Execute("CREATE TABLE 'NotificationLog' ('EZID'	INTEGER,'FromNotification'	BIT );");
            // DbContext().Execute("INSERT INTO NotificationLog VALUES ( 7795999, 1)");
            DbContext().Commit();
            return DbContext().ExecuteScalar<bool>("SELECT CASE WHEN (select EZID from NotificationLog LIMIT 1 ) IS NOT NULL THEN  1 ELSE 0 END");
        }

        public void DeleteNotificationLog(string ezids)
        {
            DbContext().ExecuteScalar<bool>("DELETE FROM NotificationLog WHERE EZID in ( " + ezids + " )");
        }
    }

    public class NotificationLog
    {
        public int EZID { get; set; }
    }
}
