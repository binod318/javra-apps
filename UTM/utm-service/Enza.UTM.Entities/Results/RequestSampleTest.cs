using System;
using System.Collections.Generic;

namespace Enza.UTM.Entities.Results
{
    public class RequestSampleTest
    {
        public string Crop { get; set; }
        public string BrStation { get; set; }
        public string Country { get; set; }
        public string Level { get; set; }
        public string TestType { get; set; }
        public int RequestID { get; set; }
        public string RequestingSystem { get; set; }
        public int DeterminationID { get; set; }
        public int MaterialID { get; set; }
        public string Name { get; set; }
        public string ExpectedResultDate { get; set; }
        public string MaterialStatus { get; set; }
        public string Site { get; set; }

        public string PlantID { get; set; }
        public string PlantName { get; set; }
        public int GID { get; set; }
        public string Enumber { get; set; }
        public string MasterNr { get; set; }
        public string LotNumber { get; set; }
    }

    public class MaterialDT
    {
        public int MaterialID { get; set; }
        public string Name { get; set; }
        public string ExpectedResultDate { get; set; }
        public string MaterialStatus { get; set; }
    }

    public class DeterminationDT
    {
        public int DeterminationID { get; set; }
        public List<MaterialDT> Materials { get; set; }
    }

    public class RequestSampleTestRequest
    {
        public string Crop { get; set; }
        public string BrStation { get; set; }
        public string Country { get; set; }
        public string Level { get; set; }
        public string TestType { get; set; }
        public int RequestID { get; set; }
        public string Site { get; set; }
        public string RequestingUser { get; set; }
        public string RequestingName { get; set; }
        public string RequestingSystem { get; set; }
        public List<DeterminationDT> Determinations { get; set; }
        public List<Material> MaterialInfo { get; set; }
    }

    public class Material
    {
        public int MaterialID { get; set; }
        public List<KeyValuePair<string, string>> Info { get; set; }
    }

    public class RequestSampleTestResult
    {
        public string Success { get; set; }
        public string ErrorMsg { get; set; }
    }
}
