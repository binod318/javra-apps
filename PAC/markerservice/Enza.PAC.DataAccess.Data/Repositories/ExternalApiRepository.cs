using Enza.PAC.Common.Extensions;
using Enza.PAC.DataAccess.Abstract;
using Enza.PAC.DataAccess.Data.Interfaces;
using Enza.PAC.Entities.Args;
using Enza.PAC.Entities.Results;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;

namespace Enza.PAC.DataAccess.Data.Repositories
{
    public class ExternalApiRepository : Repository<object>, IExternalApiRepository
    {
        public ExternalApiRepository(IPACDatabase dbContext) : base(dbContext)
        {
        }

        public async Task<DataSet> GetPlateSampleInfoAsync(GetPlateSampleInfoRequestArgs requestArgs)
        {
            return await DbContext.ExecuteDataSetAsync(DataConstants.PR_GET_PLATE_SAMPLEINFO, CommandType.StoredProcedure,
               args =>
               {
                   args.Add("@LabPlateID", requestArgs.PlateID);
               });  
        }
    }
}
