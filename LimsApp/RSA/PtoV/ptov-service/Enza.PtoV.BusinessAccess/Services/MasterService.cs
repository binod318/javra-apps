using System.Collections.Generic;
using System.Data;
using System.Security.Principal;
using System.Threading.Tasks;
using Enza.PtoV.BusinessAccess.Interfaces;
using Enza.PtoV.DataAccess.Data.Interfaces;

namespace Enza.PtoV.BusinessAccess.Services
{
    public class MasterService : IMasterService
    {
        private readonly IMasterRepository repository;
        public MasterService(IMasterRepository repository)
        {
            this.repository = repository;
        }

        public async Task<DataTable> GetCountryOfOriginAsync()
        {
            return await repository.GetCountryOfOriginAsync();
        }

        public async Task<DataTable> GetCropAsync()
        {
            return await repository.GetCropAsync();

        }

        public Task<DataTable> GetNewCropsAsync(string cropCode)
        {
            return repository.GetNewCropsAsync(cropCode);
        }

        public Task<DataTable> GetProductSegmentsAsync(string cropCode)
        {
            return repository.GetProductSegmentsAsync(cropCode);
        }

        public Task<DataTable> GetUserCropsAsync(IPrincipal user)
        {
            return repository.GetUserCropsAsync(user);
        }
    }
}
