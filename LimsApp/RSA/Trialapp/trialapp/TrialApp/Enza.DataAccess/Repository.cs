using SQLite;
using System;
using System.Collections.Generic;
using System.Linq.Expressions;
using System.Threading.Tasks;

namespace Enza.DataAccess
{
    public abstract class Repository<T> : IRepository<T> where T : new()
    {

        private readonly SQLiteAsyncConnection connectionAsync;
        private readonly SQLiteConnection connection;

        protected Repository(string conString)
        {
            try
            {
                this.connection = new SQLiteConnection(conString);
                this.connection.BusyTimeout = TimeSpan.FromSeconds(30);
            }
            catch (Exception)
            {

                throw;
            }

        }

        protected Repository(SQLiteAsyncConnection connection)
        {
            this.connectionAsync = connection;
        }

        public SQLiteAsyncConnection DbContextAsync()
        {
            return connectionAsync;
        }

        public SQLiteConnection DbContext()
        {
            return connection;
        }
        public virtual bool Add(T entity)
        {
            throw new NotImplementedException();
        }

        public virtual Task<int> AddAsync(T entity)
        {
            return DbContextAsync().InsertAsync(entity);
        }

        public virtual bool Delete(T entity)
        {
            throw new NotImplementedException();
        }

        public virtual Task<bool> DeleteAsync(T entity)
        {
            throw new NotImplementedException();
        }

        public virtual T Get(Expression<Func<T, bool>> predicate)
        {
            throw new NotImplementedException();
        }

        public virtual IEnumerable<T> GetAll(Expression<Func<T, bool>> predicate)
        {
            throw new NotImplementedException();
        }

        public virtual Task<IEnumerable<T>> GetAllAsync(Expression<Func<T, bool>> predicate)
        {
            throw new NotImplementedException();
        }

        public virtual Task<T> GetAsync(Expression<Func<T, bool>> predicate)
        {
            throw new NotImplementedException();
        }

        public virtual bool Update(T entity)
        {
            throw new NotImplementedException();
        }

        public virtual Task<bool> UpdateAsync(T entity)
        {
            throw new NotImplementedException();
        }
    }
}
