using Enza.DataAccess;
using SQLite;
using System.Collections.Generic;
using System.Threading.Tasks;
using TrialApp.Common;
using TrialApp.Entities.Transaction;

namespace TrialApp.DataAccess
{
    public class RelationshipRepository : Repository<Relationship>
    {
        public RelationshipRepository() : base(DbPath.GetTransactionDbPath())
        {
        }

        public RelationshipRepository(SQLiteAsyncConnection connection) : base(connection)
        {
        }

        public async Task SaveRelationShipAsync(List<Relationship> relationList)
        {
            foreach (var relationship in relationList)
            {
                await DbContextAsync().InsertOrReplaceAsync(relationship);
            }
        }
    }

}
