using Enza.PtoV.BusinessAccess.Interfaces;
using Enza.PtoV.Common.Extensions;
using Enza.PtoV.Entities.Args;
using Enza.PtoV.Entities.Results;
using Enza.PtoV.Services.Abstract;
using Enza.PtoV.Web.Services.Models;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.Http;

namespace Enza.PtoV.Web.Services.Controllers
{
    [Authorize(Roles = AppRoles.PTOV_USER)]
    [RoutePrefix("api/v1/phenome")]
    public class PhenomeController : BaseApiController
    {
        private readonly IPhenomeServices phenomeService;
        private readonly string BASE_SVC_URL = ConfigurationManager.AppSettings["BasePhenomeServiceUrl"];
        public PhenomeController(IPhenomeServices phenomeService)
        {
            this.phenomeService = phenomeService;
        }

        [HttpPost]
        [Route("login")]
        public async Task<IHttpActionResult> Login(string userName, string password)
        {
            using (var client = new RestClient(BASE_SVC_URL))
            {
                var response = await client.PostAsync("/login_do", values =>
                {
                    values.Add("username", userName);
                    values.Add("password", password);
                });
                return ResponseMessage(response);
            }
        }

        [HttpPost]
        [Route("ssologin")]
        public async Task<IHttpActionResult> SSOLogin(string token)
        {
            using (var client = new RestClient(BASE_SVC_URL))
            {
                var response = await client.PostAsync("/single_sign_on", values =>
                {
                    values.Add("token", token);
                });
                await response.EnsureSuccessStatusCodeAsync();
                var result = await response.Content.DeserializeAsync<PhenomeSSOResult>();
                if (result.Status == "1")
                {
                    //get UUID from response to process futher(setting cookies in phenome)
                    if (string.IsNullOrWhiteSpace(result.UUID))
                    {
                        return InvalidRequest("UUID for the request is not available.");
                    }
                    //request for authentication cookies
                    //https://onprem.unity.phenome-networks.com/login_do?username=ronensh@phenome-test.co.il&password=FADC3116-E1B0-11E8-BC0B-B8211DFEC1A6
                    response = await client.GetAsync($"/login_do?username={HttpUtility.UrlEncode(result.UserName) }&password={ result.UUID }");
                    await response.EnsureSuccessStatusCodeAsync();
                }
                return ResponseMessage(response);
            }
        }

        [HttpGet]
        [Route("getResearchGroups")]
        public async Task<IHttpActionResult> GetResearchGroups()
        {
            using (var client = new RestClient(BASE_SVC_URL))
            {
                client.SetRequestCookies(Request);
                var response = await client.GetAsync("/api/v1/tree/baseobjectnavigator/get/m?path=m&selected=m");

                return ResponseMessage(response);
            }
        }

        [HttpGet]
        [Route("getFolders")]
        public async Task<IHttpActionResult> GetFolders(int id)
        {
            using (var client = new RestClient(BASE_SVC_URL))
            {
                client.SetRequestCookies(Request);
                var response = await client.GetAsync($"/api/v1/tree/baseobjectnavigator/get_node/m?id={id}");

                return ResponseMessage(response);
            }
        }

        [HttpPost]
        [Route("import")]
        public async Task<IHttpActionResult> Import([FromBody]GermplasmsImportRequestArgs args)
        {
            if (args.CropID <= 0)
            {
                var res = new GermplasmsImportResult();
                res.Errors.Add("Crop not found.");
                return Ok(res);
            }
            var data = await phenomeService.GetPhenomeDataAsync(Request, args);
            var result = new
            {
                data.Success,
                data.Errors,
                data.Total,
                data.FileName,
                data.Data
            };
            return Ok(result);
        }

        [HttpPost]
        [Route("sendToVarmas")]
        public async Task<IHttpActionResult> SendToVarmas([FromBody] List<SendToVarmasRequestArgs> varieties)
        {
            if (varieties == null || !varieties.Any())
            {
                return InvalidRequest("Please select at least a row to proceed.");
            }
            var resp = await phenomeService.SendToVarmasAsync(varieties);
            return Ok(resp);
        }

        [HttpPost]
        [Route("accessToken")]
        public async Task<IHttpActionResult> AccessToken()
        {
            var jwtToken = Request.Headers.Authorization;
            var token = await phenomeService.GetAccessTokenAsync(jwtToken.Parameter);
            return Ok(new
            {
                accessToken = token
            });
        }
    }
}