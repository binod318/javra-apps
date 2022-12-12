using Enza.PtoV.Common.Extensions;
using Enza.Shared.Authentication;
using System;
using System.Linq;
using System.Net.Http;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using System.Web;

namespace Enza.PtoV.Web.Services.Handlers
{
    public class EnzaJWTHandler : DelegatingHandler
    {
        protected async override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            try
            {
                if (request.Headers.Contains(ClaimConstants.AUTHHEADERNAME))
                {
                    var authHeaderValue = request.Headers.GetValues(ClaimConstants.AUTHHEADERNAME).First();
                    ICreateAndReadAuthTokens authService = new AuthenticationService();
                    var claimsPrincipal = authService.ReadAndVerifyToken(authHeaderValue);
                    //convert all roles to lowercase to support case insensitive authorization check in attributes
                    var claimsIdentity = (ClaimsIdentity)claimsPrincipal.Identity;
                    var roleClaims = claimsPrincipal.Claims.Where(o => o.Type == ClaimTypes.Role).ToList();
                    foreach (var roleClaim in roleClaims)
                    {
                        claimsIdentity.RemoveClaim(roleClaim);
                        claimsIdentity.AddClaim(new Claim(roleClaim.Type, roleClaim.Value.ToLower()));
                    }
                    Thread.CurrentPrincipal = claimsPrincipal;
                    if (HttpContext.Current != null)
                    {
                        HttpContext.Current.User = claimsPrincipal;
                    }
                }
            }
            catch (Exception ex)
            {
                this.LogError(ex);
            }
            return await base.SendAsync(request, cancellationToken);
        }
    }
}