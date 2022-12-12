using System.Net.Http;
using System.Web.Http.Cors;

namespace Enza.Services.Core.Cors
{
    public class CorsPolicyFactory : ICorsPolicyProviderFactory
    {
        private readonly ICorsPolicyProvider provider;

        public CorsPolicyFactory()
        {
            provider = new CorsPolicyProvider();
        }

        public ICorsPolicyProvider GetCorsPolicyProvider(HttpRequestMessage request)
        {
            return provider;
        }
    }
}
