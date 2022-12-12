using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using Enza.PAC.BusinessAccess.Interfaces;
using Enza.PAC.Common;
using Enza.PAC.Common.Extensions;
using Enza.PAC.DataAccess.Data.Interfaces;
using Enza.PAC.DataAccess.Interfaces;
using Enza.PAC.DataAccess.Services.Proxies;
using Enza.PAC.Entities.Args;
using Enza.PAC.Entities.Results;

namespace Enza.PAC.BusinessAccess.Services
{
    public class DeterminationAssignmentService : IDeterminationAssignmentService
    {
        private readonly IDeterminationAssignmentRepository  _determinationAssignmentRepository;
        //private readonly IUserContext userContext;

        public DeterminationAssignmentService(IDeterminationAssignmentRepository determinationAssignmentRepository) //IUserContext userContext, 
        {
            //this.userContext = userContext;
            _determinationAssignmentRepository = determinationAssignmentRepository;
        }

        public async Task<JsonResponse> GetDeterminationAssignmentsAsync(GetDeterminationAssignmentsRequestArgs requestArgs)
        {
            return await _determinationAssignmentRepository.GetDeterminationAssignmentsAsync(requestArgs);
        }

        public async Task<JsonResponse> ConfirmPlanningAsync(ConfirmPlanningRequestArgs requestArgs)
        {
            var dt = await _determinationAssignmentRepository.ConfirmPlanningAsync(requestArgs);

            var result = new JsonResponse
            {
                Message = "Saved Successfully."
            };

            //there is validation errors in sp
            if (dt != null)
            {
                if (dt.Rows.Count > 0)
                {
                    result.Message = string.Empty;
                    result.Errors = dt.AsEnumerable()
                        .Select(x => new Error
                        {
                            Type = 1,
                            Message = $"Capacity exceeded for Crop: { x.Field<string>("ABSCropCode")} and Method: {x.Field<string>("MethodCode")}."
                        }).ToList();
                }
                else
                {
                    result.Message = string.Empty;
                    result.Errors = dt.AsEnumerable()
                    .Select(x => new Error
                    {
                        Type = 1,
                        Message = "Error updating status code on ABS!"
                    }).ToList(); ;
                }
            }
            else
            {
                var res = await SetDeterminationAssignmentsAsync(new GetDAOverviewRequestArgs { PeriodID = requestArgs.PeriodID });
                if (!res)
                {
                    result.Message = string.Empty;
                    result.Errors = new List<Error>{ new Error
                    {
                        Type = 1,
                        Message = "Error updating status code on ABS!"
                    }}; 
                }
            }

            return result;
        }

        public Task PlanDeterminationAssignmentsAsync(AutomaticalPlanRequestArgs requestArgs)
        {
            return _determinationAssignmentRepository.PlanDeterminationAssignmentsAsync(requestArgs);
        }

        public async Task<bool> DeclusterAsync()
        {
            return await _determinationAssignmentRepository.DeclusterAsync();
        }

        public async Task<DataSet> GetDAOverviewAsync(BatchOverviewRequestArgs requestArgs)
        {
            return await _determinationAssignmentRepository.GetDAOverviewAsync(requestArgs);
        }

        public async Task<bool> SetDeterminationAssignmentsAsync(GetDAOverviewRequestArgs requestArgs)
        {
            var data = await _determinationAssignmentRepository.GetDAForStatusUpdateAsync(requestArgs);
            return await ExecuteUpdateDeterminationStatusCodeAsync(data);            
        }

        private async Task<bool> ExecuteUpdateDeterminationStatusCodeAsync(IEnumerable<DeterminationAssignment> data)
        {
            var credentials = Credentials.GetCredentials();
            using (var svc = new ABSServiceSoapClient
            {
                Url = ConfigurationManager.AppSettings["ABSServiceUrlSet"],
                Credentials = new NetworkCredential(credentials.UserName, credentials.Password)
            })
            {
                var model = new ListQualityConnect() { DeterminationAssignments = data.ToList() };
                model.UserName = ""; //userContext?.Name;
                svc.Model = model;
                var result = await svc.UpdateDeterminationStatusCodeAsync();
                if (result.Message.EqualsIgnoreCase("S"))
                    return true;                
            }
            return false;
        }

        public async Task<DataSet> GetDataForDecisionScreenAsync(int id)
        {
            return await _determinationAssignmentRepository.GetDataForDecisionScreenAsync(id);
        }

        public async Task<DataSet> GetDataForDecisionDetailScreenAsync(GetDataForDecisionDetailRequestArgs requestArgs)
        {
            return await _determinationAssignmentRepository.GetDataForDecisionDetailScreenAsync(requestArgs);
        }
        public async Task<DataSet> GetPlatesAndPositionsForPatternAsync(int id)
        {
            return await _determinationAssignmentRepository.GetPlatesAndPositionsForPatternAsync(id);
        }

        public async Task<bool> SendResultToABSAsync(SendResultToABSRequestArgs requestArgs)
        {
            return await _determinationAssignmentRepository.SendResultToABSAsync(requestArgs);            
        }
        
        public async Task<bool> SavePatternRemarksAsync(List<UpdatePatternRemarksRequestArgs> requestArgs)
        {
            return await _determinationAssignmentRepository.SavePatternRemarksAsync(requestArgs);            
        }

        public Task<bool> ApproveDeterminationAsync(int detAssignmentID)
        {
            return _determinationAssignmentRepository.ApproveDeterminationAsync(detAssignmentID);

        }
        public Task<bool> RetestDetAssignmentAsync(int detAssignmentID)
        {
            return _determinationAssignmentRepository.RetestDetAssignmentAsync(detAssignmentID);
        }

        public async Task<bool> UpdateRemarksAsync(UpdateRemarksRequestArgs args)
        {
            return await _determinationAssignmentRepository.UpdateRemarksAsync(args);
        }

    }
}
