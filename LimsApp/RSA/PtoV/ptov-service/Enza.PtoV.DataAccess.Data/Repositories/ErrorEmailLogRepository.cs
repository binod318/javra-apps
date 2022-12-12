using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using Enza.PtoV.DataAccess.Abstract;
using Enza.PtoV.DataAccess.Data.Interfaces;
using Enza.PtoV.DataAccess.Interfaces;

namespace Enza.PtoV.DataAccess.Data.Repositories
{
    public class ErrorEmailLogRepository : Repository<object>, IErrorEmailLogRepository
    {
        public ErrorEmailLogRepository(IDatabase dbContext) : base(dbContext)
        {
        }

        public Task<IEnumerable<string>> GetUnsentEmailLogsAsync(string cropCodes)
        {
            return DbContext.ExecuteReaderAsync(DataConstants.PR_GET_UNSENT_EMAIL_LOGS, CommandType.StoredProcedure,
                p => p.Add("@CropCodes", cropCodes), 
                reader => reader.Get<string>(0));
        }

        public Task UpdateSentEmailLogAsync(string cropCode, string errorMessage)
        {
            return DbContext.ExecuteNonQueryAsync(DataConstants.PR_UPDATE_SENT_EMAIL_LOG,
                CommandType.StoredProcedure, args =>
            {
                args.Add("@CropCode", cropCode);
                args.Add("@ErrorMessage", cropCode);
            });
        }
    }
}
