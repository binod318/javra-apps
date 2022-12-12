using System.Collections.Generic;
using System.Xml.Serialization;
using TrialApp.Entities.Master;
using static TrialApp.Entities.ServiceResponse.MasterDataTableResponse;

namespace TrialApp.Entities.ServiceResponse
{
    [XmlRoot(ElementName = "old")]
    public class Old
    {
        [XmlElement(ElementName = "FieldSet")]
        public FieldSetResponse FieldSet { get; set; }

        [XmlElement(ElementName = "Country")]
        public Country1 Country { get; set; }

        [XmlElement(ElementName = "CropGroup")]
        public CropGroupResponse CropGroup { get; set; }

        [XmlElement(ElementName = "CropRD")]
        public CropRDResponse CropRD { get; set; }

        [XmlElement(ElementName = "EntityType")]
        public EntityType EntityType { get; set; }

        [XmlElement(ElementName = "PropertyOfEntity")]
        public PropertyOfEntity PropertyOfEntity { get; set; }

        [XmlElement(ElementName = "View_Trait_TDM")]
        public TraitResponse Trait { get; set; }

        [XmlElement(ElementName = "TraitInFieldSet")]
        public TraitInFieldSetResponse TraitInFieldSet { get; set; }

        [XmlElement(ElementName = "TraitType")]
        public TraitTypeResponse TraitType { get; set; }

        [XmlElement(ElementName = "TrialRegion")]
        public TrialRegion TrialRegion { get; set; }

        [XmlElement(ElementName = "TrialType")]
        public TrialType TrialType { get; set; }

        [XmlElement(ElementName = "View_TraitValue_TDM")]
        public TraitValueResponse TraitValue { get; set; }

        [XmlElement(ElementName = "CropSegment")]
        public CropSegmentResponse CropSegment { get; set; }

        [XmlElement(ElementName = "View_CropTrait_TDM")]
        public CropTraitResponse CropTrait { get; set; }

        [XmlElement(ElementName = "View_CropLov_TDM")]
        public CropLovResponse CropLov { get; set; }
    }

    [XmlRoot(ElementName = "tuple")]
    public class Tuple
    {
        [XmlElement(ElementName = "old")]
        public Old Old { get; set; }
    }

    [XmlRoot(ElementName = "getMasterDataOutput")]
    public class GetMasterDataOutput
    {
        [XmlElement(ElementName = "tuple")]
        public List<Tuple> Tuple { get; set; }
    }

    [XmlRoot(ElementName = "getMasterData_V3Response")]
    public class GetMasterData_V3Response
    {
        [XmlElement(ElementName = "getMasterDataOutput")]
        public GetMasterDataOutput GetMasterDataOutput { get; set; }
    }

    [XmlRoot(ElementName = "GetMasterData_V4Response")]
    public class GetMasterData_V4Response
    {
        [XmlElement(ElementName = "getMasterDataOutput")]
        public GetMasterDataOutput GetMasterDataOutput { get; set; }
    }
    public class Country1
    {
        public string CountryCode { get; set; }
        public string CountryName { get; set; }
        public string MTSeq { get; set; }
        public string MTStat { get; set; }
    }
}
