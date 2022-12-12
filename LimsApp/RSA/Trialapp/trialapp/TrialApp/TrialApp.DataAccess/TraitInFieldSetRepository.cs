using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Enza.DataAccess;
using SQLite;
using TrialApp.Common;
using TrialApp.Entities.Master;

namespace TrialApp.DataAccess
{
    public class TraitInFieldSetRepository : Repository<TraitInFieldSet>
    {
        public TraitInFieldSetRepository(SQLiteAsyncConnection connection) : base(connection)
        {
        }
        public TraitInFieldSetRepository() : base(DbPath.GetMasterDbPath())
        {
        }

        public IEnumerable<TraitInFieldSet> GetTraitInFieldSets(int fieldsetId)
        {
            var traitInFieldSet =
                DbContext().Query<TraitInFieldSet>("select * from TraitInFieldSet where FieldSetID = ?", fieldsetId);
            return traitInFieldSet;
        }
    }
}
