using Azure.Storage.Blobs;
using SQLite;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using TrialApp.Common;
using TrialApp.Common.Extensions;
using TrialApp.DataAccess;
using TrialApp.Entities;
using TrialApp.Entities.Bdtos.ResultSets;
using TrialApp.Entities.ServiceRequest;
using TrialApp.Entities.ServiceResponse;
using TrialApp.Entities.Transaction;
using Xamarin.Forms;


namespace TrialApp.Services
{

    public class TrialService
    {
        private readonly TrialRepository _repoAsync;
        private readonly TrialRepository _repoSync;
        private readonly TrialTypeRepository _trialTypeRepoAsync;
        private readonly RelationshipRepository _relationshipRepoAsync;
        private readonly TrialEntryAppRepository _trialEntryAppRepository;
        private readonly ObservationAppRepository _observationAppRepository;

        public TrialService()
        {
            _repoAsync = new TrialRepository(new SQLiteAsyncConnection(DbPath.GetTransactionDbPath()));
            _repoSync = new TrialRepository();
            _trialTypeRepoAsync = new TrialTypeRepository(new SQLiteAsyncConnection(DbPath.GetMasterDbPath()));
            _relationshipRepoAsync = new RelationshipRepository(new SQLiteAsyncConnection(DbPath.GetTransactionDbPath()));
            _trialEntryAppRepository = new TrialEntryAppRepository(new SQLiteAsyncConnection(DbPath.GetTransactionDbPath()));
            _observationAppRepository = new ObservationAppRepository(new SQLiteAsyncConnection(DbPath.GetTransactionDbPath()));
        }

        public List<TrialLookUp> GetAllTrials()
        {
            var orgiList = _repoSync.Get();
            return orgiList.ToList();
        }

        public async Task<List<TrialLookUp>> GetAllTrialsList()
        {
            var orgiList = await _repoAsync.GetAsync();
            var trialTypeList = await _trialTypeRepoAsync.GetAllTrialTypesAsync();
            var trialLookUps = orgiList as IList<TrialLookUp> ?? orgiList.ToList();
            foreach (var orgi in trialLookUps)
            {
                orgi.TrialTypeName = trialTypeList.FirstOrDefault(p => p.TrialTypeID.Equals(orgi.TrialTypeID))?.TrialTypeName;
            }
            return trialLookUps.ToList();
        }

        public TrialLookUp GetTrialInfo(int trialId)
        {
            var orgiList = _repoSync.Get(trialId);
            return orgiList;
        }

        public async Task<List<TrialDto1>> GetTrialsWrapperService(string localToken)
        {
            var soapClient = WebserviceTasks.GetSoapClient();

            var reqObj = new getTrialsWrapper
            {
                AppName = "TrialApp",
                DeviceID = DeviceInfo.GetUniqueDeviceID(),
                SoftwareVersion = WebserviceTasks.appVersion,
                Token = localToken,
                UserName = WebserviceTasks.UsernameWS
            };
            var resp = await
                soapClient.GetResponse<getTrialsWrapper, getTrialsWrapperResponse>(
                    reqObj, string.IsNullOrEmpty(WebserviceTasks.AdToken) ? "" : WebserviceTasks.AdToken);
            var localTrialsEZIDs = GetAllTrials().Select(t => t.EZID);
            var result = resp.TrialDto.Where(t => !localTrialsEZIDs.Contains(Convert.ToInt32(t.EZID))).ToList();
            return result;
        }

        public async Task<List<TrialDto1>> GetExternalUserTrialsWrapperService(string localToken, string trialEzids)
        {
            var soapClient = WebserviceTasks.GetSoapClient();

            var reqObj = new getTrialsForExternalUserWrapper
            {
                AppName = "TrialApp",
                DeviceID = DeviceInfo.GetUniqueDeviceID(),
                SoftwareVersion = WebserviceTasks.appVersion,
                Token = localToken,
                UserName = WebserviceTasks.UsernameWS,
                trialIDs = trialEzids
            };
            var resp = await
                soapClient.GetResponse<getTrialsForExternalUserWrapper, getTrialsForExternalUserWrapperResponse>(
                    reqObj, string.IsNullOrEmpty(WebserviceTasks.AdToken) ? "" : WebserviceTasks.AdToken);
            var localTrialsEZIDs = GetAllTrials().Select(t => t.EZID);
            var result = resp.TrialDto.Where(t => !localTrialsEZIDs.Contains(Convert.ToInt32(t.EZID))).ToList();
            return result;
        }
        public async Task UpdateGPSCoordinate(TrialLookUp trial)
        {
            await _repoAsync.UpdateGPSCoordinate(trial);
        }

        public async Task<List<int>> DownloadTrialEntriesData(IEnumerable<TrialLookUp> trialList, bool trialexists, string localToken)
        {
            var ezidSuccess = new List<int>();
            var soapClient = WebserviceTasks.GetSoapClient();

            foreach (var item in trialList)
            {
                var reqObj = new GetTrialEntriesData
                {
                    AppName = "TrialApp",
                    DeviceID = DeviceInfo.GetUniqueDeviceID(),
                    SoftwareVersion = WebserviceTasks.appVersion,
                    Token = localToken,
                    UserName = WebserviceTasks.UsernameWS,
                    EZID = item.EZID.ToString()
                };
                var resp = new GetTrialEntriesDataResponse();
                try
                {
                    resp = await soapClient.GetResponse<GetTrialEntriesData, GetTrialEntriesDataResponse>(reqObj, string.IsNullOrEmpty(WebserviceTasks.AdToken) ? "" : WebserviceTasks.AdToken);
                }
                catch (Exception ex)
                {
                    await Application.Current.MainPage.DisplayAlert("Error", ex.Message, "OK");
                }

                if (resp.Result != "Success")
                    break;

                var result = await SaveTrialEntriesData(resp, item, trialexists);
                if (!result)
                    break;

                ezidSuccess.Add(item.EZID);
            }

            return ezidSuccess;
        }

        public async Task<bool> SaveTrialEntriesData(GetTrialEntriesDataResponse response, TrialLookUp trial, bool trialexists)
        {
            try
            {
                var returnValue = false;

                var tlList = new List<TrialEntryApp>();
                var relationList = new List<Relationship>();
                var observationList = new List<ObservationAppLookup>();

                if (response.Result != "Success") return returnValue;
                if (response.Observations != null)
                {

                    observationList.AddRange(response.Observations.ObservationDto.Select(obsData => new ObservationAppLookup
                    {
                        TraitID = Convert.ToInt32(obsData.TraitID),
                        EZID = obsData.EZID.ToString(),
                        UserIDCreated = obsData.UserIDCreated.ToLower(),
                        UserIDUpdated = obsData.UserIDUpdated.ToLower(),
                        //DateTime.ParseExact("07/21/2011", "MM/dd/yyyy", CultureInfo.InvariantCulture);
                        DateCreated = string.IsNullOrWhiteSpace(obsData.ObservationDate) ? "" : Convert.ToDateTime(obsData.ObservationDate, new CultureInfo("en-US")).ToString(),
                        DateUpdated = string.IsNullOrWhiteSpace(obsData.ObservationDate) ? "" : Convert.ToDateTime(obsData.ObservationDate, new CultureInfo("en-US")).ToString(),
                        ObsValueChar = obsData.ValueChar,
                        ObsValueDate = string.IsNullOrWhiteSpace(obsData.ValueDate) ? null : Convert.ToDateTime(obsData.ValueDate, new CultureInfo("en-US")).ToString(),
                        // ObsValueDec = string.IsNullOrWhiteSpace(obsData.ValueDec) ? (decimal?)null : Convert.ToDecimal(obsData.ValueDec, new CultureInfo("en-US")),

                        ObsValueDecMet = string.IsNullOrWhiteSpace(obsData.ObsValueDecMetric) ? (decimal?)null : Convert.ToDecimal(obsData.ObsValueDecMetric, new CultureInfo("en-US")),
                        ObsValueDecImp = string.IsNullOrWhiteSpace(obsData.ObsValueDecImperial) ? (decimal?)null : Convert.ToDecimal(obsData.ObsValueDecImperial, new CultureInfo("en-US")),

                        ObsValueInt = string.IsNullOrWhiteSpace(obsData.ValueInt) ? (int?)null : Convert.ToInt32(obsData.ValueInt),
                        ObservationId = string.IsNullOrWhiteSpace(obsData.ObservationID) ? (int?)null : Convert.ToInt32(obsData.ObservationID)
                    }));
                }

                if (response.TrialEntries != null)
                {
                    foreach (var _trialdata in response.TrialEntries.TrialEntryDto)
                    {
                        if (!_trialdata.IsHidden)
                        {
                            var trialEntriesApp = new TrialEntryApp
                            {
                                EZID = _trialdata.EZID ?? "",
                                CropCode = _trialdata.CropCode ?? "",
                                FieldNumber = _trialdata.FieldNumber ?? "",
                                EZIDVariety = _trialdata.Variety.EZID ?? "",
                                VarietyNr = _trialdata.Variety.Number == "" ? (int?)null : Convert.ToInt32(_trialdata.Variety.Number),//_trialdata.Variety.Number == null ? (int?) null : Convert.ToInt32(_trialdata.Variety.Number),
                                CropCodeVariety = _trialdata.Variety.CropCode ?? "",
                                VarietyName = _trialdata.Variety.Name ?? _trialdata.Name,
                                Enumber = _trialdata.Variety.Enumber ?? "",
                                MasterNr = _trialdata.Variety.MasterNumber ?? "",
                                CropSegmentCode = _trialdata.Variety.CropSegmentCode ?? "",
                                ProductSegmentCode = _trialdata.Variety.ProductSegmentCode ?? "",
                                ProductStatus = _trialdata.Variety.ProductStatus ?? "",
                                ResistanceHR = _trialdata.Variety.ResistanceHR ?? "",
                                ResistanceIR = _trialdata.Variety.ResistanceIR ?? "",
                                ResistanceT = _trialdata.Variety.ResistanceT ?? ""

                            };
                            tlList.Add(trialEntriesApp);

                            if (_trialdata.Observations != null)
                            {

                                observationList.AddRange(_trialdata.Observations.ObservationDto.Select(obsData => new ObservationAppLookup
                                {
                                    TraitID = Convert.ToInt32(obsData.TraitID),
                                    EZID = obsData.EZID.ToString(),
                                    UserIDCreated = obsData.UserIDCreated.ToLower(),
                                    UserIDUpdated = obsData.UserIDUpdated.ToLower(),
                                    DateCreated = obsData.ObservationDate == "" ? "" : Convert.ToDateTime(obsData.ObservationDate, new CultureInfo("en-US")).ToString(),
                                    DateUpdated = obsData.ObservationDate == "" ? "" : Convert.ToDateTime(obsData.ObservationDate, new CultureInfo("en-US")).ToString(),
                                    ObsValueChar = obsData.ValueChar,
                                    ObsValueDate = string.IsNullOrWhiteSpace(obsData.ValueDate) ? "" : Convert.ToDateTime(obsData.ValueDate, new CultureInfo("en-US")).ToString(), //obsData.ValueDate == "" ? (DateTime?)null : Convert.ToDateTime(Convert.ToDateTime(obsData.ValueDate).ToString("yyyy-MM-dd")),
                                                                                                                                                                                   //ObsValueDec = string.IsNullOrWhiteSpace(obsData.ValueDec) ? (decimal?)null : Convert.ToDecimal(obsData.ValueDec, new CultureInfo("en-US")),// obsData.ValueDec == "" ? (decimal?)null : Convert.ToDecimal(obsData.ValueDec),

                                    ObsValueDecMet = string.IsNullOrWhiteSpace(obsData.ObsValueDecMetric) ? (decimal?)null : Convert.ToDecimal(obsData.ObsValueDecMetric, new CultureInfo("en-US")),
                                    ObsValueDecImp = string.IsNullOrWhiteSpace(obsData.ObsValueDecImperial) ? (decimal?)null : Convert.ToDecimal(obsData.ObsValueDecImperial, new CultureInfo("en-US")),

                                    ObsValueInt = string.IsNullOrWhiteSpace(obsData.ValueInt) ? (int?)null : Convert.ToInt32(obsData.ValueInt),
                                    ObservationId = string.IsNullOrWhiteSpace(obsData.ObservationID) ? (int?)null : Convert.ToInt32(obsData.ObservationID)
                                }));
                            }

                            var RelTb = new Relationship
                            {
                                EZID1 = Convert.ToInt32(_trialdata.TrialID),
                                EntityTypeCode1 = "TRI",
                                EZID2 = _trialdata.EZID,
                                EntityTypeCode2 = "TRL"
                            };
                            relationList.Add(RelTb);
                        }
                    }
                }

                //using (var db = new SQLiteConnection(DbPath.GetTransactionDbPath()))
                //{


                await _trialEntryAppRepository.SaveTrialEntryAppAsync(tlList);

                await _relationshipRepoAsync.SaveRelationShipAsync(relationList);

                //Create ObservationApp
                foreach (var _value in observationList)
                {
                    await _observationAppRepository.InsertObservationValue(_value);

                }

                // Do not insert trial when submitting and downloading from main screen
                //Create Trial
                if (!trialexists)
                    await _repoAsync.SaveTrialAsync(trial);

                //db.Commit();
                return true;
            }
            catch (Exception)
            {
                return false;
            }

            return false;
        }

        public void UpdateTrialStatus(int _trialEzid)
        {
            _repoSync.UpdateTrialStatus(_trialEzid);
        }

        public async Task<bool> Uploaddata(List<TrialLookUp> listofCheckedTrials, string adToken)
        {
            //var result = "";
            //var lstTrialEntryApps = new List<TrialEntry>();

            //using (var db = new SQLiteConnection(DbPath.GetTransactionDbPath()))
            //{
            //    db.BeginTransaction();
            //var decQuery = UnitOfMeasure.SystemUoM == "Imperial" ? " e.ObsValueDecImp " : " e.ObsValueDecMet ";
            var client = WebserviceTasks.GetSoapClient();

            #region Upload TrialEntries if there is any

            //get trialentries if any
            var trialEntries = _repoSync.GetTrialEntries(listofCheckedTrials);

            //foreach (var trialEntry in listofCheckedTrials.Select(trial => db.Query<TrialEntry>(
            //        "select TE.VarietyName as 'name' ,TE.FieldNumber as 'fieldnumber', TR.CropCode as 'cropcode', TE.EZID as 'trialEntryGuid', TR.EZID as 'trialID' from Trial as TR inner join Relationship as RE on TR.EZID = RE.EZID1 inner join TrialEntryApp as TE on RE.EZID2 = TE.EZID where  TE.NewRecord = 1 and TR.EZID = ? ", trial.EZID).ToList()).Where(trialEntry => trialEntry != null))
            //    {
            //        lstTrialEntryApps.AddRange(trialEntry);
            //    }


            if (trialEntries.Any())
            {
                var inputParam = new CreateTrialEntry
                {
                    UserName = WebserviceTasks.UsernameWS?.ToLower(),
                    DeviceID = DeviceInfo.GetUniqueDeviceID(),
                    SoftwareVersion = WebserviceTasks.appVersion,
                    AppName = "TrialAppLT",
                    TrialEntriesData = trialEntries.Serialize(),
                    Token = adToken
                };

                var responseCreateTrEntry = await client.GetResponse<CreateTrialEntry, CreateTrialEntryResponse>(inputParam, string.IsNullOrEmpty(WebserviceTasks.AdToken) ? "" : WebserviceTasks.AdToken);

                if (responseCreateTrEntry.TrialEntriesResultData.CreateTrialEntryResponseDto.Any())
                {
                    //update create trialentry response to db
                    await _repoAsync.UpdateCreateTrialEntryResponseAsync(responseCreateTrEntry.TrialEntriesResultData.CreateTrialEntryResponseDto);

                    //foreach (var trialentry in responseCreateTrEntry.TrialEntriesResultData.CreateTrialEntryResponseDto)
                    //{
                    //    var trialEzid = db.Query<Relationship>("select EZID1 from Relationship WHERE EZID2 = ? ", trialentry.TrialEntryGuid).FirstOrDefault();
                    //    db.ExecuteScalar<TrialLookUp>("Update Trial set SelectedRecordID = ? where SelectedRecordID = ? ",
                    //        trialentry.TrialEntryEZID, trialentry.TrialEntryGuid);

                    //    db.ExecuteScalar<TrialEntryApp>("Update TrialEntryApp set EZID = ?, NewRecord = 0 where EZID = ? ",
                    //        trialentry.TrialEntryEZID, trialentry.TrialEntryGuid);

                    //    db.ExecuteScalar<Relationship>("Update Relationship set EZID2 = ? where EZID2 = ? ",
                    //        trialentry.TrialEntryEZID, trialentry.TrialEntryGuid);

                    //    db.ExecuteScalar<ObservationAppLookup>("Update ObservationApp set EZID = ? where EZID = ? ",
                    //        trialentry.TrialEntryEZID, trialentry.TrialEntryGuid);

                    //    UpdatePictureFolder(trialentry.TrialEntryEZID, trialentry.TrialEntryGuid, trialEzid.EZID1);
                    //}
                }
                else
                {
                    //return false;
                    throw new Exception("Unale to create new trialentrie(s).");
                }

            }
            #endregion


            #region Hide Variety
            var VarityIds = _repoSync.GetHiddenVarieties(listofCheckedTrials);
            if (VarityIds.Any()) 
                {
                var inputParam = new HideTrialEntriesWrapper()
                {
                    UserName = WebserviceTasks.UsernameWS?.ToLower(),
                    DeviceID = DeviceInfo.GetUniqueDeviceID(),
                    SoftwareVersion = WebserviceTasks.appVersion,
                    AppName = "TrialApp",
                    ezIds = VarityIds.Serialize(),
                    Token = adToken

                };

                var responseHideEntry = await client.GetResponse<HideTrialEntriesWrapper, HideTrialEntriesWrapperResponse>(inputParam, string.IsNullOrEmpty(WebserviceTasks.AdToken) ? "" : WebserviceTasks.AdToken);

            }

            #endregion 


            #region Upload Observation data



            //fetch observation data
            //var observationData = await _repoAsync.GetObservationDataToUploadAsync(listofCheckedTrials);
            var observationData = _repoSync.GetObservationDataToUploadAsync(listofCheckedTrials);

            //var ezidString = listofCheckedTrials.Select(trial =>
            //    db.Query<EzidsList>(
            //        "SELECT IFNULL((group_concat(R.EZID2, '|')   || '|'), '') || T.EZID AS 'ezidLists' FROM Trial T LEFT JOIN RELATIONSHIP R ON T.EZID = R.EZID1 WHERE T.EZID = ?",
            //        trial.EZID).SingleOrDefault()
            //    ).Aggregate("", (current, val) => current + val.ezidLists + "|").Trim('|');

            //var observationData =
            //    db.Query<Observation1>(
            //        "SELECT e.EZID AS 'trialEntryEZID', e.traitid AS 'traitID', lower(e.useridcreated) AS 'userIDCreated', e.dateupdated AS 'dateUpdated', e.datecreated AS 'dateUpdated'," +
            //        "CASE " +
            //            "WHEN(e.ObsValueChar IS NOT NULL) THEN e.ObsValueChar " +
            //            "WHEN(e.ObsValueInt IS NOT NULL) THEN e.ObsValueInt " +
            //            "WHEN(e.ObsValueDecImp IS NOT NULL OR e.ObsValueDecMet IS NOT NULL)  THEN ( case when(Select Uom from SettingParameters) = 'Metric' then e.ObsValueDecMet else e.ObsValueDecImp end ) " +
            //            "WHEN(e.ObsValueDate IS NOT NULL)  THEN e.ObsValueDate ELSE '' " +
            //        "END AS 'observationValue', " +
            //        "LOWER(e.UserIDUpdated) AS 'userIDUpdated', e.datecreated AS 'observationDate', e.datecreated AS 'dateCreated', e.UoMCode as 'uoMCode' " +
            //        "FROM ObservationApp e WHERE INSTR('|" + ezidString + "|', '|' || e.ezid || '|') > 0 AND e.modified = 1 GROUP BY e.ezid,e.traitid, observationValue");

            var save = new SaveObservationData
            { 
                AppName = "TrialApp",
                DeviceID = DeviceInfo.GetUniqueDeviceID(),
                Observationsjson = observationData.Serialize(),
                SoftwareVersion = WebserviceTasks.appVersion,
                Token = adToken,
                UserName = WebserviceTasks.UsernameWS
            };

            var responseSaveObs = await client.GetResponse<SaveObservationData, SaveObservationDataResponse>(save, string.IsNullOrEmpty(WebserviceTasks.AdToken) ? "" : WebserviceTasks.AdToken);
            var result = responseSaveObs.Result;
            if (result == "Success")
            {
                //update SaveObservationDataResponse
                await _repoAsync.UpdateSaveObservationDataResponseAsync(observationData, listofCheckedTrials, WebserviceTasks.UsernameWS?.ToLower());

                //foreach (var _data in observationData)
                //{
                //    db.ExecuteScalar<ObservationApp>(
                //           @"DELETE FROM ObservationApp
                //                        WHERE EZID = ? AND TraitID = ? AND  date(DateCreated) = ? AND modified = 0 AND userIDCreated = ? AND 
                //                          (CASE
                //                                WHEN(ObsValueChar IS NOT NULL) THEN CAST(ObsValueChar AS TEXT)
                //                                WHEN(ObsValueInt IS NOT NULL)  THEN CAST(ObsValueInt AS TEXT)
                //                                WHEN(ObsValueDecImp IS NOT NULL OR ObsValueDecMet IS NOT NULL)  THEN ( case when(Select Uom from SettingParameters) = 'Imperial' then ObsValueDecImp else ObsValueDecMet end )
                //                                ELSE CAST(ObsValueDate AS TEXT)
                //                          END) != ? ",
                //           _data.trialEntryEZID, _data.traitID, _data.dateCreated, @"intra\" + WebserviceTasks.UsernameWS.ToLower(), _data.observationValue);

                //    db.ExecuteScalar<ObservationApp>(
                //        "update ObservationApp set modified = 0, userIDUpdated = ? WHERE EZID = ? and TraitID = ? and ObservationApp.modified = 1;",
                //        @"intra\" + WebserviceTasks.UsernameWS.ToLower(), _data.trialEntryEZID, _data.traitID);
                //}

                //foreach (var trial in listofCheckedTrials)
                //{
                //    db.ExecuteScalar<TrialLookUp>("update Trial set StatusCode = 20 where EZID = ?", trial.EZID);

                //    var lstTrl = db.Query<TrialEntryApp>("select EZID from TrialEntryApp T join Relationship R on T.EZID = R.EZID2 where R.EZID1 = ? and T.Modified = 1", trial.EZID).ToList();

                //    foreach (var _var in lstTrl)
                //    {
                //        db.ExecuteScalar<TrialLookUp>("Update TrialEntryApp set Modified = 0 where EZID = ? ", _var.EZID);
                //    }
                //    // await DetailPage.createDBChangeLogFile(trial.EZID.ToString(), trial.TrialName, false, false);
                //     LogMessage.Log(string.Concat(trial.EZID.ToString(), " : ", trial.TrialName));
                //}
            }
            else
            {
                throw new Exception(result);
            }
            #endregion
            //  #region DELETE Trials from device
            ////RemoveTrialFromDevice();
            //  #endregion

            #region Upload GPS data

            var trialJson = await _repoAsync.GetTrialGPSCoordinatesAsync(listofCheckedTrials);

            var upload = new UpdateTrialsWrapper()
            {
                AppName = "TrialApp",
                DeviceID = DeviceInfo.GetUniqueDeviceID(),
                TrialData = trialJson.Serialize(),
                SoftwareVersion = WebserviceTasks.appVersion,
                Token = adToken,
                UserName = WebserviceTasks.UsernameWS
            };

            var responseUpdateTrials = await client.GetResponse<UpdateTrialsWrapper, UpdateTrialsWrapperResponse>(upload, string.IsNullOrEmpty(WebserviceTasks.AdToken) ? "" : WebserviceTasks.AdToken);
            _ = responseUpdateTrials.Result;

            #endregion

            return true;
        }
        
        public async Task UploadImagesAsync(List<TrialLookUp> listofCheckedTrials)
        {
            try
            {
                //Image upload to Azure
                foreach (var trial in listofCheckedTrials)
                {
                    //Download list files before uploading
                    var serverfiles = new List<string>();
                    var containerClient = await WebserviceTasks.GetBlobClient();
                    var resultSegment = containerClient.GetBlobs(prefix: $"{trial.EZID}/");
                    foreach (var blobPage in resultSegment)
                    {
                        serverfiles.Add(blobPage.Name);
                    }

                    //check local Directory for Trial EZID
                    var di = "";
                    //here check for platform 
                    if (Device.RuntimePlatform == Device.UWP)
                    {
                        di = Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.CommonApplicationData), "TrialAppPictures", trial.EZID.ToString());
                    }
                    else
                    {
                        di = Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.Personal), "TrialAppPictures", trial.EZID.ToString());
                    }
                        
                    if (Directory.Exists(di))
                    {
                        string[] files = Directory.GetFiles(di, "*.*", SearchOption.AllDirectories);
                        foreach (var file in files)
                        {
                            //do not upload if file is already uploaded
                            if (serverfiles.Any(o => o.Contains(Path.GetFileNameWithoutExtension(file))))
                                continue;

                            //var path = file.Split('/');
                            var path = file.Split(new string[] {"TrialAppPictures/" },StringSplitOptions.RemoveEmptyEntries);
                            if(file != null)
                            {                                 
                                using (FileStream outputFileStream = new FileStream(file, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
                                {
                                    try
                                    {
                                        var result = await containerClient.UploadBlobAsync(file.Substring(file.IndexOf(trial.EZID.ToString())), outputFileStream);
                                    }
                                    catch (Exception )
                                    {
                                        
                                    }
                                }
                            }
                            
                        }
                    }
                }
                //await containerClient.UploadBlobAsync(trialEzid + $"/{Guid.NewGuid()}.jpg", phototoUpload.GetStream());
            }
            catch (Exception ex)
            {
                await Application.Current.MainPage.DisplayAlert("Error", ex.Message, "OK");
            }
        }
        public async Task<bool> RemoveTrialFromDeviceAsync(List<TrialLookUp> listofCheckedTrials, bool keeptrial)
        {
            return await _repoSync.RemoveTrialFromDeviceAsync(listofCheckedTrials, keeptrial);
        }
        public async Task DeleteTrialPictures(List<TrialLookUp> listofCheckedTrials)
        {
            foreach (var ezid in listofCheckedTrials)
            {
                try
                {
                    var path = "";
                    if (Device.RuntimePlatform == Device.UWP)
                    {
                        path = Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.CommonApplicationData), "TrialAppPictures", ezid.EZID.ToString());
                    }
                    else
                    {
                        path = Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.Personal), "TrialAppPictures", ezid.EZID.ToString());
                    }
                    var di = new DirectoryInfo(path);

                    foreach (var file in di.GetFiles())
                    {
                        file.Delete();
                    }
                    foreach (var dir in di.GetDirectories())
                    {
                        dir.Delete(true);
                    }

                    await Task.Delay(1);
                }
                catch (Exception)
                {
                }
            }
        }
        public async Task<bool> UpdateTrialAndObservationData(List<TrialLookUp> listofCheckedTrials, string token)
        {
            try
            {
                // Remove selectedtrials first
                await RemoveTrialFromDeviceAsync(listofCheckedTrials, true);

                // Download selected trials again
                await DownloadTrialEntriesData(listofCheckedTrials, true, token);

                return true;
            }
            catch (Exception)
            {
                await Application.Current.MainPage.DisplayAlert("Error", "Error while downloading submitted trials.", "OK");
                return false;
            }
        }
    }
    //internal class EzidsList
    //{
    //    public string ezidLists { get; set; }
    //}

}
