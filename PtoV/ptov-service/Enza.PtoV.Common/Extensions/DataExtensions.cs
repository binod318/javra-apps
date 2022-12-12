using System;
using System.Data;
using System.Data.Common;

namespace Enza.PtoV.Common.Extensions
{
    public static class DataExtensions
    {
        public static T Get<T>(this DbDataReader reader, int column)
        {
            if (reader.IsDBNull(column)) return default(T);
            return (T)reader.GetValue(column);
        }

        public static T Get<T>(this DataRow dr, string column)
        {
            if (dr.IsNull(column)) return default(T);
            return (T)Convert.ChangeType(dr[column],typeof(T));
        }

    }
}
