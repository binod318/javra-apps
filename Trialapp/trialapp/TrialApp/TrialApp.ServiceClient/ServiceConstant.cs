using System;
using System.Collections.Generic;
using System.Text;

namespace TrialApp.ServiceClient
{
    public class ServiceConstant
    {
        public static Dictionary<string, string> NamespaceDict = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            {"GetTrialTokenBack", "http://schemas.cordys.com/TrialPrepWsApp"},
            {"getMetaInfoForMasterDataTables","http://contract.enzazaden.com/common/masterdatamanagement/v1" },
             {"getMasterData_V3","http://contract.enzazaden.com/common/masterdatamanagement/v1" },
             {"GetMetaInfoForMasterDataTables_v1","http://contract.enzazaden.com/common/masterdatamanagement/v2" },
             {"GetMasterData_V4","http://contract.enzazaden.com/common/masterdatamanagement/v2" },
             {"getTrialsWrapper","http://schemas.enzazaden.com/trailPrep/trials/1.0" },
             {"getTrialsForExternalUserWrapper","http://schemas.enzazaden.com/trailPrep/trials/1.0" },
             {"GetTrialEntriesData","http://schemas.enzazaden.com/trailPrep/trials/1.0" },
             {"CreateTrialEntry","http://schemas.enzazaden.com/trailPrep/trials/1.0" },
             {"SaveObservationData","http://schemas.enzazaden.com/trailPrep/trials/1.0" },
             {"UpdateTrialsWrapper","http://schemas.enzazaden.com/trailPrep/trials/1.0" },
             {"hideTrialEntriesWrapper","http://schemas.enzazaden.com/trailPrep/trials/1.0" }

        };

        public static Dictionary<string, string> ServiceAction = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            {
                "GetTrialTokenBack", @"{http://schemas.cordys.com/TrialPrepWsApp}TrialPrepWsAppWebServiceInterface"
            },
            {"getMetaInfoForMasterDataTables",@"{http://contract.enzazaden.com/common/masterdatamanagement/v1}MasterDataInterface" },
            {"getMasterData_V3",@"{http://contract.enzazaden.com/common/masterdatamanagement/v1}MasterDataInterface" },
            {"GetMetaInfoForMasterDataTables_v1",@"{http://contract.enzazaden.com/common/masterdatamanagement/v2}MasterDataInterface" },
            {"GetMasterData_V4",@"{http://contract.enzazaden.com/common/masterdatamanagement/v2}MasterDataInterface" },

            {"getTrialsWrapper",@"{http://schemas.enzazaden.com/trailPrep/trials/1.0}trialPrepTrialsServiceWrappersInterface" },
            {"getTrialsForExternalUserWrapper",@"{http://schemas.enzazaden.com/trailPrep/trials/1.0}trialPrepTrialsServiceWrappersInterface" },
            {"GetTrialEntriesData",@"{http://schemas.enzazaden.com/trailPrep/trials/1.0}trialPrepTrialsServiceWrappersInterface" },
            {"CreateTrialEntry",@"{http://schemas.enzazaden.com/trailPrep/trials/1.0}trialPrepTrialsServiceWrappersInterface" },
            {"SaveObservationData",@"{http://schemas.enzazaden.com/trailPrep/trials/1.0}trialPrepTrialsServiceWrappersInterface" },
            {"UpdateTrialsWrapper",@"{http://schemas.enzazaden.com/trailPrep/trials/1.0}trialPrepTrialsServiceWrappersInterface" },
            {"hideTrialEntriesWrapper",@"{http://schemas.enzazaden.com/trailPrep/trials/1.0}trialPrepTrialsServiceWrappersInterface" },
        };
    }
}
