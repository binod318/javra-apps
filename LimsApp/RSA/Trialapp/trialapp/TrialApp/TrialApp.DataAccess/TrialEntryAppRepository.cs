using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Enza.DataAccess;
using SQLite;
using TrialApp.Common;
using TrialApp.Entities.Transaction;

namespace TrialApp.DataAccess
{
    public class TrialEntryAppRepository : Repository<TrialEntryApp>
    {
        public TrialEntryAppRepository() : base(DbPath.GetTransactionDbPath())
        {
        }

        public TrialEntryAppRepository(SQLiteAsyncConnection connection) : base(connection)
        {
        }
        public async Task<List<TrialEntryApp>> GetVarietiesListAsync(int ezid)
        {
            var trialEntry = await DbContextAsync().QueryAsync<TrialEntryApp>("select * from TrialEntryApp join Relationship on TrialEntryApp.EZID = Relationship.EZID2 where Relationship.EZID1 = ? and IsHidden = 0 order by TrialEntryApp.FieldNumber", ezid);
            return trialEntry;
        }

        public async Task<int> AddTrialEntryWithRelationshipAsync(TrialEntryApp TE, Relationship R)
        {
            if (await DbContextAsync().InsertAsync(TE) > 0)
                return await DbContextAsync().InsertAsync(R);
            return 0;

        }

        public async Task<TrialEntryApp> GetVarietiesInfoAsync(string ezid)
        {
            var trialEntry = await DbContextAsync().QueryAsync<TrialEntryApp>("select * from TrialEntryApp where TrialEntryApp.EZID = ?", ezid);
            return trialEntry.FirstOrDefault();
        }

        public async Task<List<TrialEntryApp>> GetTrialEntriesByNameAsync(string ezid, string fieldnr, string name)
        {
            var trialEntry = await DbContextAsync().QueryAsync<TrialEntryApp>("SELECT * FROM TrialEntryApp WHERE ( FieldNumber = '" + fieldnr + "' OR VarietyName = '" + name + "' COLLATE NOCASE )" + "AND EZID IN ( SELECT EZID2 from Relationship where EZID1 = " + ezid + ")");
            return trialEntry;
        }

        public async Task<bool> DeleteVarietyAsync(string ezid)
        {
            await DbContextAsync().ExecuteAsync("DELETE FROM RelationShip WHERE EZID2 = ?", ezid);
            await DbContextAsync().ExecuteAsync("DELETE FROM TrialEntryApp WHERE EZID = ?", ezid);
            return true;
        }


        public async Task<bool> HideVarietyAsync(string ezid, int trialEzid)
        {
            await DbContextAsync().ExecuteAsync("UPDATE TrialEntryApp SET IsHidden = 1 WHERE EZID = ?", ezid);
            await DbContextAsync().ExecuteAsync("UPDATE Trial set StatusCode = ? WHERE EZID = ?", "30", trialEzid);
            return true;
        }

        public async Task SaveTrialEntryAppAsync(List<TrialEntryApp> trialEntryApps)
        {
            foreach (var trialEntry in trialEntryApps)
            {
                await DbContextAsync().InsertOrReplaceAsync(trialEntry);
            }
        }
    }
}
