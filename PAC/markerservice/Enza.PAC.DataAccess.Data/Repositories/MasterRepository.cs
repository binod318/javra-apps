using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;
using Enza.PAC.DataAccess.Abstract;
using Enza.PAC.DataAccess.Data.Interfaces;
using Enza.PAC.Entities.Results;

namespace Enza.PAC.DataAccess.Data.Repositories
{
    public class MasterRepository : Repository<object>, IMasterRepository
    {
        public MasterRepository(IPACDatabase dbContext) : base(dbContext)
        {
            
        }

        public async Task<List<YearResult>> GetYearAsync()
        {
            var yearList = Enumerable.Range(DateTime.Now.Year - 2, 5);

            //Default display week is current week + 1
            var selectedYear = DateTime.Now.AddDays(7);
            var data = yearList.Select(x => new YearResult
            {
                Year = x,
                Current = (x == selectedYear.Year) ? true : false
            }).ToList();
            return await Task.FromResult(data);
        }

        public async Task<DataTable> GetperiodAsync(int year)
        {
            var ds = await DbContext.ExecuteDataSetAsync(DataConstants.PR_PAC_GET_PERIOD, CommandType.StoredProcedure, args =>
            {
                args.Add("@Year", year);
            });
            return ds.Tables[0];
        }

        public async Task<DataTable> GetCropAsync()
        {
            var ds = await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_CROP, CommandType.StoredProcedure);
            return ds.Tables[0];
        }

        public async Task<DataTable> GetMarkersAsync(string cropCode, string markerName, bool? showPacMarkers)
        {
            var ds = await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_MARKERS, CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@CropCode", cropCode);
                    args.Add("@MarkerName", markerName);
                    args.Add("@ShowPacMarkers", showPacMarkers);
                });
            return ds.Tables[0];
        }

        public async Task<DataTable> GetVarietiesAsync(string cropCode, string varietyName)
        {
            var ds = await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_VARIETIES, CommandType.StoredProcedure,
                args =>
                {
                    args.Add("@CropCode", cropCode);
                    args.Add("@VarietyName", varietyName);
                });
            return ds.Tables[0];
        }
    }    
}
