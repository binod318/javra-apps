using System.Threading.Tasks;
using Enza.PAC.BusinessAccess.Interfaces;
using Enza.PAC.DataAccess.Data.Interfaces;
using Enza.PAC.Entities.Args;
using Enza.PAC.Entities.Results;

namespace Enza.PAC.BusinessAccess.Services
{
    public class CriteriaPerCropService : ICriteriaPerCropService
    {
        private readonly ICriteriaPerCropRepository _criteriaPerCropRepository;
        public CriteriaPerCropService(ICriteriaPerCropRepository criteriaPerCropRepository)
        {
            _criteriaPerCropRepository = criteriaPerCropRepository;
        }

        public async Task<JsonResponse> GetAllCriteriaPerCropAsync(GetCriteriaPerCropRequestArgs requestArgs)
        {
            var data = await _criteriaPerCropRepository.GetAllCriteriaPerCropAsync(requestArgs);
            return new JsonResponse
            {
                Data = new
                {
                    Data = data.Tables[0],
                    Columns = data.Tables[1],
                    Crops = data.Tables[2],
                    MaterialTypes = data.Tables[3]
                },
                Total = requestArgs.TotalRows
            };
        }

        public async Task<JsonResponse> PostAsync(CriteriaPerCropRequestArgs requestArgs)
        {
            await _criteriaPerCropRepository.PostAsync(requestArgs);

            var message = requestArgs.Action == "i" ? "Criteria per crop added successfully." :
                          (requestArgs.Action == "u" ? "Criteria per crop updated successfully." :
                                                "Criteria per crop deleted successfully.");

            return new JsonResponse
            {
                Message = message
            };
        }

    }
}
