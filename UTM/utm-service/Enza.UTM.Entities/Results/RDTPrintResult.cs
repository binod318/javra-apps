using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection.Emit;
using System.Text;
using System.Threading.Tasks;

namespace Enza.UTM.Entities.Results
{
    public class RDTPrintResult
    {
        public string User { get; set; }
        public string LabelType { get; set; }
        public int Copies { get; set; }
        public RDTPrintResult()
        {
            Labels = new List<Label>();
        }
        public List<Label>  Labels { get; set; }


    }
    public class Label
    {
        public Dictionary<string,string> LabelData { get; set; }
    }
}
