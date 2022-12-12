using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Enza.DataAccess;
using SQLite;
using TrialApp.Common;
using TrialApp.Entities.Master;
using TrialApp.Entities.Transaction;

namespace TrialApp.DataAccess
{
    public class TraitRepository : Repository<Trait>
    {
        public TraitRepository(SQLiteAsyncConnection connection) : base(connection)
        {
        }

        public TraitRepository() : base(DbPath.GetMasterDbPath())
        {
        }

        public Trait GetTraits(int traitId)
        {
            var trait = DbContext().Query<Trait>("select * from Trait where TraitID = ?", traitId).FirstOrDefault();
            return trait;
        }

        public List<Trait> GetTraitsFromFieldset(int fieldsetId)
        {
            var traitList =
                DbContext()
                    .Query<Trait>(
                        "select * from TraitInFieldSet join Trait on TraitInFieldSet.TraitID = Trait.TraitID where TraitInFieldSet.FieldSetID = ? order by TraitInFieldSet.SortingOrder ",
                        fieldsetId);
            return traitList;
        }

        public async Task<List<Trait>> GetAllTraitsAsync(string cropCode)
        {
            var list = await DbContextAsync().QueryAsync<Trait>("SELECT T.* FROM Trait T " +
                                                        "JOIN CropTrait CT ON CT.TraitID = T.TraitID " +
                                                        "WHERE CT.CropCode = ? AND T.[Property] = 0",
                                                        cropCode);
            return list.OrderBy(x=> x.ColumnLabel).ToList();
        }

        /// <summary>
        /// Load Traits list detail provided with traitids in comma seperated format
        /// </summary>
        /// <param name="traitIDs"> Comma seperated TraitIDs</param>
        /// <returns></returns>
        public async Task<List<Trait>> GetTraitsAsync(string traitIDs)
        {
            var uomQuery = UnitOfMeasure.SystemUoM == "Imperial" ? "BaseUnitImp" : "BaseUnitMet";
            return await DbContextAsync().QueryAsync<Trait>("SELECT TraitID,TraitName, CASE  WHEN ('(' || IFNULL(" + uomQuery + ",'') || ')') = '()' THEN ColumnLabel ELSE (ColumnLabel || ' ' || '(' || IFNULL(" + uomQuery + ",'') || ')' ) END As ColumnLabel," +
                                                         "DataType, ListOfValues FROM Trait WHERE TraitID in ( " + traitIDs + " )");
        }

        public async Task<List<Trait>> GetTraitsDetailAsync(string traitIDs)
        {
            return await DbContextAsync().QueryAsync<Trait>("SELECT * FROM Trait WHERE TraitID in ( " + traitIDs + " )");
        }
    }
}
