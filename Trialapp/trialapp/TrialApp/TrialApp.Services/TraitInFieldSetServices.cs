using System.Collections.Generic;
using SQLite;
using TrialApp.Common;
using TrialApp.DataAccess;
using TrialApp.Entities.Master;

namespace TrialApp.Services
{
    public class TraitInFieldSetServices
    {
        private TraitInFieldSetRepository repo;
        private TraitInFieldSetRepository repoSync;
        public TraitInFieldSetServices()
        {
            repo = new TraitInFieldSetRepository(new SQLiteAsyncConnection(DbPath.GetMasterDbPath()));
            repoSync = new TraitInFieldSetRepository();
        }

        public IEnumerable<TraitInFieldSet> GetTraitInFieldSetList(int fieldsetId)
        {
            var traitInFieldsetList = repoSync.GetTraitInFieldSets(fieldsetId);
            return traitInFieldsetList;
        }
    }
}
