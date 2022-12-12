using System.Collections.Generic;

namespace Enza.PtoV.Entities.VtoP
{
    public class CreateGermplasmResult
    {
        /// <summary>
        /// GID in phenome
        /// </summary>
        public string row_id { get; set; }
        public string status { get; set; }
    }

    public class CreateInventoryResult
    {
        public CreateInventoryResult()
        {
            Data = new List<Dictionary<string, List<string>>>();
        }
        //public List<List<string>> Data { get; set; }
        public List<Dictionary<string,List<string>>> Data { get; set; }
        //public Dictionary<string ,List<string>> Data { get; set; }
        public string Status { get; set; }
        public string  Message { get; set; }
    }
}
