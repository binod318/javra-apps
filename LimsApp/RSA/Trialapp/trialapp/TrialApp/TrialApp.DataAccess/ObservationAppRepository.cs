using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Enza.DataAccess;
using SQLite;
using TrialApp.Common;
using TrialApp.Entities.Transaction;

namespace TrialApp.DataAccess
{
    public class ObservationAppRepository : Repository<ObservationAppLookup>, IObservationAppRepository
    {
        public ObservationAppRepository() : base(DbPath.GetTransactionDbPath())
        {
        }

        public ObservationAppRepository(SQLiteAsyncConnection connection) : base(connection)
        {
        }
        /// <summary>
        /// return latest single row data for provided ezid and traitid
        /// </summary>
        /// <param name="ezId"></param>
        /// <param name="traitId"></param>
        /// <returns></returns>
        public ObservationAppLookup GetObservations(string ezId, int traitId)
        {
            var obsData = DbContext().Query<ObservationAppLookup>(
                " SELECT * from [ObservationApp] AS [data] where "
                + " case when (select max (DateCreated) from observationapp where  EZID = [data].EZID  and TraitID = [data].TraitID and modified = 1 )  is not null "
                + " then DateCreated = (select max (DateCreated) from observationapp where  EZID = [data].EZID  and TraitID = [data].TraitID and modified = 1 )  and modified = 1 "
                + " else case when (select DateCreated from observationapp where  EZID = [data].EZID  and TraitID = [data].TraitID and observationid is null) is not null "
                + " then  DateCreated = (select max (DateCreated) from observationapp where  EZID = [data].EZID  and TraitID = [data].TraitID and observationid is null) "
                + " else case when  ( select DateCreated from observationapp where  EZID = [data].EZID  and TraitID = [data].TraitID  and DateCreated = date('now')) is not null "
                + " then DateCreated = ( select DateCreated from observationapp where  EZID = [data].EZID  and TraitID = [data].TraitID  and DateCreated = date('now'))  end end end "
                + " and [data].traitId = ? and  [data].ezid= ? ", traitId, ezId).FirstOrDefault();
            return obsData;
        }

        /// <summary>
        /// return modified observation under single trial
        /// </summary>
        /// <param name="trialId"></param>
        /// <returns></returns>
        public async Task<List<ObservationAppLookup>> GetModifiedObservationsForTrialAsync(int trialId)
        {
            var obsData = await DbContextAsync().QueryAsync<ObservationAppLookup>(
                "select EZID, TraitID from ObservationApp O join Relationship R ON R.EZID2 = O.EZID WHERE R.EZID1 = ? and O.Modified = ?", trialId, true);
            return obsData;
        }


        /// <summary>
        /// Load Traits list which have observation data of provided EZIDs on parameter
        /// </summary>
        /// <param name="EZIDs"> Comma seperated EZIDs</param>
        /// <returns></returns>
        public async Task<List<ObservationAppLookup>> LoadTraitsHavingObservation(string ezids)
        {
            return await DbContextAsync().QueryAsync<ObservationAppLookup>("SELECT TraitID FROM  ObservationApp WHERE EZID in ( " + ezids + " )");
        }

        /// <summary>
        /// provide latest observation data for EZID and TraitID which can be multiple in comma seperated values
        /// </summary>
        /// <param name="ezId"> Comma seperated ezid if multiple.</param>
        /// <param name="traitId"> Comma seperated traitID if multiple.</param>
        /// <returns></returns>
        public async Task<List<ObservationAppLookup>> GetObservationAll(string ezId, string traitId)
        {
            var query =
                " SELECT * from [ObservationApp] AS [data] where "
                + " case when (select max (DateCreated) from observationapp where  EZID = [data].EZID  and TraitID = [data].TraitID and modified = 1 )  is not null "
                + " then DateCreated = (select max (DateCreated) from observationapp where  EZID = [data].EZID  and TraitID = [data].TraitID and modified = 1 )  and modified = 1 "
                + " else case when (select DateCreated from observationapp where  EZID = [data].EZID  and TraitID = [data].TraitID and observationid is null) is not null "
                + " then  DateCreated = (select max (DateCreated) from observationapp where  EZID = [data].EZID  and TraitID = [data].TraitID and observationid is null) and ObservationID is null "
                + " else case when  ( select max (DateCreated) from observationapp where  EZID = [data].EZID  and TraitID = [data].TraitID) is not null "
                + " then DateCreated= ( select max (DateCreated) from observationapp where  EZID = [data].EZID  and TraitID = [data].TraitID)  end end end "
                + " and [data].traitId in ( " + traitId + " )";
            if (!string.IsNullOrEmpty(ezId))
                query += " and [data].ezid in ( " + ezId + " )";
            var obsData = await DbContextAsync().QueryAsync<ObservationAppLookup>(query);
            return obsData;
        }

        public async Task<ObservationAppLookup> GetObservationDateByUserByDate(string dateCreated, string userIDCreated, string ezId, int tID)
        {
            var query = "select * from ObservationApp where ezid = '" + ezId + "' and traitid = '" + tID + "' and UserIDCreated = '" + userIDCreated + "' and dateCreated = '" + dateCreated + "'";
            var result = await DbContextAsync().QueryAsync<ObservationAppLookup>(query);
            if (result.Any())
                return result.FirstOrDefault();
            else
                return null;
        }

        public async Task<object> GetHistoryData(List<int> traits, string ezid)
        {
            var query = " select distinct datecreated, useridcreated  from observationapp as v1  join Relationship on Relationship.[EZID2] = v1.[EZID] where Relationship.[EZID1] = " + ezid;
            var endQuery = " ) order by Date(v1.datecreated) desc ";
            for (int i = 0; i < traits.Count; i++)
            {
                if (i == 0)
                    query = query + "  and  ( v1.traitId = " + traits[i] + (traits.Count == 1 ? endQuery : string.Empty);
                else if (i == traits.Count - 1)
                    query = query + " or v1.traitId = " + traits[i] + endQuery;
                else
                    query = query + " or v1.traitId = " + traits[i];
            }
            var data = await DbContextAsync().QueryAsync<ObservationApp>(query);
            data.Insert(0, new ObservationApp { DateCreated = "All Latest", UserIDCreated = "Observations" });
            return data;
        }

        public async Task<List<ObservationAppLookup>> GetObservationPropAll(string ezId, string traitId)
        {
            var query =
                " SELECT * from [ObservationApp] AS [data] where "
                + " [data].traitId in ( " + traitId + " )";
            if (!string.IsNullOrEmpty(ezId))
                query += " and [data].ezid in ( " + ezId + " )";
            query = query + "  order by dateupdated desc";
            var obsData = await DbContextAsync().QueryAsync<ObservationAppLookup>(query);

            obsData = obsData.GroupBy(x => x.TraitID) 
                 .Select(group => group.First()).ToList();
            return obsData;
        }


        public async Task<List<ObservationAppLookup>> GetHistoryObservation(string ezId, string traitId)
        {
            var query = "SELECT * from ObservationApp WHERE EZID = " + ezId + " AND TraitID = " + traitId + " AND Modified = 0 ORDER BY DateCreated DESC, ObservationID DESC";
            var obsData = await DbContextAsync().QueryAsync<ObservationAppLookup>(query);
            return obsData;
        }
        public async Task<List<ObservationAppLookup>> GetHistoryObservationDates(string ezId, string traitIds)
        {
            var query = "SELECT * from ObservationApp WHERE EZID = " + ezId + " AND TraitID IN (" + traitIds+ ") ORDER BY DateCreated DESC, ObservationID DESC";
            var obsData = await DbContextAsync().QueryAsync<ObservationAppLookup>(query);
            return obsData;
        }

        public async Task UpdateObservationValue(ObservationAppLookup observation)
        {

            //observation = CheckThaiRegion(observation);
            var result = await DbContextAsync().ExecuteAsync("update ObservationApp set ObsValueChar = ?, ObsValueDate = ?, ObsValueDecImp = ? , ObsValueDecMet = ? , ObsValueInt = ? , UoMCode = ?, Modified = ?" +
                                               "where EZID = ? and TraitID = ?  and Modified = true and DATE(DateCreated) =DATE('" + observation.DateCreated + "')",
                               observation.ObsValueChar,
                               observation.ObsValueDate,
                               observation.IsNullEntry ? null : ((UnitOfMeasure.SystemUoM == "Imperial") ? observation.ObsValueDec : null),
                               observation.IsNullEntry ? null : ((UnitOfMeasure.SystemUoM == "Metric") ? observation.ObsValueDec : null),
                               observation.IsNullEntry ? null : observation.ObsValueInt,
                               string.IsNullOrEmpty(observation.UoMCode) ? null : observation.UoMCode,
                               true,
                               observation.EZID,
                               observation.TraitID
                              );
        }

        //private ObservationAppLookup CheckThaiRegion(ObservationAppLookup observation)
        //{
        //    if (CultureInfo.CurrentCulture.Name.ToLower().Contains("th"))
        //    {
        //        var grgDate = new DateTime();
        //        if (!string.IsNullOrEmpty(observation.DateCreated))
        //        {
        //            grgDate = DateTime.Parse(observation.DateCreated);
        //            observation.DateCreated = grgDate.AddYears(-1086).ToString();
        //        }
        //        if (!string.IsNullOrEmpty(observation.ObsValueDate))
        //        {
        //             grgDate = DateTime.Parse(observation.ObsValueDate);
        //            observation.ObsValueDate = grgDate.AddYears(-1086).ToString();
        //        }
        //        if (!string.IsNullOrEmpty(observation.DateUpdated))
        //        {
        //            grgDate = DateTime.Parse(observation.DateUpdated);
        //            observation.DateUpdated = grgDate.AddYears(-1086).ToString();
        //        }
        //    }
        //    return observation;
        //}

        //Only for property
        public async Task UpdateObservationValueForProperty(ObservationAppLookup observation)
        {
           //observation = CheckThaiRegion(observation);
            await DbContextAsync().ExecuteAsync("update ObservationApp set ObsValueChar = ?, ObsValueDate = ?, ObsValueDecImp = ? , ObsValueDecMet = ? , ObsValueInt = ? , UoMCode = ?, Modified = ? " +
                                            "where EZID = ? and TraitID = ? ",
                            observation.ObsValueChar,
                            observation.ObsValueDate,
                            (UnitOfMeasure.SystemUoM == "Imperial") ? observation.ObsValueDec : null,
                            (UnitOfMeasure.SystemUoM == "Metric") ? observation.ObsValueDec : null,
                            observation.ObsValueInt,
                            string.IsNullOrEmpty(observation.UoMCode) ? null : observation.UoMCode,
                            true,
                            observation.EZID,
                            observation.TraitID);
        }

        public async Task InsertObservationValue(ObservationAppLookup observation)
        {
            //observation = CheckThaiRegion(observation);
            var data = new ObservationApp()
            {
                DateCreated = observation.DateCreated,
                DateUpdated = observation.DateUpdated,
                EZID = observation.EZID,
                Modified = observation.Modified,
                ObservationId = observation.ObservationId,
                ObsValueChar = observation.ObsValueChar,
                ObsValueDate = observation.ObsValueDate,
                ObsValueInt = observation.IsNullEntry ? null : observation.ObsValueInt,
                TraitID = observation.TraitID,
                UserIDCreated = observation.UserIDCreated,
                UserIDUpdated = observation.UserIDUpdated,
                ObsValueDecImp = observation.IsNullEntry ? null : observation.ObsValueDecImp,
                ObsValueDecMet = observation.IsNullEntry ? null : observation.ObsValueDecMet,
                UoMCode = string.IsNullOrEmpty(observation.UoMCode) ? null : observation.UoMCode
            };

            await DbContextAsync().InsertOrReplaceAsync(data);
        }

        public async Task<List<ObservationAppLookup>> LoadObservationUsingQuery(string querystring)
        {
            var decQuery = UnitOfMeasure.SystemUoM == "Imperial"
                ? "IFNULL(ObsValueDecImp, '') != '' THEN ObsValueDecImp"
                : "IFNULL(ObsValueDecMet, '') != '' THEN ObsValueDecMet";

            var query = @"SELECT TraitID, EZID, ObsValueDate,
                        CAST (
                            CASE
                            WHEN IFNULL(ObsValueChar, '') != '' THEN ObsValueChar
                            WHEN " + decQuery +
                            @" WHEN IFNULL(ObsValueInt, '') != '' THEN ObsValueInt
                            WHEN IFNULL(ObsValueDate, '') != '' THEN ObsValueDate
                            ELSE ''
                        END AS TEXT ) AS FinalObsValue
                        from ObservationApp WHERE " + querystring;

            var data = await DbContextAsync().QueryAsync<ObservationAppLookup>(query);
            return data;
        }

        public async Task<List<ObservationAppCalculatedSum>> GetCumulatedObsValueAsync(string ezid, string traitid)
        {
            var decQuery = UnitOfMeasure.SystemUoM == "Imperial" ? "ObsValueDecImp" : "ObsValueDecMet";
            var query = @"SELECT SUM(Cumulated) AS CalculatedSum, TraitID FROM
                        ( 
                          SELECT 
                                EZID, 
                                TraitID, 
                                IFNULL(" + decQuery + @",0) AS Cumulated
                          FROM ObservationApp OA WHERE EZID = " + ezid + " and TraitID in ( " + traitid + " ) " +
                        ") GROUP BY TraitID";
            var data = await DbContextAsync().QueryAsync<ObservationAppCalculatedSum>(query);
            return data;
        }

        public async Task<bool> SaveObservationDataAsync(List<ObservationAppLookup> obsData)
        {
            try
            {
                var ezidlist = string.Join(",", obsData.Select(x => "'" + x.EZID.ToString() + "'").Distinct());
                var traitidlist = string.Join(",", obsData.Select(x => x.TraitID.ToString()).Distinct());

                var allObservations = await GetObservationAll(ezidlist, traitidlist);

                foreach (var obs in obsData)
                {
                    //Check if Observation for same EZID/TraitID/Date already exists
                    var existingdata = allObservations.FirstOrDefault(o => o.EZID == obs.EZID && o.TraitID == obs.TraitID && o.Modified && o.DateCreated == obs.DateCreated);

                    // Update
                    if (existingdata != null)
                        await UpdateObservationValue(obs); //ObservationService.UpdateObservationData(observation);
                                                           // Create new
                    else
                        await InsertObservationValue(obs); //ObservationService.InsertObservationData(observation);
                }
            }
            catch (Exception)
            {
                return false;
            }

            return true;
        }
    }
}
