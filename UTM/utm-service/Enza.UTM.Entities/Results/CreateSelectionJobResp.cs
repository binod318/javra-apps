using System.Collections.Generic;

namespace Enza.UTM.Entities.Results
{
    public class CreateSelectionJobResp
    {
        public string Status { get; set; }
        public int IsJob { get; set; }
        public List<string> Rows_ids { get; set; }
        public string Message { get; set; }
        public string job_id { get; set; }
    }
    
}
