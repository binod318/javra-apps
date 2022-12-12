using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;
using Enza.PtoV.DataAccess.Abstract;
using Enza.PtoV.DataAccess.Data.Interfaces;
using Enza.PtoV.DataAccess.Interfaces;
using Enza.PtoV.Entities;
using Enza.PtoV.Entities.Args;
using Enza.PtoV.Entities.Results;
using Newtonsoft.Json;

namespace Enza.PtoV.DataAccess.Data.Repositories
{
    public class VarietyRepository : Repository<object>, IVarietyRepository
    {
        private readonly IUserContext _userContext;
        private readonly IPedigreeRepository _pedigreeRepo;
        public VarietyRepository(IDatabase dbContext, IUserContext userContext,IPedigreeRepository pedigreeRepository) : base(dbContext)
        {
            _userContext = userContext;
            _pedigreeRepo = pedigreeRepository;
        }

        public async Task UpdateProductSegmentsAsync(UpdateProductSegmentsRequestArgs requestArgs)
        {
            var jsonData = JsonConvert.SerializeObject(requestArgs);
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_UPDATE_PRODUCT_SEGMENTS,
                CommandType.StoredProcedure, args => args.Add("@JsonData", jsonData));
        }

        //get varieties detail including parents if present
        public Task<IEnumerable<VarietyResult>> GetVarietyDetailsAsync(IEnumerable<int> varietyIDs)
        {
            return DbContext.ExecuteReaderAsync(DataConstants.PR_GET_VARIETY_DETAILS,
                CommandType.StoredProcedure,
                args => args.Add("@VarietyIDs", string.Join(",", varietyIDs)), reader => new VarietyResult
                {
                    VarietyID = reader.Get<int>(0),
                    CropCode = reader.Get<string>(1),
                    BrStationCode = reader.Get<string>(2),
                    GID = reader.Get<int>(3),
                    TransferType = reader.Get<string>(4),
                    ENumber = reader.Get<string>(5),
                    NewCropCode = reader.Get<string>(6),
                    ProdSegCode = reader.Get<string>(7),
                    SyncCode = reader.Get<string>(8),
                    StatusCode = reader.Get<int>(9),
                    Maintainer = reader.Get<int>(10),
                    FemaleParent = reader.Get<int>(11),
                    MaleParent = reader.Get<int>(12),
                    Parent = reader.Get<int>(13),
                    LotNr = reader.Get<int>(14),
                    ReplacingLot = reader.Get<bool>(15),
                    CountryOfOrigin = reader.Get<string>(16),
                    UsePoNr = reader.Get<bool>(17),
                    Linkedvariety = reader.Get<int>(18),
                    Stem = reader.Get<string>(19)
                });
        }

        public async Task<UpdateVarmasResult> UpdateVarmasResponseAsync(UpdateVarmasResponse model)
        {
            var items = await DbContext.ExecuteReaderAsync(DataConstants.PR_UPDATE_VARMAS_RESPONSE,
                CommandType.StoredProcedure, args =>
                {
                    args.Add("@VarietyID", model.VarietyID);
                    args.Add("@GID", model.GID);
                    args.Add("@VarietyNr", model.VarietyNr);
                    args.Add("@ENumber", model.ENumber);
                    args.Add("@VarietyStatus", model.VarietyStatus);
                    args.Add("@VarietyName", model.VarietyName);
                    args.Add("@LotNr", model.LotNr);
                    args.Add("@PhenomeLotID", model.PhenomeLotID);
                    args.Add("@User", _userContext.Name);
                }, reader => new UpdateVarmasResult
                {
                    StatusCode = reader.Get<int>(0),
                    StatusName = reader.Get<string>(1)
                });
            return items.FirstOrDefault();
        }

        public async Task<bool> ReplaceLOTAsync(int gID, int lotGID)
        {
            var data = await DbContext.ExecuteNonQueryAsync(DataConstants.PR_REPLACE_LOT,
                CommandType.StoredProcedure, args =>
                {                    
                    args.Add("@GID", gID);
                    args.Add("@LotGID", lotGID);
                });
            return true;
        }

        public async Task<bool> ReplaceLOTAsync(ReplaceLotRequestArgs args)
        {
            var data = await DbContext.ExecuteNonQueryAsync(DataConstants.PR_REPLACE_LOTV2,
                CommandType.StoredProcedure, args1 =>
                {                    
                    args1.Add("@GID", args.GID);
                    args1.Add("@LotGID", args.LotGID);
                    args1.Add("@ReplacedLotID", args.PhenomeLotID);
                });
            return true;
        }

        public async Task<DataTable> ReplaceLOTLookupAsync(int gID)
        {
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_REPLACELOT_LOOKUP,
                CommandType.StoredProcedure, args =>
                {
                    args.Add("@GID", gID);

                });
            return data.Tables[0];
        }

        public async Task<IEnumerable<VarietyResult>> GetVarietyDetailForReplacedLotAsync(string varietyIDS)
        {
            return await DbContext.ExecuteReaderAsync(DataConstants.PR_GET_VARIETYDETAILS_FOR_REPLACELOT,
                CommandType.StoredProcedure,
                args => args.Add("@VarietyIDs", varietyIDS), reader => new VarietyResult
                {
                    VarietyID = reader.Get<int>(0),
                    CropCode = reader.Get<string>(1),
                    BrStationCode = reader.Get<string>(2),
                    GID = reader.Get<int>(3),
                    TransferType = reader.Get<string>(4),
                    ENumber = reader.Get<string>(5),
                    NewCropCode = reader.Get<string>(6),
                    ProdSegCode = reader.Get<string>(7),
                    SyncCode = reader.Get<string>(8),
                    StatusCode = reader.Get<int>(9),
                    Maintainer = reader.Get<int>(10),
                    FemaleParent = reader.Get<int>(11),
                    MaleParent = reader.Get<int>(12),
                    Parent = reader.Get<int>(13),
                    LotNr = reader.Get<int>(14),
                    VarmasVarietyNr = reader.Get<int>(15),
                    CountryOfOrigin = reader.Get<string>(16),
                    UsePoNr = reader.Get<bool>(17),
                    Stem = reader.Get<string>(18),
                    linkedlot = reader.Get<int>(19)
                });
        }

        public async Task<IEnumerable<ColumnInfo>> GetColumnDetailForGermplasm(int gID)
        {
            return await DbContext.ExecuteReaderAsync(DataConstants.PR_GET_COLUMNS_INFO,
                CommandType.StoredProcedure,
                args => args.Add("@GID", gID), reader => new ColumnInfo
                {
                    ColumnID = reader.Get<int>(0),
                    ColumnLabel = reader.Get<string>(1),
                    PhenomeColID = reader.Get<string>(2),
                    VariableID = reader.Get<string>(3)
                });
        }

        public async Task ImportGermplasmFromPedigree(DataTable dtRowTVP, DataTable dtColumnsTVP, DataTable dtCellTVP,DataTable dtLotTVP, int gID)
        {
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_IMPORT_GERMPLASM_FROM_PEDIGREE,
                CommandType.StoredProcedure, args1 =>
                {
                    args1.Add("@TVPRow", dtRowTVP);
                    args1.Add("@TVPColumn", dtColumnsTVP);
                    args1.Add("@TVPCell", dtCellTVP);
                    args1.Add("@TVPlot", dtLotTVP);
                    args1.Add("@GID", gID);
                });
        }

        public async Task<IEnumerable<LotDeteilResult>> PhenomeLotIDExistsAsync(int phenomeLotGID)
        {
            return await DbContext.ExecuteReaderAsync(DataConstants.PR_GET_LOT_BY_PHENOME_LOT_ID,
                   CommandType.StoredProcedure, args => args.Add("@PhenomeLotID", phenomeLotGID),
                   reader => new LotDeteilResult
                   {
                       LotID = reader.Get<int>(0),
                       GID = reader.Get<int>(1)
                   });

        }

        public Task<IEnumerable<VarietyInfo>> GetVarietiesAsync(IEnumerable<int> gids)
        {
            return DbContext.ExecuteReaderAsync(DataConstants.PR_GET_VARIETIES,
                CommandType.StoredProcedure,
                args => args.Add("@GIDs", string.Join(",", gids)),
                reader => new VarietyInfo
                {
                    VarietyID = reader.Get<int>(0),
                    GID = reader.Get<int>(1),
                    SyncCode = reader.Get<string>(2),
                    CropCode = reader.Get<string>(3),
                    BrStationCode = reader.Get<string>(4),
                    FemaleParent = reader.Get<int?>(5),
                    MaleParent = reader.Get<int?>(6),
                    Maintainer = reader.Get<int?>(7),
                    TransferType = reader.Get<string>(8),
                    PONumber = reader.Get<string>(9),
                    VarmasStatus = reader.Get<string>(10),
                    MaintainerPONr = reader.Get<string>(11)
                });
        }

        public Task<IEnumerable<VarietyResult>> GetVarietiesWithStemAsync(IEnumerable<int> varietyIDs)
        {
            return DbContext.ExecuteReaderAsync(DataConstants.PR_GET_VARIETY_DETAIL_WITH_STEM,
                CommandType.StoredProcedure,
                args => args.Add("@VarietyIDs", string.Join(",", varietyIDs)), reader => new VarietyResult
                {
                    VarietyID = reader.Get<int>(0),
                    GID = reader.Get<int>(1),
                    ENumber = reader.Get<string>(2),
                    VarmasVarietyNr = reader.Get<int>(3),
                    Stem = reader.Get<string>(4),
                    StatusCode = reader.Get<int>(5)
                });
        }

        public async Task<bool> UpdateVarietyLinkAsync(int varietyID, string transferType, int newGID)
        {
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_UPDATE_GID_LINK,
                CommandType.StoredProcedure, args1 =>
                {
                    args1.Add("@VarietyID", varietyID);
                    args1.Add("@TransferType", transferType);
                    args1.Add("@NewGID", newGID);
                });

            return true;
        }

        public async Task<VarietyResult> GetVarietyNrOfParentAsync(int gID)
        {
            var result = await DbContext.ExecuteReaderAsync(DataConstants.PR_GET_PARENTS_VARITYNR,
                CommandType.StoredProcedure,
                args => args.Add("@GID", gID), reader => new VarietyResult
                {
                    FemaleParent = reader.Get<int>(1),
                    MaleParent = reader.Get<int>(2),
                    Maintainer = reader.Get<int>(3)
                });
            return result.FirstOrDefault();
        }

        public async Task<bool> UndoReplaceLOTAsync(UndoReplaceLotRequestArgs args)
        {
            var data = await DbContext.ExecuteNonQueryAsync(DataConstants.PR_UNDO_REPLACE_LOT,
                CommandType.StoredProcedure, args1 =>
                {
                    args1.Add("@GID", args.GID);
                });
            return true;
        }
    }
}
