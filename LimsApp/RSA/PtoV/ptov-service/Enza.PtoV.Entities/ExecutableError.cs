using System;

namespace Enza.PtoV.Entities
{
    public class ExecutableError
    {
        public bool Success { get; set; }
        public string CropCode { get; set; }
        public string SyncCode { get; set; }
        public string ErrorMessage { get; set; }
        public string ErrorType { get; set; }
        public Exception Exception { get; set; }
    }
}
