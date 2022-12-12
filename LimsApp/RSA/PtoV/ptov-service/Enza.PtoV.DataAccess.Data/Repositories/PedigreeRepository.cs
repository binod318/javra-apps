using System.Threading.Tasks;
using Enza.PtoV.DataAccess.Data.Interfaces;
using Enza.PtoV.Entities.Args;
using Enza.PtoV.DataAccess.Abstract;
using Enza.PtoV.DataAccess.Interfaces;
using Enza.PtoV.Entities.Results;
using Newtonsoft.Json;
using System;
using System.IO;
using System.Configuration;
using Enza.PtoV.Common.Extensions;
using Enza.PtoV.Services.Abstract;
using System.Web;
using System.Collections.Generic;
using System.Linq;

namespace Enza.PtoV.DataAccess.Data.Repositories
{
    public class PedigreeRepository : Repository<object>, IPedigreeRepository
    {
        private readonly IGermplasmRepository _germplasmRepository;
        private readonly string _baseServiceUrl = ConfigurationManager.AppSettings["BasePhenomeServiceUrl"];
        public PedigreeRepository(IDatabase dbContext, IGermplasmRepository germplasmRepository) : base(dbContext)
        {
            _germplasmRepository = germplasmRepository;
        }

        public async Task<string> GetPedigreeAsync(GetPedigreeRequestArgs requestArgs)
        {
            if (requestArgs.Request == null)
                throw new Exception("Please provide Request object to process to phenome.");

            var columns = (await _germplasmRepository.GetPhenomeColumnsAsync(requestArgs.BaseGID)).ToList();
            
            
            //var backwardGen = ConfigurationManager.AppSettings["Pedigree:BackwardGen"];
           // var forwardGen = ConfigurationManager.AppSettings["Pedigree:FowardGen"];
            using (var client = new RestClient(_baseServiceUrl))
            {
                client.SetRequestCookies(requestArgs.Request);
                var url = "/api/v2/germplasm/pedigreetree/getPedigree";
                var response = await client.PostAsync(url, values =>
                {
                    values.Add("GID", requestArgs.GID.ToText());
                    values.Add("BackwardGen", requestArgs.BackwardGen.ToText());
                    values.Add("FowardGen", requestArgs.ForwardGen.ToText());
                    values.Add("Columns", columns.Serialize());
                });
                await response.EnsureSuccessStatusCodeAsync();
                return await response.Content.ReadAsStringAsync();
            }
        }
    }
}
