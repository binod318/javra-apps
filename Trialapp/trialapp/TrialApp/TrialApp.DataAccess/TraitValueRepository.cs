using Enza.DataAccess;
using TrialApp.Common;
using SQLite;
using TrialApp.Entities.Master;
using System.Collections.Generic;
using System;

namespace TrialApp.DataAccess
{
    public class TraitValueRepository : Repository<TraitValue>
    {
        public TraitValueRepository() : base(DbPath.GetMasterDbPath())
        {
        }
        public TraitValueRepository(SQLiteAsyncConnection connection) : base(connection)
        {
        }

        public List<TraitValue> GetTraitValueWithID(int traitID, string cropcode)
        {
            return DbContext().Query<TraitValue>("select SortingOrder, TraitValueCode ||  '  : '  || TraitValueName as 'TraitValueName' ,  TraitValueCode from  TraitValue where TraitID = ? "
                                                    + " AND TraitValueID IN (SELECT TraitValueID FROM CropLov  WHERE CropCode = ? ) ORDER BY SortingOrder", traitID, cropcode);
        }

        public List<TraitValue> GetTraitValue(int traitID)
        {
            return DbContext().Query<TraitValue>("select * from TraitValue WHERE TraitID = ?", traitID);
        }

        public List<TraitValue> GetCropTraitValue(int traitID, string cropCode)
        {
            return DbContext().Query<TraitValue>("select * from TraitValue WHERE TraitID = ? AND TraitValueID IN (SELECT TraitValueID FROM CropLov WHERE CropCode = ? ) ORDER BY SortingOrder", traitID, cropCode);
        }
    }
}
