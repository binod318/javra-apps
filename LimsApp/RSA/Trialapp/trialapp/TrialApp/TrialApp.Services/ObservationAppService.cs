using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SQLite;
using TrialApp.Common;
using TrialApp.DataAccess;
using TrialApp.Entities.Transaction;

namespace TrialApp.Services
{
    public class ObservationAppService
    {
        private ObservationAppRepository _repoAsync;
        private ObservationAppRepository _repoSync;
        private ObservationAppRepository1 _repo1;
        public ObservationAppService()
        {
            _repoAsync = new ObservationAppRepository(new SQLiteAsyncConnection(DbPath.GetTransactionDbPath()));
            _repoSync = new ObservationAppRepository();
            _repo1 = new ObservationAppRepository1();

        }

        public ObservationAppLookup GetObservationData(string ezId, int traitId)
        {
            var obsData = _repoSync.GetObservations(ezId, traitId);
            return obsData;
        }

        public async Task<List<ObservationAppLookup>> GetModifiedObservationsForTrialAsync(int trialId)
        {
            return await _repoAsync.GetModifiedObservationsForTrialAsync(trialId);
        }
        
        public async Task GetObservationForSelectedTraits(List<Entities.Master.Trait> traits, List<dynamic> itemsSource, string historyVal, int ezID, Dictionary<string, int> indexedEzids)
        {
            await _repo1.GetObsevationdataAsync(traits,itemsSource,historyVal,ezID, indexedEzids);

        }

        public async Task<List<ObservationAppLookup>> GetObservationDataAll(string ezId, string traitId)
        {
            var obsData = await _repoAsync.GetObservationAll(ezId, traitId);
            return obsData;
        }

        public async Task<List<ObservationAppLookup>> GetObservationPropDataAll(string ezId, string traitId)
        {
            var obsData = await _repoAsync.GetObservationPropAll(ezId, traitId);
            return obsData;
        }
        

        public async Task<List<ObservationAppLookup>> GetHistoryObservation(string ezId, string traitId)
        {
            var obsData = await _repoAsync.GetHistoryObservation(ezId, traitId);
            return obsData;
        }
        public async Task<List<ObservationAppLookup>> GetHistoryObservationDates(string ezId, string traitIds)
        {
            var obsData = await _repoAsync.GetHistoryObservationDates(ezId, traitIds);
            return obsData;
        }

        public async Task UpdateObservationData(ObservationAppLookup observation)
        {
            await _repoAsync.UpdateObservationValue(observation);
        }

        public async Task UpdateObservationDataForProperty(ObservationAppLookup observation)
        {
            await _repoAsync.UpdateObservationValueForProperty(observation);
        }

        public async Task InsertObservationData(ObservationAppLookup observation)
        {
            await _repoAsync.InsertObservationValue(observation);
        }
        /// <summary>
        /// Load Traits list which have observation data of provided EZIDs on parameter
        /// </summary>
        /// <param name="EZIDs"> Comma seperated EZIDs</param>
        /// <returns></returns>
        public async Task<List<ObservationAppLookup>> LoadTraitsHavingObservation(string ezids)
        {
            return await _repoAsync.LoadTraitsHavingObservation(ezids);
        }

        public async Task<List<ObservationAppLookup>> LoadPropertiesHavingObservation(string ezids)
        {
            return await _repoAsync.LoadTraitsHavingObservation(ezids);
        }

        public async Task<List<ObservationAppLookup>> LoadObservationUsingQuery(string querystring)
        {
            return await _repoAsync.LoadObservationUsingQuery(querystring);
        }

        public async Task<List<ObservationAppCalculatedSum>> GetCumulatedObsValueAsync(string ezid, string traitId)
        {
            return await _repoAsync.GetCumulatedObsValueAsync(ezid, traitId);
        }

        public async Task<object> GetHistoryData(List<int> traits , string ezid)
        {
            return await _repoAsync.GetHistoryData(traits, ezid);
        }

        public async Task<bool> SaveObservationDataAsync(List<ObservationAppLookup> obsData)
        {
            return await _repoAsync.SaveObservationDataAsync(obsData);
        }

        public async Task<ObservationAppLookup> GetObservationDateByUserByDate(string dateCreated, string userIDCreated, string ezId, int tID)
        {
            return  await _repoAsync.GetObservationDateByUserByDate(dateCreated, userIDCreated, ezId, tID);
        }
    }
}
