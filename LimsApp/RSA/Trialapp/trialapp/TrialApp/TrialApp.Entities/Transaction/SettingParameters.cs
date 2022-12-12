using System;
using System.Collections.Generic;
using System.Text;

namespace TrialApp.Entities.Transaction
{
    public class SettingParameters
    {
        public int ID { get; set; }

        public string NewStatusColor { get; set; }
        public string UpdateStatusColor { get; set; }
        public string SyncStatusColor { get; set; }
        public string BackgroundColor { get; set; }
        public string BackgroundImage { get; set; }
        public string Version { get; set; }
        public string Endpoint { get; set; }

        public string SyncCode { get; set; }

        public int RowHeightField { get; set; }

        public string StyleName { get; set; }
        public bool Session { get; set; }

        public string PreDefVal { get; set; }
        public bool Filter { get; set; }
        public string UoM { get; set; }
        public string DefaultLayout { get; set; }
        public int DisplayPropertyID { get; set; }
        public string LoggedInUser { get; set; }
        public bool? IsRegistered { get; set; }
    }

    public static class UnitOfMeasure
    {
        public static string SystemUoM { get; set; }
        public static bool RaiseWarning { get; set; }
    }
}
