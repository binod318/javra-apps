using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using Enza.PAC.BusinessAccess.Interfaces;
using Enza.PAC.DataAccess.Data.Interfaces;
using Enza.PAC.Entities.Args;
using Enza.PAC.Entities.Results;

namespace Enza.PAC.BusinessAccess.Services
{
    public class PacCapacityService : IPacCapacityService
    {
        private readonly IPacCapacityRepository _pacCapacityRepo;
        public PacCapacityService(IPacCapacityRepository pacCapacityRepo)
        {
            _pacCapacityRepo = pacCapacityRepo;
        }

        public async Task<JsonResponse> GetPlanningCapacityAsync(int year)
        {
            var data = await _pacCapacityRepo.GetPlanningCapacityAsync(year);
            var result = new JsonResponse
            {
                Data = data
            };
            return result;
        }
        public async Task<JsonResponse> SaveLabCapacityAsync(List<SaveCapacityRequestArgs> args)
        {
            await _pacCapacityRepo.SaveLabCapacityAsync(args);
            var result = new JsonResponse();
            result.Message = "Saved Successfully.";
            return result;
        }

        public async Task<JsonResponse> GetPACPlanningCapacitySOAsync(int periodID)
        {
            var data = await _pacCapacityRepo.GetPACPlanningCapacitySOAsync(periodID);
            var result = new JsonResponse
            {
                Data = data
            };
            return result;
        }

        public async Task<JsonResponse> SavePACPlanningCapacitySOAsync(List<SavePlanningCapacitySOArgs> args)
        {
            var result = new JsonResponse();
            var week = new List<string>();
            var data = await _pacCapacityRepo.SavePACPlanningCapacitySOAsync(args);
            if(data.Tables[0].Rows.Count > 0)
            {
                foreach(DataRow dr in data.Tables[0].Rows)
                {
                    week.Add(dr[1].ToString());
                }
                result.AddError("Error on saving data. Capacity limit exceeded for week: " + string.Join(",",week));
            }
            else
                result.Message = "Saved Successfully.";
            return result;
        }
    }
}
