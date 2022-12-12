using System;
using System.ComponentModel;
using System.Data;

namespace Enza.PSC.DataAccess.Data.Extensions
{
    public static class DbExtensions
    {
        public static T Get<T>(this IDataReader reader, int index)
        {
            var isNull = reader.IsDBNull(index);
            return isNull ? default(T) : (T) reader.GetValue(index).ChangeType(typeof (T));
        }

        public static object ChangeType(this object value, Type conversionType)
        {
            if (conversionType == null) throw new ArgumentNullException(nameof(conversionType));
            if (conversionType.IsGenericType && conversionType.GetGenericTypeDefinition() == typeof(Nullable<>))
            {
                if (value == null) return null;

                var nullableConverter = new NullableConverter(conversionType);
                conversionType = nullableConverter.UnderlyingType;
            }
            return Convert.ChangeType(value, conversionType);
        }
    }
}
