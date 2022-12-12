using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Threading.Tasks;
using Enza.PSC.DataAccess.Interfaces;

namespace Enza.PSC.DataAccess.Data
{
    public class Database : IDatabase, IDisposable
    {
        private bool _disposed;
        private SqlConnection _conection;
        public Database(string connectionString)
        {
            _conection = new SqlConnection(connectionString);
            CommandTimeout = 30;
        }

        public int CommandTimeout { get; set; }

        private async Task OpenAsync()
        {
            if (_conection.State != ConnectionState.Open)
            {
                await _conection.OpenAsync();
                //set password for initial database, run only onece
                //_conection.ChangePassword(string.Empty);
            }
        }

        private void Open()
        {
            if (_conection.State != ConnectionState.Open)
            {
                _conection.Open();
                //set password for initial database, run only onece
                //_conection.ChangePassword(string.Empty);
            }
        }

        private void Close()
        {
            if (_conection.State != ConnectionState.Closed)
            {
                _conection.Close();
            }
        }

        #region ExecuteNonQuery

        public int ExecuteNonQuery(string query)
        {
            return ExecuteNonQuery(query, args => { });
        }
        public int ExecuteNonQuery(string query, Action<IDictionary<string, object>> parameters)
        {
            var args = new Dictionary<string, object>();
            parameters(args);
            return ExecuteNonQuery(query, args);
        }
        public int ExecuteNonQuery(string query, IDictionary<string, object> parameters)
        {
            int result;
            try
            {
                using (var cmd = _conection.CreateCommand())
                {
                    cmd.CommandText = query;
                    cmd.CommandType = CommandType.Text;
                    cmd.CommandTimeout = CommandTimeout;

                    #region Parameters

                    cmd.Parameters.Clear();
                    if (parameters != null && parameters.Count > 0)
                    {
                        foreach (var key in parameters.Keys)
                        {
                            var value = parameters[key];
                            if (value is SqlParameter)
                            {
                                cmd.Parameters.Add(value as SqlParameter);
                            }
                            else
                            {
                                var parameter = cmd.CreateParameter();
                                parameter.ParameterName = key;
                                //Key must be prefixed with @ while passing into this method
                                parameter.Value = (value ?? DBNull.Value);
                                cmd.Parameters.Add(parameter);
                            }
                        }
                    }

                    #endregion

                    Open();
                    result = cmd.ExecuteNonQuery();
                }
            }
            finally
            {
                Close();
            }
            return result;
        }


        public async Task<int> ExecuteNonQueryAsync(string query)
        {
            return await ExecuteNonQueryAsync(query, args => { });
        }

        public async Task<int> ExecuteNonQueryAsync(string query, CommandType commandType, IDictionary<string, object> parameters)
        {
            int result;
            try
            {
                using (var cmd = _conection.CreateCommand())
                {
                    cmd.CommandText = query;
                    cmd.CommandType = commandType;
                    cmd.CommandTimeout = CommandTimeout;

                    #region Parameters

                    cmd.Parameters.Clear();
                    if (parameters != null && parameters.Count > 0)
                    {
                        foreach (var key in parameters.Keys)
                        {
                            var value = parameters[key];
                            if (value is SqlParameter)
                            {
                                cmd.Parameters.Add(value as SqlParameter);
                            }
                            else
                            {
                                var parameter = cmd.CreateParameter();
                                parameter.ParameterName = key;
                                //Key must be prefixed with @ while passing into this method
                                parameter.Value = (value ?? DBNull.Value);
                                cmd.Parameters.Add(parameter);
                            }
                        }
                    }

                    #endregion

                    await OpenAsync();
                    result = await cmd.ExecuteNonQueryAsync();
                }
            }
            finally
            {
                Close();
            }
            return result;
        }

        public Task<int> ExecuteNonQueryAsync(string query, CommandType commandType, Action<IDictionary<string, object>> parameters)
        {
            var args = new Dictionary<string, object>();
            parameters(args);
            return ExecuteNonQueryAsync(query, commandType, args);
        }

        public async Task<int> ExecuteNonQueryAsync(string query, Action<IDictionary<string, object>> parameters)
        {
            var args = new Dictionary<string, object>();
            parameters(args);
            return await ExecuteNonQueryAsync(query, args);
        }
        public Task<int> ExecuteNonQueryAsync(string query, IDictionary<string, object> parameters)
        {
            return ExecuteNonQueryAsync(query, CommandType.Text, parameters);
        }

        #endregion

        #region ExecuteReader

        public async Task<IEnumerable<T>> ExecuteListAsync<T>(string query, Func<IDataReader, T> mapping)
        {
            return await ExecuteListAsync(query, args => { }, mapping);
        }

        public async Task<IEnumerable<T>> ExecuteListAsync<T>(string query,
            Action<IDictionary<string, object>> parameters, Func<IDataReader, T> mapping)
        {
            var args = new Dictionary<string, object>();
            parameters(args);
            return await ExecuteListAsync(query, args, mapping);
        }

        public async Task<IEnumerable<T>> ExecuteListAsync<T>(string query, IDictionary<string, object> parameters, Func<IDataReader, T> mapping)
        {
            var result = new List<T>();
            try
            {
                using (var cmd = _conection.CreateCommand())
                {
                    cmd.CommandText = query;
                    cmd.CommandType = CommandType.Text;
                    cmd.CommandTimeout = CommandTimeout;

                    #region Parameters

                    cmd.Parameters.Clear();
                    if (parameters != null && parameters.Count > 0)
                    {
                        foreach (var key in parameters.Keys)
                        {
                            var value = parameters[key];
                            if (value is SqlParameter)
                            {
                                cmd.Parameters.Add(value as SqlParameter);
                            }
                            else
                            {
                                var parameter = cmd.CreateParameter();
                                parameter.ParameterName = key;
                                //Key must be prefixed with @ while passing into this method
                                parameter.Value = (value ?? DBNull.Value);
                                cmd.Parameters.Add(parameter);
                            }
                        }
                    }

                    #endregion

                    await OpenAsync();

                    using (var reader = await cmd.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            result.Add(mapping(reader));
                        }
                    }
                }
            }
            finally
            {
                Close();
            }
            return result;
        }

        #endregion

        #region IDisposable Members

        ~Database()
        {
            Dispose(false);
        }

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        protected virtual void Dispose(bool disposing)
        {
            if (_disposed) return;
            if (disposing)
            {
                if (_conection != null)
                {
                    _conection.Dispose();
                    _conection = null;
                }
            }
            _disposed = true;
        }

        #endregion
    }
}
