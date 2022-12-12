using Enza.PAC.BusinessAccess.Interfaces;
using Enza.PAC.DataAccess.Data.Interfaces;
using Enza.PAC.Entities.Args;
using System;
using System.Threading.Tasks;

namespace Enza.PAC.BusinessAccess.Services
{
    public class LimsService : ILimsService
    {
        private readonly ILimsRepository _limsRepository;
        public LimsService(ILimsRepository limsRepository)
        {
            _limsRepository = limsRepository;
        }

        public async Task<bool> ReservePlateplansInLIMSCallbackAsync(ReservePlateplansInLIMSCallbackRequestArgs requestArgs)
        {
            var data = await _limsRepository.ReservePlateplansInLIMSCallbackAsync(requestArgs);
            return data;
        }

        public Task ReceiveResultsinKscoreCallbackAsync(ReceiveResultsinKscoreRequestArgs requestArgs)
        {
            return _limsRepository.ReceiveResultsinKscoreCallbackAsync(requestArgs);
        }
    }
}
