using Enza.PAC.Common.Extensions;
using Enza.PAC.DataAccess.Abstract;
using Enza.PAC.DataAccess.Data.Interfaces;
using Enza.PAC.Entities.Args;
using System;
using System.Configuration;
using System.Data;
using System.Linq;
using System.Threading.Tasks;

namespace Enza.PAC.DataAccess.Data.Repositories
{
    public class LimsRepository : Repository<object>, ILimsRepository
    {
        public LimsRepository(IPACDatabase dbContext) : base(dbContext)
        {
        }

        public async Task<bool> ReservePlateplansInLIMSCallbackAsync(ReservePlateplansInLIMSCallbackRequestArgs requestArgs)
        {
            var hybridAsParentCrop = ConfigurationManager.AppSettings["HybridAsParentCrop"];

            DbContext.CommandTimeout = 60 * 2;
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_RESERVE_PLATEPLANS_IN_LIMS_CALLBACK, CommandType.StoredProcedure,
               args =>
               {
                   args.Add("@LIMSPlateplanID", requestArgs.LIMSPlateplanID);
                   args.Add("@TestName", requestArgs.LIMSPlateplanName);
                   args.Add("@TestID", requestArgs.RequestID);
                   args.Add("@TVP_Plates", requestArgs.ToTVPPlates());
                   args.Add("@HybridAsParentCrop", hybridAsParentCrop);
               });
            return true;
        }


        public async Task ReceiveResultsinKscoreCallbackAsync(ReceiveResultsinKscoreRequestArgs requestArgs)
        {
            var hybridAsParentCrop = ConfigurationManager.AppSettings["HybridAsParentCrop"];

            var details = requestArgs.Plates.SelectMany(x => x.Wells.SelectMany(y => y.Markers.Select(z => new
            {
                x.LIMSPlateID,
                z.MarkerNr,
                z.AlleleScore,
                Position = $"{y.PlateRow}{y.PlateColumn:00}",
                z.CreationDate
            }))).ToList();

            var dataAsJson = details.ToJson();
            DbContext.CommandTimeout = 60 * 5;
            
            await DbContext.ExecuteNonQueryAsync(DataConstants.PR_RECEIVE_RESULTS_IN_KSCORE_CALLBACK, CommandType.StoredProcedure,
              args =>
              {
                  args.Add("@RequestID", requestArgs.RequestID);
                  args.Add("@DataAsJson", dataAsJson);
                  args.Add("@HybridAsParentCrop", hybridAsParentCrop);
              });
        }
    }
}
