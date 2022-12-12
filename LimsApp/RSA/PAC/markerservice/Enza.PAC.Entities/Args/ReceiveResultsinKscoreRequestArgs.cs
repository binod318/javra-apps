using System;
using System.Collections.Generic;

namespace Enza.PAC.Entities.Args
{
    public class ReceiveResultsinKscoreRequestArgs
    {
        public ReceiveResultsinKscoreRequestArgs()
        {
            Plates = new List<KscorePlate>();
        }
        public int RequestID { get; set; }
        public List<KscorePlate> Plates { get; set; }
    }
    public class KscorePlate
    {
        public KscorePlate()
        {
            Wells = new List<KscoreWell>();
        }
        public int LIMSPlateID { get; set; }
        public List<KscoreWell> Wells { get; set; }
    }

    public class KscoreWell
    {
        public KscoreWell()
        {
            Markers = new List<KscoreMarker>();
        }
        public string PlateRow { get; set; }
        public int PlateColumn { get; set; }
        public List<KscoreMarker> Markers { get; set; }
    }

    public class KscoreMarker
    {
        public string MarkerNr { get; set; }
        public string AlleleScore { get; set; }
        public string CreationDate { get; set; }
    }

    public class receiveResult
    {
        public string XmlContent { get; set; }
    }

    //public class ReceiveResultsinKscoreRequestArgs1
    //{
    //    public ReceiveResultsinKscoreRequestArgs1()
    //    {
    //        Plates = new Plates1();
    //    }
    //    public object RequestID { get; set; }
    //    //public object Plates12 { get; set; }
    //    public Plates1 Plates { get; set; }
    //    public class Plates1
    //    {
    //        public Plates1()
    //        {
    //            Plate = new List<Plate1>();
    //        }
    //        public List<Plate1> Plate { get; set; }
    //    }
    //    public class Plate1
    //    {
    //        public Plate1()
    //        {
    //            Wells = new Wells1();
    //        }
    //        public string LimsPlateID { get; set; }
    //        public string LimsPlateName { get; set; }
    //        public string PlateNr { get; set; }
    //        public Wells1 Wells { get; set; }
    //    }
    //    public class Wells1
    //    {
    //        public Wells1()
    //        {
    //            Well = new List<Well1>();
    //        }
    //        public List<Well1> Well { get; set; }
    //    }
    //    public class Well1
    //    {
    //        public Well1()
    //        {
    //            Markers = new Markers1();
    //        }
    //        public string BreedingStationCode { get; set; }
    //        public Markers1 Markers { get; set; }
    //        public string PlantNr { get; set; }
    //        public string PlateColumn { get; set; }
    //        public string PlateRow { get; set; }
    //    }
    //    public class Markers1
    //    {
    //        public Markers1()
    //        {
    //            Marker = new List<Marker1>();
    //        }
    //        public List<Marker1> Marker { get; set; }
    //    }
    //    public class Marker1
    //    {
    //        public Marker1()
    //        {
    //            Scores = new Scores1();
    //        }
    //        public string MarkerNr { get; set; }
    //        public Scores1 Scores { get; set; }
    //    }
    //    public class Scores1
    //    {
    //        public Scores1()
    //        {
    //            Score = new Score1();
    //        }
    //        public Score1 Score { get; set; }
    //    }
    //    public class Score1
    //    {
    //        public string AlleleScore { get; set; }
    //        //public string CreationDate { get; set; }
    //    }
    //}


}
