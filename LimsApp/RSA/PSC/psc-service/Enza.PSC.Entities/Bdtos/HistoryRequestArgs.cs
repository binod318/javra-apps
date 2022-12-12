namespace Enza.PSC.Entities.Bdtos
{
    public class HistoryRequestArgs
    {
        public string PlateIDBarcode { get; set; }
        public string SampleNrBarcode { get; set; }
        public string User { get; set; }

        public int? PageIndex { get; set; }
        public int? PageSize { get; set; }
    }
}
