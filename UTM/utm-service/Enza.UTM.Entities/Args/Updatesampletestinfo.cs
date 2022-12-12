using System;
using System.Collections.Generic;

namespace Enza.UTM.Entities.Args
{
    public class Updatesampletestinfo
    {
        public Updatesampletestinfo()
        {
            InterfaceRefIds = new List<InterfaceRef>();
        }
        public int RequestID { get; set; }
        public string Action { get; set; }
        public string RequestingUser { get; set; }
        public string RequestingSystem { get; set; }
        public List<InterfaceRef> InterfaceRefIds { get; set; }
    }

    public class InterfaceRef
    {
        public int InterfaceRefId { get; set; }
        public List<Dictionary<string, string>> Info { get; set; }
    }

    public class UpdatedTestInfo
    {
        public int TestID { get; set; }
        public int MaterialID { get; set; }
        public int DeterminationID { get; set; }
        public int InterfaceRefID { get; set; }
        public int? MaxSelect { get; set; }
        public int StatusCode { get; set; }
    }
}
