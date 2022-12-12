using System;
using System.ComponentModel.DataAnnotations;

namespace Enza.PSC.Entities
{
    public class PlateHistory
    {
        [Required(ErrorMessage = "Please provide Machine Name.")]
        public string MachineName { get; set; }
        [Required(ErrorMessage = "Please provide Plate Barcode1.")]
        public string PlateBarcode1 { get; set; }
        [Required(ErrorMessage = "Please provide Plate Barcode2.")]
        public string PlateBarcode2 { get; set; }
        public DateTime CreatedDate { get; set; }
        public bool IsMatched { get; set; }
    }
}
