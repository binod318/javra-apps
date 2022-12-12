using System;
using Enza.PSC.DataAccess.Interfaces;

namespace Enza.PSC.DataAccess.Abstract
{
    public abstract class Repository<T> : IDisposable, IRepository<T> where T : class
    {
        private bool disposed;
        
        #region IDisposable Members

        protected virtual void Dispose(bool disposing)
        {
            if (disposed) return;
            
            disposed = true;
        }
        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }
        ~Repository()
        {
            Dispose(false);
        }

        #endregion
    }
}
