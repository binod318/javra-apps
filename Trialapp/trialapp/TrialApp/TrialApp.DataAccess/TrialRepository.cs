using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Enza.DataAccess;
using TrialApp.Common;
using TrialApp.Entities.Transaction;
using SQLite;
using TrialApp.Entities.Bdtos.ResultSets;
using TrialApp.Entities.ServiceResponse;
using System.IO;
using Xamarin.Forms;
using System;

namespace TrialApp.DataAccess
{
    public class TrialRepository : Repository<TrialLookUp>
    {
        public TrialRepository() : base(DbPath.GetTransactionDbPath())
        {
        }
        public TrialRepository(SQLiteAsyncConnection connection) : base(connection)
        {
        }

        public async Task<IEnumerable<TrialLookUp>> GetAsync()
        {
            var trials = await DbContextAsync().QueryAsync<TrialLookUp>("Select * from Trial");
            return trials;
        }
      
        public IEnumerable<TrialLookUp> Get()
        {
         
            var trials = DbContext().Query<TrialLookUp>("Select * from Trial");
            return trials;
        }
        
        public override Task<int> AddAsync(TrialLookUp entity)
        {
            return base.AddAsync(entity);
        }
        
        public void UpdateTrialStatus(int _trialEzid)
        {
            DbContext().Execute("UPDATE Trial set StatusCode = ? WHERE EZID = ?", "30", _trialEzid);
        }

        public TrialLookUp Get(int trialId)
        {
            var trial = DbContext().Query<TrialLookUp>("Select * from Trial where EZID = ?", trialId).FirstOrDefault();
            return trial;
        }

        public async Task<List<TrialJson>> GetTrialGPSCoordinatesAsync(List<TrialLookUp> listofCheckedTrials)
        {
            var ezid = string.Join(",", listofCheckedTrials.Select(p => p.EZID.ToString()));
            var trials = await DbContextAsync().QueryAsync<TrialJson>("Select EZID as 'TrialID', Latitude, Longitude from Trial where EZID IN (" + ezid + ")");
            return trials;
        }

        public async Task SaveTrialAsync(TrialLookUp trial)
        {
            await DbContextAsync().InsertOrReplaceAsync(new Trial()
            {
                EZID = trial.EZID,
                CropCode = trial.CropCode,
                TrialName = trial.TrialName,
                TrialTypeID = trial.TrialTypeID,
                CountryCode = trial.CountryCode?.ToUpper(),
                TrialRegionID = trial.TrialRegionID,
                CropSegmentCode = trial.CropSegmentCode?.ToUpper(),
                DefaultTraitSetID = trial.DefaultTraitSetID,
                StatusCode = trial.StatusCode,
                Latitude = trial.Latitude,
                Longitude = trial.Longitude
            });
        }

        public List<TrialEntry> GetTrialEntries(List<TrialLookUp> listofCheckedTrials)
        {
            var lstTrialEntryApps = new List<TrialEntry>();

            foreach (var trialEntry in listofCheckedTrials.Select(trial => DbContext().Query<TrialEntry>(
                    "select TE.VarietyName as 'name' ,TE.FieldNumber as 'fieldnumber', TR.CropCode as 'cropcode', TE.EZID as 'trialEntryGuid', TR.EZID as 'trialID' from Trial as TR inner join Relationship as RE on TR.EZID = RE.EZID1 inner join TrialEntryApp as TE on RE.EZID2 = TE.EZID where  TE.NewRecord = 1 and TR.EZID = ? ", trial.EZID).ToList()).Where(trialEntry => trialEntry != null))
            {
                lstTrialEntryApps.AddRange(trialEntry);
            }

            return lstTrialEntryApps;
        }
        public List<int> GetHiddenVarieties(List<TrialLookUp> listofCheckedTrials) 
        {
            var edids = new List<int>();
            foreach (var trialEntry in listofCheckedTrials.Select(trial => DbContext().Query<TrialEntryApp>(
                    "select * from TrialEntryApp join Relationship on TrialEntryApp.EZID = Relationship.EZID2 where Relationship.EZID1 = ? and IsHidden = 1", trial.EZID).ToList()).Where(trialEntry => trialEntry != null))
            {
                edids.AddRange(trialEntry.Select(x=> Convert.ToInt32(x.EZID)));
            }

            return edids;
        }

        public async Task UpdateCreateTrialEntryResponseAsync(List<CreateTrialEntryResponseDto> createTrialEntryResponseDto)
        {
            foreach (var trialentry in createTrialEntryResponseDto)
            {
                var data = await DbContextAsync().QueryAsync<Relationship>("select EZID1 from Relationship WHERE EZID2 = ? ", trialentry.TrialEntryGuid);
                var trialEzid = data.FirstOrDefault();
                await DbContextAsync().ExecuteScalarAsync<TrialLookUp>("Update Trial set SelectedRecordID = ? where SelectedRecordID = ? ",
                    trialentry.TrialEntryEZID, trialentry.TrialEntryGuid);

                await DbContextAsync().ExecuteScalarAsync<TrialEntryApp>("Update TrialEntryApp set EZID = ?, NewRecord = 0 where EZID = ? ",
                    trialentry.TrialEntryEZID, trialentry.TrialEntryGuid);

                await DbContextAsync().ExecuteScalarAsync<Relationship>("Update Relationship set EZID2 = ? where EZID2 = ? ",
                    trialentry.TrialEntryEZID, trialentry.TrialEntryGuid);

                await DbContextAsync().ExecuteScalarAsync<ObservationAppLookup>("Update ObservationApp set EZID = ? where EZID = ? ",
                    trialentry.TrialEntryEZID, trialentry.TrialEntryGuid);

                UpdatePictureFolder(trialentry.TrialEntryEZID, trialentry.TrialEntryGuid, trialEzid.EZID1);
            }
        }

        public string GetTrialEntryEZIDFromSelectedTrial(List<TrialLookUp> listofCheckedTrials)
        {
            var ezidString = listofCheckedTrials.Select(trial =>
                   DbContext().Query<EzidsList>(
                       "SELECT IFNULL((group_concat(R.EZID2, '|')   || '|'), '') || T.EZID AS 'ezidLists' FROM Trial T LEFT JOIN RELATIONSHIP R ON T.EZID = R.EZID1 WHERE T.EZID = ?",
                       trial.EZID).SingleOrDefault()
                    ).Aggregate("", (current, val) => current + val.ezidLists + "|").Trim('|');
            
            return ezidString;
        }

        public List<Observation1> GetObservationDataToUploadAsync(List<TrialLookUp> listofCheckedTrials)
        {
            var ezidString = GetTrialEntryEZIDFromSelectedTrial(listofCheckedTrials);

            var observationData =
                DbContext().Query<Observation1>(
                    "SELECT e.EZID AS 'trialEntryEZID', e.traitid AS 'traitID', lower(e.useridcreated) AS 'userIDCreated', e.dateupdated AS 'dateUpdated', e.datecreated AS 'dateUpdated'," +
                    "CASE " +
                        "WHEN(e.ObsValueChar IS NOT NULL) THEN e.ObsValueChar " +
                        "WHEN(e.ObsValueInt IS NOT NULL) THEN e.ObsValueInt " +
                        "WHEN(e.ObsValueDecImp IS NOT NULL OR e.ObsValueDecMet IS NOT NULL)  THEN ( case when(Select Uom from SettingParameters) = 'Metric' then e.ObsValueDecMet else e.ObsValueDecImp end ) " +
                        "WHEN(e.ObsValueDate IS NOT NULL)  THEN e.ObsValueDate ELSE '' " +
                    "END AS 'observationValue', " +
                    "LOWER(e.UserIDUpdated) AS 'userIDUpdated', e.datecreated AS 'observationDate', e.datecreated AS 'dateCreated', e.UoMCode as 'uoMCode' " +
                    "FROM ObservationApp e WHERE INSTR('|" + ezidString + "|', '|' || e.ezid || '|') > 0 AND e.modified = 1 GROUP BY e.ezid,e.traitid, observationValue");

            return observationData;
        }

        public async Task UpdateSaveObservationDataResponseAsync(List<Observation1> observationData, List<TrialLookUp> listofCheckedTrials, string user)
        {
            foreach (var _data in observationData)
            {
                await DbContextAsync().ExecuteScalarAsync<ObservationApp>(
                       @"DELETE FROM ObservationApp
                                            WHERE EZID = ? AND TraitID = ? AND  date(DateCreated) = ? AND modified = 0 AND userIDCreated = ? AND 
                                              (CASE
                                                    WHEN(ObsValueChar IS NOT NULL) THEN CAST(ObsValueChar AS TEXT)
                                                    WHEN(ObsValueInt IS NOT NULL)  THEN CAST(ObsValueInt AS TEXT)
                                                    WHEN(ObsValueDecImp IS NOT NULL OR ObsValueDecMet IS NOT NULL)  THEN ( case when(Select Uom from SettingParameters) = 'Imperial' then ObsValueDecImp else ObsValueDecMet end )
                                                    ELSE CAST(ObsValueDate AS TEXT)
                                              END) != ? ",
                       _data.trialEntryEZID, _data.traitID, _data.dateCreated, @"intra\" + user, _data.observationValue);

                await DbContextAsync().ExecuteScalarAsync<ObservationApp>(
                    "update ObservationApp set modified = 0, userIDUpdated = ? WHERE EZID = ? and TraitID = ? and ObservationApp.modified = 1;",
                    @"intra\" + user, _data.trialEntryEZID, _data.traitID);
            }

            foreach (var trial in listofCheckedTrials)
            {
                await DbContextAsync().ExecuteScalarAsync<TrialLookUp>("update Trial set StatusCode = 20 where EZID = ?", trial.EZID);

                var lstTrl = await DbContextAsync().QueryAsync<TrialEntryApp>("select EZID from TrialEntryApp T join Relationship R on T.EZID = R.EZID2 where R.EZID1 = ? and T.Modified = 1", trial.EZID);

                foreach (var _var in lstTrl.ToList())
                {
                    await DbContextAsync().ExecuteScalarAsync<TrialLookUp>("Update TrialEntryApp set Modified = 0 where EZID = ? ", _var.EZID);
                }
                LogMessage.Log(string.Concat(trial.EZID.ToString(), " : ", trial.TrialName));
            }
        }

        public async Task<bool> RemoveTrialFromDeviceAsync(List<TrialLookUp> listofCheckedTrials, bool keeptrial)
        {
            await Task.Delay(1);
            var ezidStringFinish = GetTrialEntryEZIDFromSelectedTrial(listofCheckedTrials);
            foreach (var trial in listofCheckedTrials)
            {
                if (!keeptrial)
                    DbContext().ExecuteScalar<TrialLookUp>("delete from Trial where  EZID = ?", trial.EZID);

                DbContext().ExecuteScalar<Relationship>(
                        "delete from Relationship where ezid1 = ?", trial.EZID);
                if (!keeptrial)
                    DbContext().ExecuteScalar<DefaultTraitsPerTrial>(
                        "delete from DefaultTraitsPerTrial where ezid = ?", trial.EZID);

                LogMessage.Log(string.Concat(trial.EZID.ToString(), " : ", trial.TrialName));
            }
            DbContext().ExecuteScalar<ObservationAppLookup>(
                        "delete from ObservationApp WHERE INSTR('|" +
                        ezidStringFinish +
                        "|', '|' || ObservationApp.ezid || '|') > 0;");

            DbContext().ExecuteScalar<TrialEntryApp>(
                       "delete from TrialEntryApp WHERE INSTR('|" +
                       ezidStringFinish +
                       "|', '|' || TrialEntryApp.ezid || '|') > 0 ;");

            return true;
        }

        private void UpdatePictureFolder(string trialEntryEZID, string trialEntryGuid, int trialezid)
        {
            var oldpath = "";
            if (Device.RuntimePlatform == Device.UWP)
            {
                oldpath = Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.CommonApplicationData), "TrialAppPictures", trialezid.ToString(), trialEntryGuid);
            }
            else
            {
                oldpath = Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.Personal), "TrialAppPictures", trialezid.ToString(), trialEntryGuid);

            }
            //var oldpath = Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.Personal), "TrialAppPictures", trialezid.ToString(), trialEntryGuid);
            if (Directory.Exists(oldpath))
            {
                if (Device.RuntimePlatform == Device.UWP)
                {
                    Directory.Move(oldpath, Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.CommonApplicationData), "TrialAppPictures", trialezid.ToString(), trialEntryEZID));

                }
                else
                {
                    Directory.Move(oldpath, Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.Personal), "TrialAppPictures", trialezid.ToString(), trialEntryEZID));
                }
            }
            //Directory.Move(oldpath, Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.Personal), "TrialAppPictures", trialezid.ToString(), trialEntryEZID));

        }

        public async Task UpdateGPSCoordinate(TrialLookUp trial)
        {
            await DbContextAsync().ExecuteAsync("UPDATE Trial set Latitude = ?, Longitude = ?, StatusCode = 30 WHERE EZID = ?", trial.Latitude, trial.Longitude, trial.EZID);
        }
    }

    internal class EzidsList
    {
        public string ezidLists { get; set; }
    }
}
