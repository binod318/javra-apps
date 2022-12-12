namespace Enza.PAC.DataAccess.Services
{
    public class SoapExecutionResult
    {
        public SoapExecutionResult()
        {
            
        }

        public SoapExecutionResult(string result, string error)
        {
            Success = !result.ToLower().Contains("failure");
            Error = error;
        }

        public bool Success{ get; private set; } 
        public string Error { get; set; }
    }
}
