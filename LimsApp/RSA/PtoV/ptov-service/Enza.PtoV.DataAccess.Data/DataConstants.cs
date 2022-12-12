namespace Enza.PtoV.DataAccess.Data
{
    public class DataConstants
    {
        public const string PR_GET_TRAIT_SCREENING = "PR_GetTraitScreening";
        public const string PR_GET_TRAIT_SCREENING_RESULT = "PR_GetTraitScreeningResult";
        public const string PR_GET_TRAITS = "PR_GetTraits";
        public const string PR_GET_SCREENING = "PR_GetScreening";
        public const string PR_SAVE_TRAIT_SCREENING = "PR_SaveTraitScreening";
        public const string PR_SAVE_TRAIT_SCREENING_RESULT = "PR_SaveTraitScreeningResult";
        public const string PR_GET_TRAIT_LOV = "PR_GetTraitLOV";
        public const string PR_GET_SCREENING_LOV = "PR_GetScreeningLOV";
        public const string PR_GET_TRAITS_WITH_SCREENING = "PR_GetTraitsWithScreening";
        public const string PR_GET_GERMPLASM = "PR_GetGermplasm"; 
        public const string PR_IMPORTDATA = "PR_ImportData";
        public const string PR_GET_CROPS = "PR_GetCrops";
        public const string PR_GET_NEWCROPS = "PR_GetNewCrops";
        public const string PR_GET_PRODUCT_SEGMENTS = "PR_GetProductSegments";
        public const string PR_UPDATE_PRODUCT_SEGMENTS = "PR_UpdateProductSegments";
        public const string PR_GET_CONVERTED_GERMPLASM = "PR_GetConvertedGermplasm";
        public const string PR_GET_VARIETY_DETAILS = "PR_GetVarietyDetails";
        public const string PR_UPDATE_VARMAS_RESPONSE = "PR_UpdateVarmasResponse";
        public const string PR_GET_GID_T0_IMPORT = "PR_GetGIDToImport";
        public const string PR_GET_PARENT = "PR_GetParent";
        public const string PR_GET_COLUMNS = "PR_GetColumns";
        public const string PR_DELETE_IMPORTED_GERMPLASMS = "PR_DeleteImportedGermplasms";
        public const string PR_GET_TRANSFERTYPE_PER_CROP = "PR_GetTransferTypePerCrop";
        public const string PR_GET_PHENOME_OBJECT_DETAIL = "PR_GetPhenomeObjectDetail";
        public const string PR_SYNCHRONIZE_PHENOME = "PR_SynchronizePhenome";
        public const string PR_GET_VARMAS_DATA_TO_SYNC = "PR_GetVarmasDataToSync";
        public const string PR_UPDATE_MODIFIED_VALUE = "PR_UpdateModifiedValue";
        public const string PR_GET_REPLACELOT_LOOKUP = "PR_GetReplaceLOTLookup";
        public const string PR_REPLACE_LOT = "PR_ReplaceLOT";
        public const string PR_REPLACE_LOTV2 = "PR_ReplaceLOTV2";
        public const string PR_UNDO_REPLACE_LOT = "PR_UndoReplaceLOT";
        public const string PR_GET_VARIETYDETAILS_FOR_REPLACELOT = "PR_GetVarietyDetails_ForReplaceLOT";
        public const string PR_RACIPROCATE = "PR_Raciprocate";
        public const string PR_REMOVE_UNMAPPED_COLUMNS = "PR_Remove_UnMappedColumns";
        public const string PR_GETCOUNTRIES = "PR_GetCountries";
        public const string PR_GET_PHENOME_COLUMNS = "PR_GetPhenomeColumns";
        public const string PR_GET_LOT_BY_PHENOME_LOT_ID = "PR_GetLotByPhenomeLotID";
        public const string PR_GET_VARIETY_DETAIL_WITH_STEM = "PR_GetVarietyDetailWithStem";
        public const string PR_UPDATE_GID_LINK = "PR_UpdateGIDLink";
        public const string PR_GET_PARENTS_VARITYNR = "PR_GetParentsVarityNr";


        //VtoPSync
        public const string PR_VTOPSYNC_GET_CONFIGS = "PR_VtoPSync_GetConfigs";
        public const string PR_VTOPSYNC_UPDATE_PTOV_RELATIONSHIP = "PR_VtoPSync_UpdatePtoVRelationship";
        public const string PR_VTOPSYNC_UPDATE_LAST_LOTNR = "PR_VtoPSync_UpdateLastLotNr";
        public const string PR_VTOPSYNC_GET_GERMPLASM_NAME_FROM_EZID = "PR_VtoPSync_GetGermplasmNameFromEZID";
        public const string PR_VTOPSYNC_GET_VARIETY_SYNC_LOGS = "PR_VtoPSync_GetVarietySyncLogs";
        public const string PR_VTOPSYNC_UPDATE_VARMAS_ENUMBERS = "PR_VtoPSync_UpdateVarmasENumbers";
        public const string PR_VTOPSYNC_GET_VARIETY_LOGS = "PR_VtoPSync_GetVarietyLogs";


        public const string PR_GET_EMAIL_CONFIGS = "PR_GetEmailConfigs";
        public const string PR_SAVE_EMAIL_CONFIG = "PR_SaveEmailConfig";
        public const string PR_DELETE_EMAIL_CONFIG = "PR_DeleteEmailConfig";
        public const string PR_GET_COLUMNS_INFO = "PR_GetColumnsInfo";
        public const string PR_IMPORT_GERMPLASM_FROM_PEDIGREE = "PR_Import_Germplasm_From_Pedigree";

        public const string PR_GET_VARIETIES = "PR_GetVarieties";
        public const string PR_GET_PHENOME_COLUMN_DETAILS = "PR_GetPhenomeColumnDetails";
        public const string PR_VTOPSYNC_GET_VARIETY_LOGS_FOR_VARIETIES = "PR_VtoPSync_GetGIDofVarieties";

        public const string PR_GET_UNSENT_EMAIL_LOGS = "PR_GetUnsentEmailLogs";
        public const string PR_UPDATE_SENT_EMAIL_LOG = "PR_UpdateSentEmailLog";
    }
}