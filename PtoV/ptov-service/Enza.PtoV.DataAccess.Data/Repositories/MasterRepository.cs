using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Security.Principal;
using System.Threading.Tasks;
using Enza.PtoV.Common.Extensions;
using Enza.PtoV.DataAccess.Abstract;
using Enza.PtoV.DataAccess.Data.Interfaces;
using Enza.PtoV.DataAccess.Interfaces;
using Enza.PtoV.Entities.Results;

namespace Enza.PtoV.DataAccess.Data.Repositories
{
    public class MasterRepository : Repository<object>, IMasterRepository
    {
        private readonly IUserContext userContext;
        public MasterRepository(IDatabase dbContext, IUserContext userContext) : base(dbContext)
        {
            this.userContext = userContext;
        }

        public async Task<DataTable> GetCropAsync()
        {
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_CROPS, CommandType.StoredProcedure);
            return data.Tables[0];
        }

        public async Task<DataTable> GetNewCropsAsync(string cropCode)
        {
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_NEWCROPS,
                CommandType.StoredProcedure, args => args.Add("@CropCode", cropCode));
            return data.Tables[0];
        }

        public async Task<DataTable> GetProductSegmentsAsync(string cropCode)
        {
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_PRODUCT_SEGMENTS,
                CommandType.StoredProcedure, args => args.Add("@CropCode", cropCode));
            return data.Tables[0];
        }

        public async Task<IEnumerable<ColumnResult>> GetColumnsAsync(string cropCode)
        {
            return await DbContext.ExecuteReaderAsync(DataConstants.PR_GET_COLUMNS,
                CommandType.StoredProcedure, args => args.Add("@CropCode", cropCode), reader => new ColumnResult
                {
                    ColumnID = reader.Get<int>(0),
                    ColumnNr = reader.Get<int>(1),
                    TraitID = reader.Get<int?>(2),
                    ColumnLabel = reader.Get<string>(3),
                    DataType = reader.Get<string>(4)
                });
        }

        public async Task<TransferTypeForCropResult> GetTransferTypePerCropAsync(string cropCode)
        {
            var data =  await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_TRANSFERTYPE_PER_CROP,
                CommandType.StoredProcedure, 
                args => args.Add("@CropCode", cropCode));
            if (data.Tables[0].Rows.Count == 0)
                return null;

            var dr = data.Tables[0].Rows[0];
            return new TransferTypeForCropResult
            {
                CropCode = dr["CropCode"].ToText(),
                HasCms = dr["HasCms"].ToBoolean(),
                HasHybrid = dr["HasHybrid"].ToBoolean(),
                HasOp = dr["HasOp"].ToBoolean(),
                HasBulb = dr["HasBulb"].ToBoolean(),
                UsePONr = dr["UsePONr"].ToBoolean()
            };
        }

        public async Task<DataTable> GetCountryOfOriginAsync()
        {
            var data = await DbContext.ExecuteDataSetAsync(DataConstants.PR_GETCOUNTRIES, CommandType.StoredProcedure);
            return data.Tables[0];
        }

        public async Task<DataTable> GetUserCropsAsync(IPrincipal user)
        {
            var crops = user.GetCrops();
            if (!crops.Any())
            {
                var dt = new DataTable();
                dt.Columns.Add("CropCode", typeof(string));
                dt.Columns.Add("CropName", typeof(string));
                return dt;
            }
            if (crops.Any(x => x.ToUpper() == "ALL"))
            {
                return await GetCropAsync();
            }

            var allCrops = await GetCropAsync();
            var cropCodes = crops.Select(x => string.Format("'{0}'", x));
            var cropsAsString = string.Join(",", cropCodes);
            allCrops.DefaultView.RowFilter = string.Format("CropCode IN ({0})", cropsAsString);
            return allCrops.DefaultView.ToTable();
        }
    }
}
