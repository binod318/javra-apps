using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;
using TrialApp.Entities.Transaction;

namespace TrialApp.Services.Interface
{
    public interface IObservationAppService
    {
        ObservationAppLookup GetObservationData(string ezId, int traitId);

        Task<List<ObservationAppLookup>> GetModifiedObservationsForTrialAsync(int trialId);

        Task GetObservationForSelectedTraits(List<Entities.Master.Trait> traits, List<dynamic> itemsSource, string historyVal, int ezID, Dictionary<string, int> indexedEzids);

        Task<List<ObservationAppLookup>> GetObservationDataAll(string ezId, string traitId);

        Task<List<ObservationAppLookup>> GetObservationPropDataAll(string ezId, string traitId);
        Task<List<ObservationAppLookup>> GetHistoryObservation(string ezId, string traitId);

        Task UpdateObservationData(ObservationAppLookup observation);

        Task UpdateObservationDataForProperty(ObservationAppLookup observation);

        Task InsertObservationData(ObservationAppLookup observation);
        /// <summary>
        /// Load Traits list which have observation data of provided EZIDs on parameter
        /// </summary>
        /// <param name="EZIDs"> Comma seperated EZIDs</param>
        /// <returns></returns>
        Task<List<ObservationAppLookup>> LoadTraitsHavingObservation(string ezids);
        Task<List<ObservationAppLookup>> LoadPropertiesHavingObservation(string ezids);
        Task<List<ObservationAppLookup>> LoadObservationUsingQuery(string querystring);

        Task<List<ObservationAppCalculatedSum>> GetCumulatedObsValueAsync(string ezid, string traitId);

        Task<object> GetHistoryData(List<int> traits, string ezid);
        Task<bool> SaveObservationDataAsync(List<ObservationAppLookup> obsData);
    }
}
