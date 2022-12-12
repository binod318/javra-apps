using System;
using System.Data;
using System.Threading.Tasks;
using Enza.PtoV.DataAccess.Abstract;
using Enza.PtoV.DataAccess.Data.Interfaces;
using Enza.PtoV.DataAccess.Interfaces;
using Enza.PtoV.Entities.Results;

namespace Enza.PtoV.DataAccess.Data.Repositories
{
    public class PhenomeRepository : Repository<object>, IPhenomeRepository
    {
        private readonly IUserContext userContext;

        public PhenomeRepository(IDatabase dbContext, IUserContext userContext) : base(dbContext)
        {
            this.userContext = userContext;
        }

        
    }
}
