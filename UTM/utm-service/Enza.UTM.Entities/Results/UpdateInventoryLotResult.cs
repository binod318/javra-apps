using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Enza.UTM.Entities.Results
{
    public class UpdateInventoryLotResult
    {
        public UpdateInventoryLotResult()
        {
            ErrorIDs = new List<int>();
            MissingColumns = new List<string>();
        }
        public List<int> ErrorIDs { get; set; }
        public List<string> MissingColumns { get; set; }
        public string ErrorMessage { get; set; }

    }
}
