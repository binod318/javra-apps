
using SQLite;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using TrialApp.Common;
using TrialApp.DataAccess;
using TrialApp.Entities.Master;

namespace TrialApp.Services
{

    public class TraitValueService
    {
        private TraitValueRepository repo;
        private TraitValueRepository repo1;

        public TraitValueService()
        {
            repo = new TraitValueRepository(new SQLiteAsyncConnection(DbPath.GetMasterDbPath()));
            repo1 = new TraitValueRepository();
        }
        public ObservableCollection<TraitValue> GetTraitValueWithID(int traitID, string cropcode)
        {
            var cmbnull = new TraitValue { TraitValueCode = "" ,TraitValueName= " "};
            var traitValueList =  repo1.GetTraitValueWithID(traitID, cropcode);
            traitValueList.Insert(0, cmbnull);
            return new ObservableCollection<TraitValue>(traitValueList);
        }

        public ObservableCollection<TraitValue> GetTraitValue(int traitID)
        {
            var traitValueList = repo1.GetTraitValue(traitID);
            return new ObservableCollection<TraitValue>(traitValueList);
        }

        public ObservableCollection<TraitValue> GetCropTraitValue(int traitID, string cropCode)
        {
            var traitValueList = repo1.GetCropTraitValue(traitID, cropCode);
            return new ObservableCollection<TraitValue>(traitValueList);
        }
    }

}
