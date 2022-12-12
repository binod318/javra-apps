namespace Enza.UTM.Entities.Results
{
    public class RunJobResponse : PhenomeResponse
    {
        public string job_id { get; set; }
    }
    public class JobStateResponse : PhenomeResponse
    {
        public string job_state { get; set; }
    }
}