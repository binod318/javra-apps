﻿namespace Enza.UTM.Entities
{
    public class EmailConfig
    {
        public int? ConfigID { get; set; }
        public string ConfigGroup { get; set; }
        public string CropCode { get; set; }
        public string BrStationCode { get; set; }
        public string Recipients { get; set; }
        //public int? SiteID { get; set; }
        //public string SiteName { get; set; }
    }
}
