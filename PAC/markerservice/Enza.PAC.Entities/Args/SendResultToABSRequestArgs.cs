using Enza.PAC.Entities.Args.Abstracts;
using System;
using System.Collections.Generic;

namespace Enza.PAC.Entities.Args
{
    public class SendResultToABSRequestArgs : RequestArgs
    {
        public int ID { get; set; }
    }
    public class UpdateDeterminationID
    {
        public int detAssignmentID { get; set; }
    }

    public class UpdateDAArgs
    {
        public int DetAssignmentID { get; set; }
        public string ValidatedOn { get; set; }
        public string Remarks { get; set; }
        public Decimal ResultPercentage { get; set; }
        public int QualityClass { get; set; }
        public string ValidatedBy { get; set; }
        public int NrOfWells { get; set; }
        public int NrOfInbreds { get; set; }
        public int NrOfDeviating { get; set; }
        public int SendToABS { get; set; }
    }

    public class UpdateDARequestArgs
    {
        public string Username { get; set; }
        public string Password { get; set; }
        public List<DADetail> DeterminationAssignments { get; set; }
    }

    public class DADetail
    {
        public int DetAssignmentID { get; set; }
        public string Remarks { get; set; }
        public int Result { get; set; }
        public string ApprovedDate { get; set; }
        public decimal ResultPercentage { get; set; }
        public List<DAResult> Results { get; set; }
    }

    public class DAResult
    {
        public int Result { get; set; }
        public int DeterminationCode { get; set; }
        public string ApprovedBy { get; set; }
        public int ReplicateNumber { get; set; }
    }

    public class test123
    {
        public class Plates1
        {
            public Plates1()
            {
                Plate = new List<Plate1>();
            }
            public List<Plate1> Plate { get; set; }
        }
        public class Plate1
        {
            public Plate1()
            {
                Wells = new Wells1();
            }
            public string LimsPlateID { get; set; }
            public string LimsPlateName { get; set; }
            public string PlateNr { get; set; }
            public Wells1 Wells { get; set; }
        }
        public class Wells1
        {
            public Wells1()
            {
                Well = new List<Well1>();
            }
            public List<Well1> Well { get; set; }
        }
        public class Well1
        {
            public Well1()
            {
                Markers = new Markers1();
            }
            public string BreedingStationCode { get; set; }
            public Markers1 Markers { get; set; }
            public string PlantNr { get; set; }
            public string PlateColumn { get; set; }
            public string PlateRow { get; set; }
        }
        public class Markers1
        {
            public Markers1()
            {
                Marker = new List<Marker1>();
            }
            public List<Marker1> Marker { get; set; }
        }
        public class Marker1
        {
            public Marker1()
            {
                Scores = new Scores1();
            }
            public string MarkerNr { get; set; }
            public Scores1 Scores { get; set; }
        }
        public class Scores1
        {
            public Scores1()
            {
                Score = new Score1();
            }
            public Score1 Score { get; set; }
        }
        public class Score1
        {
            public string AlleleScore { get; set; }
            //public string CreationDate { get; set; }
        }
    }
}
