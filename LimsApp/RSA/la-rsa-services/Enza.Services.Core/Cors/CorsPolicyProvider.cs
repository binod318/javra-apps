using System.Collections.Generic;
using System.IO;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Cors;
using System.Web.Http.Cors;
using Newtonsoft.Json;

namespace Enza.Services.Core.Cors
{
    public class CorsPolicyProvider: ICorsPolicyProvider
    {
        public async Task<CorsPolicy> GetCorsPolicyAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            var policy = new EnableCorsAttribute("*", "*", "*");
            //Get origis from json file
            var origins = new List<string>();
            var file = @"C:\BAS\CrossOrigins.json";
            if (File.Exists(file))
            {
                var json = File.ReadAllText(file);
                origins = JsonConvert.DeserializeObject<List<string>>(json);
            }
            if (origins.Count > 0)
            {
                policy = new EnableCorsAttribute(string.Join(",", origins.ToArray()), "*", "*");
            }
            policy.SupportsCredentials = true;
            return await policy.GetCorsPolicyAsync(request, cancellationToken);
        }
    }
}
