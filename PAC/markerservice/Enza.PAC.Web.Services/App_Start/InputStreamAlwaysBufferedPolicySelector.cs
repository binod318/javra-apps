using System.Net.Http;
using System.Web.Http.WebHost;

namespace Enza.PAC.Web.Services.App_Start
{
    public class InputStreamAlwaysBufferedPolicySelector : WebHostBufferPolicySelector
    {
        public override bool UseBufferedInputStream(object hostContext)
        {
            return true;
        }

        public override bool UseBufferedOutputStream(HttpResponseMessage response)
        {
            return base.UseBufferedOutputStream(response);
        }
    }
}