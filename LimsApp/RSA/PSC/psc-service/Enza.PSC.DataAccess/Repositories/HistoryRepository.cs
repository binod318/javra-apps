using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;
using Enza.PSC.DataAccess.Abstract;
using Enza.PSC.DataAccess.Data.Extensions;
using Enza.PSC.DataAccess.Interfaces;
using Enza.PSC.DataAccess.Repositories.Interfaces;
using Enza.PSC.Entities;
using Enza.PSC.Entities.Bdtos;

namespace Enza.PSC.DataAccess.Repositories
{
    public class HistoryRepository : Repository<History>, IHistoryRepository
    {
        private readonly IDatabase db;
        private readonly IUserContext _userContext;

        public HistoryRepository(IDatabase db, IUserContext userContext)
        {
            this.db = db;
            _userContext = userContext.GetContext();
        }

        public async Task<IEnumerable<History>> GetAllAsync(HistoryRequestArgs request)
        {
            //Remove all old data and keep only 10000 records.
            await CleanUpHistoryAsync();

            var sb = new StringBuilder(@"SELECT 
                                              [PlateIDBarcode]
                                              ,[SampleNrBarcode]
                                              ,[User]
                                              ,Format(CreatedDate,'yyyy-MM-dd HH:mm:ss') AS 'CreatedDate'
                                              ,[IsMatched]
                                        FROM History 
                                        WHERE 1 = 1 ");
            if (request != null)
            {
                if (!string.IsNullOrWhiteSpace(request.PlateIDBarcode))
                {
                    sb.Append("AND PlateIDBarcode LIKE '%@PlateIDBarcode%' ");
                }
                if (!string.IsNullOrWhiteSpace(request.SampleNrBarcode))
                {
                    sb.Append("AND SampleNrBarcode LIKE '%@SampleNrBarcode%' ");
                }
                if (!string.IsNullOrWhiteSpace(request.User))
                {
                    sb.Append("AND User LIKE '%@User%' ");
                }               
            }
            sb.Append("ORDER BY CreatedDate DESC ");

            return await db.ExecuteListAsync(sb.ToString(), args =>
            {
                args.Add("@PlateIDBarcode", request?.PlateIDBarcode);
                args.Add("@SampleNrBarcode", request?.SampleNrBarcode);
                args.Add("@User", request?.User);
            }, reader => new History
            {
                PlateIDBarcode = reader.Get<string>(0),
                SampleNrBarcode = reader.Get<string>(1),
                User = reader.Get<string>(2),
                CreatedDate = reader.Get<string>(3),
                IsMatched = reader.Get<bool>(4)
            });
        }

        public async Task<int> SaveAsync(History history)
        {
            const string query = "PR_SaveOrUpdateHistory";
            var rs = await db.ExecuteNonQueryAsync(query,System.Data.CommandType.StoredProcedure, args =>
            {
                args.Add("@PlateIDBarcode", history.PlateIDBarcode);
                args.Add("@SampleNrBarcode", history.SampleNrBarcode);
                args.Add("@User", _userContext.Name);
                args.Add("@IsMatched", history.IsMatched);
            });
            return rs;
        }

        async Task CleanUpHistoryAsync()
        {
            var query = @"DELETE FROM History
                        WHERE CreatedDate < 
                        (
                            SELECT MIN(CreatedDate)
                            FROM
                            (
                                SELECT 
                                    CreatedDate
                                FROM History
                                ORDER BY CreatedDate DESC
                                OFFSET 0 ROWS
		                        FETCH NEXT 10000 ROWS ONLY
                            ) V1
                        )";
            await db.ExecuteNonQueryAsync(query);
        }
    }
}
