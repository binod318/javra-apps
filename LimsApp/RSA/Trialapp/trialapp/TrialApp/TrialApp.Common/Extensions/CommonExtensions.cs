using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.Serialization.Json;
//using Windows.UI.Xaml;
//using Windows.UI.Xaml.Media;

namespace TrialApp.Common.Extensions
{
    public static class CommonExtensions
    {
        public static string ToNullOrValue(this object o)
        {
            return o == null ? null : o.ToString();
        }

        public static string ToNullOrValue(this string o)
        {
            return string.IsNullOrWhiteSpace(o) ? null : o;
        }

        public static string ToText(this object o)
        {
            return o == null ? string.Empty : o.ToString();
        }
        public static int ToInt32(this object o)
        {
            if (o == null || o == DBNull.Value)
                return default(int);
            return Convert.ToInt32(o);
        }

        public static long ToInt64(this object o)
        {
            if (o == null || o == DBNull.Value)
                return default(int);
            return Convert.ToInt64(o);
        }


        public static string Serialize<T>(this List<T>instance)
        {
            using (var _Stream = new MemoryStream())
            {
                var _Serializer = new DataContractJsonSerializer(instance.GetType());
                _Serializer.WriteObject(_Stream, instance);
                _Stream.Position = 0;
                using (var _Reader = new StreamReader(_Stream))
                { return _Reader.ReadToEnd(); }
            }
        }

        //public static IEnumerable<T> FindVisualChildren<T>(DependencyObject depObj) where T : DependencyObject
        //{
        //    if (depObj != null)
        //    {
        //        for (var i = 0; i < VisualTreeHelper.GetChildrenCount(depObj); i++)
        //        {
        //            var child = VisualTreeHelper.GetChild(depObj, i);
        //            if (child != null && child is T)
        //            {
        //                yield return (T) child;
        //            }

        //            foreach (var childOfChild in FindVisualChildren<T>(child))
        //            {
        //                yield return childOfChild;
        //            }
        //        }
        //    }
        //}

        #region Exception

        public static Exception GetException(this Exception ex)
        {
            var innerEx = ex;
            while (innerEx.InnerException != null)
            {
                innerEx = innerEx.InnerException;
            }
            return innerEx;
        }

        #endregion
    }
}