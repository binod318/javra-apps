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
    public class EnzaCorsPolicyProvider : ICorsPolicyProvider
    {
        public async Task<CorsPolicy> GetCorsPolicyAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            var context = request.GetCorsRequestContext();
            var origin = context.Origin;
            if (await IsValidOriginAsync(origin))
            {
                // Grant CORS request
                var policy = new CorsPolicy
                {
                    AllowAnyHeader = true,
                    AllowAnyMethod = true,
                    SupportsCredentials = true
                };
                policy.Origins.Add(origin);
                return policy;
            }
            // Reject CORS request
            return null;
        }

        private async Task<bool> IsValidOriginAsync(string origin)
        {
            if (string.IsNullOrWhiteSpace(origin))
            {
                return await Task.FromResult(true);
            }

            var origins = new List<string>();
            var file = @"C:\BAS\CrossOrigins.json";
            if (File.Exists(file))
            {
                var json = File.ReadAllText(file);
                origins = JsonConvert.DeserializeObject<List<string>>(json);
            }
            if (origins.Count > 0)
            {
                var allowed = origins.Contains(origin);
                return await Task.FromResult(allowed);
            }
            return await Task.FromResult(true);
        }
    }
}
