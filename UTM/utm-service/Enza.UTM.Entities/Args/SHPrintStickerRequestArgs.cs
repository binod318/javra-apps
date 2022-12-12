using Enza.UTM.Common.Exceptions;
using Enza.UTM.Entities.Args.Abstract;
using System.Collections.Generic;

namespace Enza.UTM.Entities.Args
{
    public class SHPrintStickerRequestArgs
    {
        public SHPrintStickerRequestArgs()
        {
            MaterialDetermiantion = new List<MaterialDetermination>();
        }
        public int TestID { get; set; }
        public List<MaterialDetermination> MaterialDetermiantion { get; set; }
    }
    
}
