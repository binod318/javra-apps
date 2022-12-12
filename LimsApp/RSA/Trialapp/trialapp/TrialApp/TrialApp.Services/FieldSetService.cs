
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Threading.Tasks;
using SQLite;
using TrialApp.DataAccess;
using TrialApp.Entities.Master;

namespace TrialApp.Services
{
    public class FieldSetService
    {
        private FieldSetRepository repo;
        private readonly CropRdService _cropRdService;
        private TraitValueRepository repo1;

        public FieldSetService()
        {
            repo = new FieldSetRepository();
            _cropRdService = new CropRdService();
            repo1 = new TraitValueRepository();
        }

        internal void Update(List<FieldSet> fieldsetList, SQLiteConnection db)
        {
            repo.InsertAll(fieldsetList, db);
        }

        public List<FieldSet> GetFieldSetList(string cropCode)
        {
            return repo.Get(cropCode);
        }

        public List<FieldSet> GetPropertySetList(string cropCode)
        {
            var propertySetList = repo.GetProperty(cropCode);
            return propertySetList;
        }

        public ObservableCollection<TraitValue> GetStatusSetList( string crop)
        {
            
            var cmbnull = new TraitValue { TraitValueCode = "", TraitValueName = " " };
            var traitValueList = repo1.GetTraitValueWithID(4185, crop);
            traitValueList.Insert(0, cmbnull);
            return new ObservableCollection<TraitValue>(traitValueList);
        }
    }
}
