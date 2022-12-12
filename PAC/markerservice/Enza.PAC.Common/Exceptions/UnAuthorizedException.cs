using System;

namespace Enza.PAC.Common.Exceptions
{
    public class UnAuthorizedException : Exception
    {
        public UnAuthorizedException(string message) : base(message)
        {
        }
    }
}
