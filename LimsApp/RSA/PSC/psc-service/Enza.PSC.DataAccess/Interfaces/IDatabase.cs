using System;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;

namespace Enza.PSC.DataAccess.Interfaces
{
    public interface IDatabase
    {
        int CommandTimeout { get; set; }

        int ExecuteNonQuery(string query);
        int ExecuteNonQuery(string query, Action<IDictionary<string, object>> parameters);
        int ExecuteNonQuery(string query, IDictionary<string, object> parameters);

        Task<int> ExecuteNonQueryAsync(string query);
        Task<int> ExecuteNonQueryAsync(string query, CommandType commandType, IDictionary<string, object> parameters);
        Task<int> ExecuteNonQueryAsync(string query, CommandType commandType, Action<IDictionary<string, object>> parameters);
        Task<int> ExecuteNonQueryAsync(string query, Action<IDictionary<string, object>> parameters);
        Task<int> ExecuteNonQueryAsync(string query, IDictionary<string, object> parameters);

        Task<IEnumerable<T>> ExecuteListAsync<T>(string query, Func<IDataReader, T> mapping);

        Task<IEnumerable<T>> ExecuteListAsync<T>(string query, Action<IDictionary<string, object>> parameters,
            Func<IDataReader, T> mapping);

        Task<IEnumerable<T>> ExecuteListAsync<T>(string query, IDictionary<string, object> parameters,
            Func<IDataReader, T> mapping);
    }
}
