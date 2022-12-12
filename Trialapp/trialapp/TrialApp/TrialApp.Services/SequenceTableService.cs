using SQLite;
using System.Linq;
using System.Threading.Tasks;
using TrialApp.Common;
using TrialApp.DataAccess;
using TrialApp.Entities.Master;

namespace TrialApp.Services
{

    public class SequenceTableService
    {
        private SequenceTableRepository repo;
        private SequenceTableRepository repoAsync;

        public SequenceTableService()
        {
            repo = new SequenceTableRepository();
            repoAsync = new SequenceTableRepository(new SQLiteAsyncConnection(DbPath.GetMasterDbPath()));
        }

        public async Task<int> GetMaxSequence(string tableName)
        {
            if (tableName == "ProgramFieldSetField")
                tableName = "ProgramFieldSetFields";
            int maxVal;
            var data = repo.GetMaxSequence(tableName);
            if (data == null)
            {
                var newdata = new SequenceTable();
                newdata.TableName = tableName;
                newdata.Sequence = 0;
                await repoAsync.DbContextAsync().InsertOrReplaceAsync(newdata);
                maxVal = 0;
            }
            else
                maxVal = data.Sequence;
            return maxVal;
        }

        public async Task SetMaxVal(string tableName, int maxVal)
        {
            if (tableName == "ProgramFieldSetField")
                tableName = "ProgramFieldSetFields";
            var newseq = new SequenceTable
            {
                TableName = tableName,
                Sequence = maxVal
            };
            await repoAsync.DbContextAsync().InsertOrReplaceAsync(newseq);
        }


    }

}
