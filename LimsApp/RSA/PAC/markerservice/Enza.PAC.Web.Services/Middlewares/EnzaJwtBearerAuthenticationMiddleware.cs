using Enza.PAC.Common.Security;
using Microsoft.Owin;
using Microsoft.Owin.Extensions;
using Microsoft.Owin.Security;
using Microsoft.Owin.Security.Infrastructure;
using Microsoft.Owin.Security.Jwt;
using Owin;
using System;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;

namespace Enza.PAC.Web.Services.Middlewares
{
    //reference: https://github.com/michaelnoonan/Auth0-Owin-JwtBearerAuthentication/tree/master/Auth0.Owin.Jwt
    public class EnzaJwtAuthenticationHandler : AuthenticationHandler<JwtBearerAuthenticationOptions>
    {
        protected async override Task<AuthenticationTicket> AuthenticateCoreAsync()
        {
            if (TryRetrieveToken(Request, out string token))
            {
                try
                {
                    var validator = new JwtTokenValidator();
                    var principal = validator.Verify(token);
                    var identity = principal.Identity as ClaimsIdentity;
                    //convert all roles to lowercase to support case insensitive authorization check in attributes
                    var roleClaims = identity.Claims.Where(o => o.Type == ClaimTypes.Role).ToList();
                    foreach (var roleClaim in roleClaims)
                    {
                        identity.RemoveClaim(roleClaim);
                        identity.AddClaim(new Claim(roleClaim.Type, roleClaim.Value.ToLower()));
                    }
                    return await Task.FromResult(new AuthenticationTicket(identity, new AuthenticationProperties()));
                }
                catch (Exception)
                {
                    return await Task.FromResult<AuthenticationTicket>(null);
                }
            }
            return await Task.FromResult<AuthenticationTicket>(null);
        }

        private static bool TryRetrieveToken(IOwinRequest request, out string token)
        {
            token = null;
            if (request.Headers.TryGetValue(JwtTokenValidator.AUTH_HEADER_NAME, out string[] headers))
            {
                token = headers.FirstOrDefault();
                return true;
            }
            return false;
        }
    }

    public class EnzaJwtBearerAuthenticationMiddleware : AuthenticationMiddleware<JwtBearerAuthenticationOptions>
    {
        public EnzaJwtBearerAuthenticationMiddleware(OwinMiddleware next)
            : base(next, new JwtBearerAuthenticationOptions())
        {
        }
        public EnzaJwtBearerAuthenticationMiddleware(OwinMiddleware next, JwtBearerAuthenticationOptions options)
            : base(next, options)
        {
        }
        protected override AuthenticationHandler<JwtBearerAuthenticationOptions> CreateHandler()
        {
            return new EnzaJwtAuthenticationHandler();
        }
    }

    public static class EnzaJwtBearerAuthenticationExtensions
    {
        public static IAppBuilder UseEnzaJwtBearerAuthentication(this IAppBuilder app, JwtBearerAuthenticationOptions options)
        {
            if (app == null)
            {
                throw new ArgumentNullException("app");
            }
            if (options == null)
            {
                throw new ArgumentNullException("options");
            }
            app.Use(typeof(EnzaJwtBearerAuthenticationMiddleware), options);
            app.UseStageMarker(PipelineStage.Authenticate);
            return app;
        }
        public static IAppBuilder UseEnzaJwtBearerAuthentication(this IAppBuilder app)
        {
            if (app == null)
            {
                throw new ArgumentNullException("app");
            }
            app.Use(typeof(EnzaJwtBearerAuthenticationMiddleware));
            app.UseStageMarker(PipelineStage.Authenticate);
            return app;
        }
    }
}