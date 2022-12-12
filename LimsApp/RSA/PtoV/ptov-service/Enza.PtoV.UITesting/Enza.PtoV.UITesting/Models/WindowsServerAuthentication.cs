using System.Runtime.InteropServices;

namespace Enza.PtoV.UITesting.Models
{
    public class WindowsServerAuthentication
    {
        [DllImport("shlwapi.dll", SetLastError = true, EntryPoint = "#437")]
        private static extern bool IsOS(int os);
        const int OS_ANYSERVER = 29;


        public static bool IsWindowsServer()
        {
            return IsOS(OS_ANYSERVER);
        }
    }
}
