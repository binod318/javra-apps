using Newtonsoft.Json;
using System.Collections.Generic;

namespace Enza.PtoV.UITesting.Models
{
    public class AppSettings
    {
        public AppSettings()
        {
            FolderList = new List<string>();
        }
        public string ApplicationURL { get; set; }

        [JsonProperty("Import:UserName")]
        public string UserName { get; set; }
        [JsonProperty("Import:Password")]
        public string Password { get; set; }
        [JsonProperty("Import:FolderList")]
        public List<string> FolderList { get; set; }
    }
}
