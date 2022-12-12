using System;
using System.Collections.Generic;
using System.Text;

namespace TrialApp.Entities.Transaction
{
    public class TrialEntryApp
    {
        public string EZID { get; set; }
        public string CropCode { get; set; }
        public string FieldNumber { get; set; }
        public string EZIDVariety { get; set; }
        public int? VarietyNr { get; set; }
        public string CropCodeVariety { get; set; }
        public string VarietyName { get; set; }
        public string Enumber { get; set; }
        public string CropSegmentCode { get; set; }
        public string ProductSegmentCode { get; set; }
        public string ProductStatus { get; set; }
        public string ResistanceHR { get; set; }
        public string ResistanceIR { get; set; }
        public string ResistanceT { get; set; }
        public string MasterNr { get; set; }
        public bool Modified { get; set; }
        public bool NewRecord { get; set; }
        public bool IsHidden { get; set; }
    }
}
