using Enza.PtoV.Entities.Args.Abstract;
using System.Collections.Generic;

namespace Enza.PtoV.Entities.Results
{
    public class GetSettingsResponse : PhenomeResponse
    {
        public GetSettingsResponse()
        {
            rg_columns_vid_names = new List<Variables>();
        }
        public List<Variables> rg_columns_vid_names { get; set; }
     
        public Settings Settings { get; set; }

    }
    public class Variables
    {
        public string Value { get; set; }
        public string Name { get; set; }
    }
    public class Settings
    {
        public Settings()
        {
            LockColumnsFromEditing = new LockColumnFromEditing();
        }
        public LockColumnFromEditing LockColumnsFromEditing { get; set; }
    }
    public class LockColumnFromEditing
    {
        public LockColumnFromEditing()
        {
            variable_ids = new List<string>();

        }
        public string lock_for_all { get; set; }
        public string LockColumnsFromEditing { get; set; } //LockColumnsFromEditing //LockColumnsFromEditing
        public List<string> variable_ids { get; set; }
    }
}