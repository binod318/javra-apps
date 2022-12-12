namespace Enza.PtoV.Entities.Results
{
    public class VarmasDataResult
    {
        public string SyncCode { get; set; }
        //public int VarietyNr { get; set; }
        public int GID { get; set; }
        public int LotNumber { get; set; }
        public int VarietyNr { get; set; }
        public int? ScreeningFieldNr { get; set; }
        public string ScreeningFieldValue { get; set; }
        public bool IsValid { get; set; }
        public int CellID { get; set; }
        public int TraitID { get; set; }
        public string TraitName { get; set; }
        public string ColumnLabel { get; set; }
    }
}