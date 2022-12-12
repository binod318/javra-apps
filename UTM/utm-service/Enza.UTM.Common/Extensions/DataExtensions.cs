using System.Collections.Generic;
using System.Data.Common;
using System.Linq;

namespace Enza.UTM.Common.Extensions
{
    public static class DataExtensions
    {
        public static T Get<T>(this DbDataReader reader, int column)
        {
            if (reader.IsDBNull(column)) return default(T);
            return (T)reader.GetValue(column);
        }

        public static IEnumerable<IEnumerable<T>> BatchBy<T>(this IEnumerable<T> source, int batchSize)
        {
            var total = 0;
            var count = source.Count();
            while (total < count)
            {
                yield return source.Skip(total).Take(batchSize);
                total += batchSize;
            }
        }
    }
}
