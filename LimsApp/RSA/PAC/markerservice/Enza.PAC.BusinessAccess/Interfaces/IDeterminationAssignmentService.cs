using Enza.PAC.Entities.Args;
using Enza.PAC.Entities.Results;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;

namespace Enza.PAC.BusinessAccess.Interfaces
{
    public interface IDeterminationAssignmentService
    {
        Task<JsonResponse> GetDeterminationAssignmentsAsync(GetDeterminationAssignmentsRequestArgs requestArgs);
        Task<JsonResponse> ConfirmPlanningAsync(ConfirmPlanningRequestArgs requestArgs);
        Task PlanDeterminationAssignmentsAsync(AutomaticalPlanRequestArgs requestArgs);
        Task<bool> DeclusterAsync();
        Task<DataSet> GetDAOverviewAsync(BatchOverviewRequestArgs requestArgs);
        Task<bool> SetDeterminationAssignmentsAsync(GetDAOverviewRequestArgs requestArgs);
        Task<DataSet> GetDataForDecisionScreenAsync(int id);
        Task<DataSet> GetDataForDecisionDetailScreenAsync(GetDataForDecisionDetailRequestArgs requestArgs);
        Task<DataSet> GetPlatesAndPositionsForPatternAsync(int id);
        Task<bool> SavePatternRemarksAsync(List<UpdatePatternRemarksRequestArgs> requestArgs);
        Task<bool> SendResultToABSAsync(SendResultToABSRequestArgs requestArgs);
        Task<bool> ApproveDeterminationAsync(int detAssignmentID);
        Task<bool> RetestDetAssignmentAsync(int detAssignmentID);
        Task<bool> UpdateRemarksAsync(UpdateRemarksRequestArgs args);
    }
}
