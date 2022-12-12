using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Enza.PtoV.Entities.Args.Abstract;

namespace Enza.PtoV.Entities
{
    public class GermPlasmParentInfo
    {
        public GermPlasmParentInfo()
        {
            FemalePar = new ParentGID();
            MalePar = new ParentGID();
            MaintainerPar = new ParentGID();
        }
        /// <summary>
        /// Base GID from which we starts to fetch parents
        /// </summary>
        public int BaseGID { get; set; }
        public int GID { get; set; }
        /// <summary>
        /// Generation of GID
        /// </summary>
        public string Gen { get; set; }
        /// <summary>
        /// Female parent of GID
        /// </summary>
        //public int FemaleParGID { get; set; }
        public ParentGID FemalePar { get; set; }
        public ParentGID MalePar { get; set; }
        public ParentGID MaintainerPar { get; set; }
        public string  TransferType { get; set; }
    }
    public class ParentGID
    {
        public string TransferType { get; set; }
        public int GID { get; set; }
        public string Gen { get; set; }
        public int Level { get; set; }
        public bool FetchNextParent { get; set; }

    }
}
