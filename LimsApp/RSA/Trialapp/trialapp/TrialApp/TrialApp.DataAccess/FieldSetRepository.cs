using Enza.DataAccess;
using SQLite;
using System.Collections.Generic;
using System.Threading.Tasks;
using TrialApp.Common;
using TrialApp.Entities.Master;

namespace TrialApp.DataAccess
{
    public class FieldSetRepository : Repository<FieldSet>
    {
        public FieldSetRepository() : base(DbPath.GetMasterDbPath())
        {
        }
        public FieldSetRepository(SQLiteAsyncConnection connection) : base(connection)
        {
        }

        public void InsertAll(List<FieldSet> fieldsetList, SQLiteConnection db)
        {
            db.InsertAll(fieldsetList);
        }

        public List<FieldSet> Get(string cropCode)
        {
            return DbContext().Query<FieldSet>(@"SELECT * FROM FieldSet WHERE [NormalTrait] = 1 and CropCode = ? ORDER BY FieldSetCode", cropCode);
            
        }

        public List<FieldSet> GetProperty(string cropCode)
        {
            var propertySet = DbContext().Query<FieldSet>(@"SELECT * FROM FieldSet WHERE [NormalTrait] = 0 and [Property] = 1 and CropCode = ? ORDER BY FieldSetCode",
                                            cropCode);
            return propertySet;
        }
        //
        public List<FieldSet> GetStatusProperty()
        {
            var propertySet = DbContext().Query<FieldSet>(@"select * from TraitValue where TraitID = 4185 ");
            return propertySet;
        }
    }

}
