using System.Collections.Generic;
using System.Data;
using System.Security.Principal;
using System.Threading.Tasks;
using Enza.UTM.Entities;
using Enza.UTM.Entities.Args;

namespace Enza.UTM.BusinessAccess.Interfaces
{
    public interface IMasterService
    {
        Task<IEnumerable<Crop>> GetCropAsync();
        Task<IEnumerable<TraitValueLookup>> GetTraitValuesAsync(string cropCode, int traitID);
        Task<IEnumerable<BreedingStation>> GetBreedingStationAsync();
        Task<IEnumerable<TestProtocol>> GetTestProtocolsAsync();
        Task<IEnumerable<SiteLocation>> GetSitesAsync();

        Task<DataTable> GetCNTProcessesAsync();
        Task SaveCNTProcessAsync(IEnumerable<CNTProcessRequestArgs> items);
        Task<DataTable> GetCNTLabLocationsAsync();
        Task SaveCNTLabLocationsAsync(IEnumerable<CNTLabLocationRequestArgs> items);

        Task<DataTable> GetCNTStartMaterialsAsync();
        Task SaveCNTStartMaterialsAsync(IEnumerable<CNTStartMaterialRequestArgs> items);

        Task<DataTable> GetCNTTypesAsync();
        Task SaveCNTTypesAsync(IEnumerable<CNTTypeRequestArgs> items);
        Task<IEnumerable<Crop>> GetUserCropsAsync(IPrincipal user);
        Task<IEnumerable<string>> GetUserCropCodesAsync(IPrincipal user);
    }
}
