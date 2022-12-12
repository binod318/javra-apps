using System.Xml.Serialization;

namespace TrialApp.Entities.Master
{
    public class CropGroup
    {
        [XmlElement(ElementName = "ignore1")]
        public int? CropGroupID { get; set; }

        public string CropGroupName { get; set; }

        public string MTSeq { get; set; }
    }

    public class Country
    {
        public string CountryCode { get; set; }
        public string CountryName { get; set; }
        public string MTSeq { get; set; }
    }

    public class CDM_Filter
    {
        public string AppName { get; set; }
        public string TableName { get; set; }
        public string FieldName { get; set; }

        public string FieldLabel { get; set; }

        public int SortingOrder { get; set; }

        public string DescField { get; set; }

        public string MTSeq { get; set; }
        public string FromDatabase { get; set; }
    }

    public class CropRD
    {
        public string CropCode { get; set; }

        public string CropName { get; set; }
        [XmlElement(ElementName = "ignore2")]
        public int? CropGroupID { get; set; }

        public string MTSeq { get; set; }
    }

    public class EntityType
    {
        public string EntityTypeCode { get; set; }
        public string EntityTypeName { get; set; }
        public string TableName { get; set; }
        public int MTSeq { get; set; }
        public string MTStat { get; set; }

    }

    public class FieldSet
    {
        public string FieldSetID { get; set; }
        public string FieldSetCode { get; set; }
        public string FieldSetName { get; set; }
        public string CropCode { get; set; }
        public bool Property { get; set; }
        public bool NormalTrait { get; set; }
        public int MTSeq { get; set; }
        public string MTStat { get; set; }

    }

    public class PropertyOfEntity
    {
        public int PropertyID { get; set; }

        public string EntityTypeCode { get; set; }

        public int TraitID { get; set; }

        public string TableField { get; set; }

        public int MTSeq { get; set; }

        public string MTStat { get; set; }

    }



    public class TraitInFieldSet
    {
        [XmlElement(ElementName = "ignore4")]
        public int? FieldSetID { get; set; }

        public int TraitID { get; set; }
        [XmlElement(ElementName = "ignore6")]
        public int? SortingOrder { get; set; }


        public int MTSeq { get; set; }


        public string MTStat { get; set; }

    }

    public class TraitType
    {
        [XmlElement(ElementName = "ignore7")]
        public int? TraitTypeID { get; set; }
        public string TraitTypeName { get; set; }
        public int MTSeq { get; set; }
        public string MTStat { get; set; }
    }

    public class TraitValue
    {
        public string TraitValueCode { get; set; }
        public string TraitValueName { get; set; }
        [XmlElement(ElementName = "ignore9")]
        public int? TraitValueID { get; set; }

        [XmlElement(ElementName = "ignore10")]
        public int? TraitID { get; set; }

        [XmlElement(ElementName = "ignore11")]
        public int? SortingOrder { get; set; }
        public int MTSeq { get; set; }
        public string MTStat { get; set; }

    }

    public class Trait
    {
        public int TraitID { get; set; }

        [XmlElement(ElementName = "ignore14")]
        public int? TraitTypeID
        { get; set; }

        public string TraitName { get; set; }

        public string ColumnLabel { get; set; }


        public string DataType { get; set; }

        public bool Updatable { get; set; }

        public string DisplayFormat { get; set; }


        public bool Editor { get; set; }


        public bool ListOfValues { get; set; }
        [XmlElement(ElementName = "ignore15")]
        public int? MinValue { get; set; }
        [XmlElement(ElementName = "ignore16")]
        public int? MaxValue { get; set; }


        public bool Property { get; set; }

        [XmlElement(ElementName = "ignore18")]
        public string BaseUnitImp { get; set; }

        [XmlElement(ElementName = "ignore19")]
        public string BaseUnitMet { get; set; }

        [XmlElement(ElementName = "ignore17")]
        public int? MTSeq { get; set; }


        public string MTStat { get; set; }
        public bool ShowSum { get; set; }
        public string Description { get; set; }

    }

    public class TrialRegion
    {

        public int TrialRegionID { get; set; }


        public string TrialRegionName { get; set; }

        public string TrialRegionCode { get; set; }
        public int MTSeq { get; set; }

        public string MTStat { get; set; }

    }

    public class TrialType
    {
        public int TrialTypeID { get; set; }
        public string TrialTypeName { get; set; }
        public string TrialTypeCode { get; set; }
        public bool Commercial { get; set; }
        public int MTSeq { get; set; }
        public string MTStat { get; set; }

    }

    public class SequenceTable
    {
        public string TableName { get; set; }
        public int Sequence { get; set; }
    }

    public class CropSegment
    {
        public string CropSegmentCode { get; set; }
        public string CropSegmentName { get; set; }
        public string CropCode { get; set; }
        public int MTSeq { get; set; }
        public string MTStat { get; set; }
    }

    public class CropTrait
    {
        public string CropCode { get; set; }
        public int TraitID { get; set; }
        public int MTSeq { get; set; }
        public string MTStat { get; set; }
    }

    public class CropLov
    {
        public string CropCode { get; set; }
        public int TraitValueID { get; set; }
        public int MTSeq { get; set; }
        public string MTStat { get; set; }
    }

}
