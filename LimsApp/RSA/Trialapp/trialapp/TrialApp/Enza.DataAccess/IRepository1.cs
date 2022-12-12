using System;
using System.Collections.Generic;
using System.Linq.Expressions;

using System.Threading.Tasks;

namespace Enza.DataAccess
{
    public interface IRepository1<T>
    {
        bool OpenConnection();
        Task<bool> OpenConnectionAsync();
        bool CloseConnection();
    }
}
