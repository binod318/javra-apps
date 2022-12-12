using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Enza.DataAccess;
using SQLite;
using TrialApp.Common;
using TrialApp.Entities.Transaction;

namespace TrialApp.DataAccess
{
    public interface IObservationAppRepository
    {
        /// <summary>
        /// return latest single row data for provided ezid and traitid
        /// </summary>
        /// <param name="ezId"></param>
        /// <param name="traitId"></param>
        /// <returns></returns>
        ObservationAppLookup GetObservations(string ezId, int traitId);


        /// <summary>
        /// return modified observation under single trial
        /// </summary>
        /// <param name="trialId"></param>
        /// <returns></returns>
        Task<List<ObservationAppLookup>> GetModifiedObservationsForTrialAsync(int trialId);


        /// <summary>
        /// Load Traits list which have observation data of provided EZIDs on parameter
        /// </summary>
        /// <param name="EZIDs"> Comma seperated EZIDs</param>
        /// <returns></returns>
        Task<List<ObservationAppLookup>> LoadTraitsHavingObservation(string ezids);

        /// <summary>
        /// provide latest observation data for EZID and TraitID which can be multiple in comma seperated values
        /// </summary>
        /// <param name="ezId"> Comma seperated ezid if multiple.</param>
        /// <param name="traitId"> Comma seperated traitID if multiple.</param>
        /// <returns></returns>
        Task<List<ObservationAppLookup>> GetObservationAll(string ezId, string traitId);

        Task<object> GetHistoryData(List<int> traits, string ezid);

        Task<List<ObservationAppLookup>> GetObservationPropAll(string ezId, string traitId);


        Task<List<ObservationAppLookup>> GetHistoryObservation(string ezId, string traitId);

        Task UpdateObservationValue(ObservationAppLookup observation);
        //Only for property
        Task UpdateObservationValueForProperty(ObservationAppLookup observation);

        Task InsertObservationValue(ObservationAppLookup observation);
        Task<List<ObservationAppLookup>> LoadObservationUsingQuery(string querystring);
        Task<List<ObservationAppCalculatedSum>> GetCumulatedObsValueAsync(string ezid, string traitid);

        Task<bool> SaveObservationDataAsync(List<ObservationAppLookup> obsData);
    }
}
