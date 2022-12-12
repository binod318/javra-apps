using System;

namespace Enza.PAC.Entities.Results
{
    public class DeterminationAssignmentResult
    {
        public int DetAssignmentID { get; set; }
        public string MethodCode { get; set; }
        public string ABSCropCode { get; set; }
        public int SampleNr { get; set; }
        public string UtmostInlayDate { get; set; }
        public string ExpectedReadyDate { get; set; }
        public short? PriorityCode { get; set; }
        public int? BatchNr { get; set; }
        public bool RepeatIndicator { get; set; }
        public int? VarietyNr { get; set; }
        public string Process { get; set; }
        public short? ProductStatus { get; set; }
        
        public string ReceiveDate { get; set; }
        public bool ReciprocalProd { get; set; }
        public string Remarks { get; set; }

        public bool BioIndicator { get; set; }
        public string LogicalClassificationCode { get; set; }
        public string LocationCode { get; set; }
    }
}
