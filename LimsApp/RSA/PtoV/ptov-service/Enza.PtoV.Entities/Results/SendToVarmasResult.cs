using System.Collections.Generic;

namespace Enza.PtoV.Entities.Results
{
    public class SendToVarmasResult
    {
        public SendToVarmasResult()
        {
            Results = new List<VarmasResponse>();
            Errors = new List<string>();
        }
        public List<VarmasResponse> Results { get; set; }
        public List<string> Errors { get; set; }
        public Warning Warning { get; set; }
    }


    public class VarmasResponse
    {
        public int VarietyID { get; set; }
        public int VarietyNr { get; set; }
        public string ENumber { get; set; }
        public int StatusCode { get; set; }
        public string StatusName { get; set; }
        public int GID { get; set; }
    }

    public class Warning
    {
        public string Message { get; set; }
        public int GID { get; set; }
        public List<int> SkipGID { get; set; }
    }

    public class VarmasResponseError
    {
        public VarmasResponseError(int gid, string message)
        {
            GID = gid;
            Message = message;
        }
        public int GID { get; set; }
        public string Message { get; set; }
    }

}
