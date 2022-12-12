using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Net.Http;
using System.Threading.Tasks;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Linq;

namespace TrialApp.Services
{
    public class SimpleGraphService
    {
        public async Task<string> GetNameAsync()
        {
            using (var client = new HttpClient())
            {
                var token = WebserviceTasks.AdAccessToken;
               
                if (!string.IsNullOrEmpty(token))
                {
                    var message = new HttpRequestMessage(HttpMethod.Get, "https://graph.microsoft.com/v1.0/me");
                    message.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);

                    var response = await client.SendAsync(message);

                    if (response.IsSuccessStatusCode)
                    {
                        var json = await response.Content.ReadAsStringAsync();
                        var data = (JObject)JsonConvert.DeserializeObject(json);

                        if (data.ContainsKey("displayName"))
                        {
                            return data["displayName"].Value<string>();
                            //return name + " " + data["familyName"]?.Value<string>();

                        }
                        else
                            return "Mr. No Name";
                        //currentUser = JsonConvert.DeserializeObject<User>(json);
                    }
                }
                else
                {
                    return "Token Invalid";
                }
            }

            return "Name unknown";
        }

        public List<string> GetAllRolesAsync(string token)
        {
            JwtSecurityTokenHandler tokenHandler = new JwtSecurityTokenHandler();
            var securityToken = tokenHandler.ReadToken(token) as JwtSecurityToken;
            //var ff = securityToken.Claims.FirstOrDefault(o => o.Type == "name")?.Value; //get fullname

            var roles = securityToken.Claims.Where(o => o.Type == "roles").Select(p => p.Value).ToList();
            
            return roles;
        }

        public string GetFullName(string token)
        {
            JwtSecurityTokenHandler tokenHandler = new JwtSecurityTokenHandler();
            var securityToken = tokenHandler.ReadToken(token) as JwtSecurityToken;
            var fullname = securityToken.Claims.FirstOrDefault(o => o.Type == "name")?.Value; //get fullname

            return fullname;
        }
    }
}
