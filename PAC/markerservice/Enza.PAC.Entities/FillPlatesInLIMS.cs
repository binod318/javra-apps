using System.Collections.Generic;

namespace Enza.PAC.Entities
{
    public class FillPlatesInLIMS
    {
        public string CropCode { get; set; }
        public int LimsPlateplanID { get; set; }
        public int RequestID { get; set; }
        public int LimsPlateID { get; set; }
        public string LimsPlateName { get; set; }
        public int MarkerNr { get; set; }
        public string MarkerName { get; set; }
        public int PlateColumn { get; set; }
        public string PlateRow { get; set; }
        public string PlantNr { get; set; }
        public string PlantName { get; set; }
        public string BreedingStationCode { get; set; }
    }


    public class FillPlatesInLIMSService
    {
        public string CropCode { get; set; }
        public int LimsPlatePlanID { get; set; }
        public int RequestID { get; set; }
        public List<Plate> Plates { get; set; }
    }

    public class Plate
    {
        public int LimsPlateID { get; set; }
        public string LimsPlateName { get; set; }
        public List<Marker> Markers { get; set; }
        public List<Well> Wells { get; set; }
    }

    public class Marker
    {
        public int MarkerNr { get; set; }
        public string MarkerName { get; set; }
    }

    public class Well
    {
        public int PlateColumn { get; set; }
        public string PlateRow { get; set; }
        public string PlantNr { get; set; }
        public string PlantName { get; set; }
        public string BreedingStationCode { get; set; }
    }
}
