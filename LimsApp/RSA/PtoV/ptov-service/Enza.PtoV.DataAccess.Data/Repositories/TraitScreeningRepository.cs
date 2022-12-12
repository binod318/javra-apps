using System.Data;
using System.Threading.Tasks;
using Enza.PtoV.DataAccess.Data.Interfaces;
using Enza.PtoV.Entities.Args;
using Enza.PtoV.DataAccess.Abstract;
using Enza.PtoV.DataAccess.Interfaces;
using Enza.PtoV.Common.Extensions;
using System;

namespace Enza.PtoV.DataAccess.Data.Repositories
{
    public class TraitScreeningRepository : Repository<object>, ITraitScreeningRepository
    {
        public TraitScreeningRepository(IDatabase dbContext):base(dbContext)
        {

        }
        public async Task<DataTable> GetTraitScreeningAsync(TraitScreeningRequestArgs requestargs)
        {
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_TRAIT_SCREENING, CommandType.StoredProcedure, args =>
              {
                  args.Add("@PageNumber", requestargs.PageNumber);
                  args.Add("@PageSize", requestargs.PageSize);
                  args.Add("@Filter", requestargs.ToFilterString());
                  args.Add("@Sort", requestargs.ToSortString());
              });
            if(data.Tables[0].Rows.Count > 0)
                requestargs.TotalRows = data.Tables[0].Rows[0]["TotalRows"].ToInt32();
            data.Tables[0].Columns.Remove("TotalRows");
            return data.Tables[0];
        }

        public async Task<DataTable> GetTraitScreeningResultAsync(TraitScreeningRequestArgs requestargs)
        {
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_TRAIT_SCREENING_RESULT, CommandType.StoredProcedure, args =>
            {
                args.Add("@PageNumber", requestargs.PageNumber);
                args.Add("@PageSize", requestargs.PageSize);
                args.Add("@Filter", requestargs.ToFilterString());
                args.Add("@Sort", requestargs.ToSortString());
            });
            if (data.Tables[0].Rows.Count > 0)
                requestargs.TotalRows = data.Tables[0].Rows[0]["TotalRows"].ToInt32();
            data.Tables[0].Columns.Remove("TotalRows");
            return data.Tables[0];
        }
        public async Task<DataTable> GetTraitsAsync(string traitName, string cropCode)
        {
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_TRAITS, CommandType.StoredProcedure, args =>
            {
                args.Add("@TraitName", traitName);
                args.Add("@CropCode", cropCode);

            });
            return data.Tables[0];
        }
        public async Task<DataTable> GetScreeningAsync(string ScreeningName, string cropCode)
        {
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_SCREENING, CommandType.StoredProcedure, args =>
            {
                args.Add("@SFColumnLabel", ScreeningName);
                args.Add("@CropCode", cropCode);

            });
            return data.Tables[0];
        }
        public async Task<DataTable> SaveTraitScreeningAsync(SaveTraitScreeningRequestArgs requestArgs)
        {
            await DbContext.ExecuteDataSetAsync(DataConstants.PR_SAVE_TRAIT_SCREENING, CommandType.StoredProcedure, args =>
            {
                args.Add("@TVP_RelationTraitScreening", requestArgs.ToRelationTraitScreeningTVP());
            });
            return await GetTraitScreeningAsync(new TraitScreeningRequestArgs
            {
                Filter = requestArgs.Filter,
                PageNumber = requestArgs.PageNumber,
                PageSize = requestArgs.PageSize,
                Sorting = requestArgs.Sorting,
                TotalRows = requestArgs.TotalRows
            });
        }
        public async Task<DataTable> GetTraitLOVAsync(int traitID)
        {
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_TRAIT_LOV, CommandType.StoredProcedure, args =>
            {
                args.Add("@TraitID", traitID);

            });
            return data.Tables[0];
        }

        public async Task<DataTable> GetScreeningLOVAsync(int screeningFieldID)
        {
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_SCREENING_LOV, CommandType.StoredProcedure, args =>
            {
                args.Add("@screeningFieldID", screeningFieldID);

            });
            return data.Tables[0];
        }

        public async Task<DataTable> GetTraitsWithScreeningAsync(string traitName, string cropCode)
        {
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_TRAITS_WITH_SCREENING, CommandType.StoredProcedure, args =>
            {
                args.Add("@TraitName", traitName);
                args.Add("@CropCode", cropCode);
            });
            return data.Tables[0];
        }

        public async Task<DataTable> SaveTraitScreeningResultAsync(SaveTraitScreeningResultArgs requestargs)
        {
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_SAVE_TRAIT_SCREENING_RESULT, CommandType.StoredProcedure, args =>
            {
                args.Add("@TVP_TraitScreeningResult", requestargs.ToTraitScreeningResultTVP());
            });
            var args1 = new TraitScreeningRequestArgs
            {
                Filter = requestargs.Filter,
                PageNumber = requestargs.PageNumber,
                PageSize = requestargs.PageSize,
                Sorting = requestargs.Sorting,
                TotalRows = requestargs.TotalRows
            };
            var data1 = await GetTraitScreeningResultAsync(args1);
            requestargs.TotalRows = args1.TotalRows;
            return data1;
        }

        public async Task<bool> RemoveUnmappedColumns(RemoveColumnsRequestArgs args)
        {
            var dataAsJson = args.Columns.Serialize();
            var data = await DbContext.ExecuteNonQueryAsync(DataConstants.PR_REMOVE_UNMAPPED_COLUMNS, CommandType.StoredProcedure, args1 =>
            {
                args1.Add("@CropCode", args.CropCode);
                args1.Add("@DataAsJson", dataAsJson);
            });
            return true;
        }
    }
}
