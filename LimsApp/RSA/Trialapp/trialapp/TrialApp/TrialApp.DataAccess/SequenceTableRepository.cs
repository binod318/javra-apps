using Enza.DataAccess;
using TrialApp.Common;
using SQLite;
using TrialApp.Entities.Master;
using System.Linq;

namespace TrialApp.DataAccess
{
    public class SequenceTableRepository : Repository<SequenceTable>
    {
        public SequenceTableRepository() : base(DbPath.GetMasterDbPath())
        {
        }
        public SequenceTableRepository(SQLiteAsyncConnection connection) : base(connection)
        {
        }

        public SequenceTable GetMaxSequence(string tableName)
        {
            var data =
               DbContext().Query<SequenceTable>("SELECT Sequence from SequenceTable WHERE TableName = ?", tableName)
                   .FirstOrDefault();
            return data;
        }

    }
}
