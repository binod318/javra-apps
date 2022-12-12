using System.Collections.Generic;

namespace Enza.UTM.Entities.Results
{
    public class InventoryLotColumnsResponse : PhenomeResponse
    {
        public InventoryLotColumnsResponse()
        {
            All_Columns = new List<Column>();
        }
        public List<Column> All_Columns { get; set; }
    }
}
