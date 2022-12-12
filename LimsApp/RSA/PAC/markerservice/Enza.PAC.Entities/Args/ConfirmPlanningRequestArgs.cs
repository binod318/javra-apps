using Enza.PAC.Entities.Args.Abstracts;
using System;
using System.Collections.Generic;

namespace Enza.PAC.Entities.Args
{
    public class ConfirmPlanningRequestArgs : RequestArgs 
    {
        public ConfirmPlanningRequestArgs()
        {
            Details = new List<ConfirmPlanningRequestItem>();
        }
        public int PeriodID { get; set; }       
        public List<ConfirmPlanningRequestItem> Details { get; set; }
    }

    public class ConfirmPlanningRequestItem
    {
        public int DetAssignmentID { get; set; }
        public string MethodCode { get; set; }
        public string ABSCropCode { get; set; }
        public int SampleNr { get; set; }
        public DateTime? PlannedDate { get; set; }
        public DateTime? UtmostInlayDate { get; set; }
        public DateTime? ExpectedReadyDate { get; set; }
        public short? PriorityCode { get; set; }
        public int? BatchNr { get; set; }
        public bool RepeatIndicator { get; set; }
        public int? VarietyNr { get; set; }
        public string Process { get; set; }
        public short? ProductStatus { get; set; }
        public string Remarks { get; set; }

        public DateTime? ReceiveDate { get; set; }
        public bool ReciprocalProd { get; set; }
        public bool BioIndicator { get; set; }
        public string LogicalClassificationCode { get; set; }
        public string LocationCode { get; set; }
        public bool IsLabPriority { get; set; }

        public string Action { get; set; }
    }
}
