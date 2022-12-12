using System;
using System.ComponentModel.DataAnnotations;

namespace Enza.PSC.Entities
{
    public class History
    {
        [Required(ErrorMessage = "Please provide Plate Barcode.")]
        public string PlateIDBarcode { get; set; }

        [Required(ErrorMessage = "Please provide SampleNr Barcode.")]
        public string SampleNrBarcode { get; set; }

        public string User { get; set; }
        public string CreatedDate { get; set; }

        [Required(ErrorMessage = "Please provide IsMatched.")]
        public bool IsMatched { get; set; }
    }
}
