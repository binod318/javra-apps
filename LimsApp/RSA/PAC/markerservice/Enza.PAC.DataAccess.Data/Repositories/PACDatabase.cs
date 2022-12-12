using Enza.PAC.DataAccess.Data.Interfaces;
using Enza.PAC.DataAccess.Databases;
using Enza.PAC.DataAccess.Interfaces;

namespace Enza.PAC.DataAccess.Data.Repositories
{
    public class PACDatabase : SqlDatabase, IPACDatabase
    {
        public PACDatabase(string nameOrConnectionString, IUserContext userContext) : base(nameOrConnectionString, userContext)
        {
        }
    }
}
