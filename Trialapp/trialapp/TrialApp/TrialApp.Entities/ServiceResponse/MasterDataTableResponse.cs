using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Serialization;
using TrialApp.Entities.Master;

namespace TrialApp.Entities.ServiceResponse
{
    public class MasterDataTableResponse
    {
        public class CropRDResponse : CropRD
        {
            [XmlElement(ElementName = "CropGroupID")]
            public string CropGroupIDRaw
            {
                get
                {
                    return CropGroupID.ToString();
                }
                set
                {
                    if (string.IsNullOrEmpty(value))
                        CropGroupID = null;
                    else
                        CropGroupID = Convert.ToInt32(value);
                }
            }

            public string MTStat { get; set; }
        }

        public class FieldSetResponse : FieldSet
        {

        }
        public class TraitResponse : Trait
        {
            [XmlElement(ElementName = "TraitTypeID")]
            public string TraitTypeIDRaw
            {
                get
                {
                    return TraitTypeID.ToString();
                }
                set
                {
                    if (string.IsNullOrEmpty(value))
                        TraitTypeID = null;
                    else
                        TraitTypeID = Convert.ToInt32(value);
                }
            }


            [XmlElement(ElementName = "MinValue")]
            public string MinValueRaw
            {
                get
                {
                    return MinValue.ToString();
                }
                set
                {
                    if (string.IsNullOrEmpty(value))
                        MinValue = null;
                    else
                        MinValue = Convert.ToInt32(value);
                }
            }


            [XmlElement(ElementName = "MaxValue")]
            public string MaxValueRaw
            {
                get
                {
                    return MaxValue.ToString();
                }
                set
                {
                    if (string.IsNullOrEmpty(value))
                        MaxValue = null;
                    else
                        MaxValue = Convert.ToInt32(value);
                }
            }

            [XmlElement(ElementName = "MTSeq")]
            public string MTSeqRaw
            {
                get
                {
                    return MTSeq.ToString();
                }
                set
                {
                    if (string.IsNullOrEmpty(value))
                        MTSeq = null;
                    else
                        MTSeq = Convert.ToInt32(value);
                }
            }


            [XmlElement(ElementName = "UoMCode")]
            public string BaseUnitMetRaw
            {
                get
                {
                    return BaseUnitMet;
                }
                set
                {
                    if (string.IsNullOrEmpty(value))
                        BaseUnitMet = null;
                    else
                        BaseUnitMet = value;
                }
            }

            [XmlElement(ElementName = "UoMCodeImperial")]
            public string BaseUnitImpRaw
            {
                get
                {
                    return BaseUnitImp;
                }
                set
                {
                    if (string.IsNullOrEmpty(value))
                        BaseUnitImp = null;
                    else
                        BaseUnitImp = value;
                }
            }
        }

        public class TraitInFieldSetResponse : TraitInFieldSet
        {

            [XmlElement(ElementName = "FieldSetID")]
            public string FieldSetIDRaw
            {
                get
                {
                    return FieldSetID.ToString();
                }
                set
                {
                    if (string.IsNullOrEmpty(value))
                        FieldSetID = null;
                    else
                        FieldSetID = Convert.ToInt32(value);
                }
            }


            [XmlElement(ElementName = "SortingOrder")]
            public string SortingOrderRaw
            {
                get
                {
                    return SortingOrder.ToString();
                }
                set
                {
                    if (string.IsNullOrEmpty(value))
                        SortingOrder = null;
                    else
                        SortingOrder = Convert.ToInt32(value);
                }
            }

        }

        public class TraitTypeResponse : TraitType
        {
            [XmlElement(ElementName = "TraitTypeID")]
            public string TraitTypeIDRaw
            {
                get
                {
                    return TraitTypeID.ToString();
                }
                set
                {
                    if (string.IsNullOrEmpty(value))
                        TraitTypeID = null;
                    else
                        TraitTypeID = Convert.ToInt32(value);
                }
            }
            
        }

        public class TraitValueResponse : TraitValue
        {
            [XmlElement(ElementName = "TraitValueID")]
            public string TraitValueIDRaw
            {
                get
                {
                    return TraitValueID.ToString();
                }
                set
                {
                    if (string.IsNullOrEmpty(value))
                        TraitValueID = null;
                    else
                        TraitValueID = Convert.ToInt32(value);
                }
            }

            [XmlElement(ElementName = "TraitID")]
            public string TraitIDRaw
            {
                get
                {
                    return TraitID.ToString();
                }
                set
                {
                    if (string.IsNullOrEmpty(value))
                        TraitID = null;
                    else
                        TraitID = Convert.ToInt32(value);
                }
            }

            [XmlElement(ElementName = "SortingOrder")]
            public string SortingOrderRaw
            {
                get
                {
                    return SortingOrder.ToString();
                }
                set
                {
                    if (string.IsNullOrEmpty(value))
                        SortingOrder = null;
                    else
                        SortingOrder = Convert.ToInt32(value);
                }
            }
        }

        public class CropGroupResponse : CropGroup
        {
            [XmlElement(ElementName = "CropGroupID")]
            public string CropGroupIDRaw
            {
                get
                {
                    return CropGroupID.ToString();
                }
                set
                {
                    if (string.IsNullOrEmpty(value))
                        CropGroupID = null;
                    else
                        CropGroupID = Convert.ToInt32(value);
                }
            }

            public string MTStat { get; set; }

        }

        public class CropSegmentResponse : CropSegment
        {
        }

        public class CropTraitResponse : CropTrait
        {

        }
        public class CropLovResponse : CropLov
        {

        }
    }
}
