using System.Collections.Generic;
using Enza.PtoV.Entities.Results;
using System.Net.Http;
using System.Threading.Tasks;
using Enza.PtoV.Entities.Args;
using System.Data;
using System;
using Enza.PtoV.Entities;

namespace Enza.PtoV.BusinessAccess.Interfaces
{
    public interface IPhenomeServices
    {
        Task<GermplasmsImportResult> GetPhenomeDataAsync(HttpRequestMessage request, GermplasmsImportRequestArgs args);
        Task<SendToVarmasResult> SendToVarmasAsync(IEnumerable<SendToVarmasRequestArgs> args);
        Task<SendToVarmasResult> SyncToVarmasAsync(IEnumerable<int> args);
        void PrepareTVPs(DataTable TVP_Variety, DataTable Column, DataTable Cell, DataTable lot);
        Dictionary<string, (string Name, Type DataType)> PhenomeToPToVColumns();
        Task ValidatePONrForCMSCropAsync(HttpRequestMessage request, VarietyInfo variety, int gid, TransferTypeForCropResult transferType);

        Task<IEnumerable<GermplasmInfo>> GetGermplasmsAsync(HttpRequestMessage request,
             string cropCode,
             IEnumerable<int> gids,
             IEnumerable<string> cols);

        Task<string> GetAccessTokenAsync(string jwtToken);
    }
}
