using System;
using System.Collections.Generic;
using System.Text;

namespace TrialApp.Entities.Transaction
{
    public class TrialLookUp
    {
        public int EZID { get; set; }
        public string CropCode { get; set; }
        public string TrialName { get; set; }
        public int TrialTypeID { get; set; }
        public string TrialTypeName { get; set; }
        public string CountryCode { get; set; }
        public int TrialRegionID { get; set; }
        public string CropSegmentCode { get; set; }
        public int DefaultTraitSetID { get; set; }
        public int StatusCode { get; set; }
        public int Order { get; set; }
        public string SelectedRecordID { get; set; }
        public string Latitude { get; set; }
        public string Longitude { get; set; }
        public string CropCountry { get; set; }
    }

    public class Trial
    {
        public int EZID { get; set; }
        public string CropCode { get; set; }
        public string TrialName { get; set; }
        public int TrialTypeID { get; set; }
        public string CountryCode { get; set; }
        public int TrialRegionID { get; set; }
        public string CropSegmentCode { get; set; }
        public int DefaultTraitSetID { get; set; }
        public int StatusCode { get; set; }
        public int Order { get; set; }
        public string SelectedRecordID { get; set; }
        public string Latitude { get; set; }
        public string Longitude { get; set; }
    }
}
