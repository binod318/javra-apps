using Microsoft.Data.Sqlite;
using System;
using System.Threading.Tasks;

namespace Enza.DataAccess
{
    public abstract class Repository1<T> : IRepository1<T> where T : new()
    {

        private SqliteConnection connection;

        protected Repository1(string conString)
        {
            try
            {
                //this.connection = new SqliteConnection(conString);
                this.connection = new SqliteConnection();
                connection.ConnectionString = conString;
            }
            catch (Exception e)
            {
                throw;
            }

        }

        //protected Repository1(SqliteConnection connection)
        //{
        //    this.connection = connection;
        //}

        public SqliteConnection DbContextAsync()
        {
            return connection;
        }

        public SqliteConnection DbContext()
        {
            return connection;
        }
        

        public bool OpenConnection()
        {
            connection.Open();
            return true;
        }

        public async Task<bool> OpenConnectionAsync()
        {
            await connection.OpenAsync();
            return true;
        }

        public bool CloseConnection()
        {
            connection.Close();
            return true;
        }
    }
}
