using Microsoft.IdentityModel.Tokens;
using System.Configuration;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace Enza.PAC.Common.Security
{
    public class JwtTokenValidator
    {
        public const string AUTH_HEADER_NAME = "enzauth";
        private readonly JwtSecurityTokenHandler _handler;
        private readonly SymmetricSecurityKey _signingKey;
        public JwtTokenValidator()
        {
            _handler = new JwtSecurityTokenHandler();
            var plainTextSecurityKey = ConfigurationManager.AppSettings["signingsecret"];
            _signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(plainTextSecurityKey));
        }

        public ClaimsPrincipal Verify(string token)
        {
            var tokenValidationParameters = new TokenValidationParameters()
            {
                ValidAudiences = new string[]
                {
                    $"http://{AUTH_HEADER_NAME}"
                },
                ValidIssuers = new string[]
                {
                    $"http://{AUTH_HEADER_NAME}"
                },
                IssuerSigningKey = _signingKey,
                ValidateLifetime = true
            };
            return _handler.ValidateToken(token, tokenValidationParameters, out _);
        }
    }
}
