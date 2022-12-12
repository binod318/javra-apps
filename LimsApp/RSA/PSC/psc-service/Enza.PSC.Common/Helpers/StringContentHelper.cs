using Newtonsoft.Json;
using System.Net.Http;
using System.Text;

namespace Enza.PSC.Common.Helpers
{
    public class StringContentHelper
    {
        public static StringContent CreateJsonContent(object obj)
        {
            var json = JsonConvert.SerializeObject(obj);
            var content = new StringContent(json, Encoding.UTF8, "application/json");
            return content;
        }
        public static dynamic CreateJsonContent(string objString)
        {
            return JsonConvert.DeserializeObject<dynamic>(objString);
        }
    }
}
