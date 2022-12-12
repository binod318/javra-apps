using System;
using System.Collections.Generic;

namespace Enza.PtoV.Entities.Args
{
    public class ReplaceLotRequestArgs
    {
        public ReplaceLotRequestArgs()
        {
            Data = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        }
        /// <summary>
        /// "Lot~ids": ["1046966"] => This LOTID is used for replacing LOT of previous variety
        /// </summary>
        public int PhenomeLotID { get; set; }
        /// <summary>
        /// "GID" => This GID is used for replacing LOT of previous variety
        /// </summary>
        public int LotGID { get; set; }
        /// <summary>
        /// GID => Currently selected GID in grid of UI in which Lot should be replaced with new LotID
        /// </summary>
        public int GID { get; set; }
        /// <summary>
        /// Lvl => Level returning from service of LotID.
        /// </summary>
        public int Level { get; set; }

        /// <summary>
        /// List of data of selected LotID
        /// </summary>
        public Dictionary<string, string> Data { get; set; }

    }
}
