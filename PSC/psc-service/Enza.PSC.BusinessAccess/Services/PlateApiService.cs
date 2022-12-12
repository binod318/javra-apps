using System.Configuration;
using System.Threading.Tasks;
using Enza.PSC.BusinessAccess.Interfaces;
using Enza.PSC.BusinessAccess.Proxies;
using Enza.PSC.Common.Helpers;

namespace Enza.PSC.BusinessAccess.Services
{
    public class PlateApiService : IPlateApiService
    {
        private readonly string base_url = ConfigurationManager.AppSettings["PacServiceUrl"];
        public PlateApiService()
        {
        }

        public async Task<dynamic> GetPlateInfoAsync(int plateId, string token)
        {
            //var client = new PacServiceRestClient();
            //var request = new { PlateID = plateId };
            //var apiName = "/v1/ExternalApi/getplatesampleinfo";
            //var json = await client.PostData(apiName, request);
            //return StringContentHelper.CreateJsonContent(json);

            var client = new RestClient(base_url);
            client.AddRequestHeaders(headers => { headers.Add("Authorization", token); });

            var request = new { PlateID = plateId };
            var apiName = "/v1/ExternalApi/getplatesampleinfo";
            var url = base_url + apiName;
            var response = await client.PostAsync(url, request);
            var json = await response.Content.ReadAsStringAsync();
            return StringContentHelper.CreateJsonContent(json);
        }
    }
}
