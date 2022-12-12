using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;

namespace Enza.PtoV.Common.Extensions
{
    public static class JsonExtensions
    {
        public static async Task<T> DeserializeAsync<T>(this HttpContent httpContent)
        {
            var stream = await httpContent.ReadAsStreamAsync();
            var serializer = new JsonSerializer();
            using (var sr = new StreamReader(stream))
            {
                using (var jsonTextReader = new JsonTextReader(sr))
                {
                    return serializer.Deserialize<T>(jsonTextReader);
                }
            }
        }

        public static string Serialize<T>(this T o)
        {
            return JsonConvert.SerializeObject(o);
        }

        public static string ToCamelCase(this object o)
        {
            var settings = new JsonSerializerSettings
            {
                ContractResolver = new CamelCasePropertyNamesContractResolver()
            };
            return JsonConvert.SerializeObject(o, settings);
        }

        public static string ToCamelCaseColumnName(this string value)
        {
            var dict = new Dictionary<string, string>
            {
                {value, value}
            }.ToCamelCase();
            var d2 = JsonConvert.DeserializeObject<Dictionary<string, string>>(dict);
            return d2.Keys.FirstOrDefault();
        }
    }
}
