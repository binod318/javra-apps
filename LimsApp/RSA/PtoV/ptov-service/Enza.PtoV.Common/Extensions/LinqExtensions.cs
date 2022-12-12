using System;
using System.Collections.Generic;
using System.Linq;

namespace Enza.PtoV.Common.Extensions
{
    public static class LinqExtensions
    {
        public static IEnumerable<TResult> Select2<TSource, TResult>(this IEnumerable<TSource> source,
            Func<TSource, TResult> selector)
        {
            return source.Where(x => x != null).Select(selector);
        }

        public static List<TResult> ToSafeList<TResult>(this IEnumerable<TResult> source)
        {
            return source.Where(x => x != null).ToList();
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
