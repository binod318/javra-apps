using Enza.PtoV.BusinessAccess.Interfaces;
using Enza.PtoV.DataAccess.Data.Interfaces;
using Enza.PtoV.Entities.Args;
using System.Threading.Tasks;
using Enza.PtoV.Entities.Results;

namespace Enza.PtoV.BusinessAccess.Services
{
    public class PedigreeService : IPedigreeService
    {
        private readonly IPedigreeRepository _repo;
        public PedigreeService(IPedigreeRepository repo)
        {
            _repo = repo;
        }

        public async Task<string> GetPedigreeAsync(GetPedigreeRequestArgs requestArgs)
        {
            return await _repo.GetPedigreeAsync(requestArgs);
        }
    }
}
