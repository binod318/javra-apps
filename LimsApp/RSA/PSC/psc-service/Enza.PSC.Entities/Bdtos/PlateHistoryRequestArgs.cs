namespace Enza.PSC.Entities.Bdtos
{
    public class PlateHistoryRequestArgs
    {
        public string PlateBarcode1 { get; set; }
        public string PlateBarcode2 { get; set; }
        public bool? IsMached { get; set; }
    }
}
