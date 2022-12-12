namespace Enza.PtoV.Entities.Results
{
    public class GermplasmResult
    {
        public string Message { get; set; }
        public string Status { get; set; }
        public bool Success
        {
            get
            {
                return string.CompareOrdinal(Status, "1") == 0;
            }
        }
    }
}
