using System;

namespace Enza.PSC.Common.Extensions
{
    public static class Extensions
    {
        public static Tuple<string, string> GetCredentials(this string credentials)
        {
            var chunks = credentials.Split(new[] {'|'}, 2);
            if (chunks.Length != 2)
                throw new Exception(@"Invalid credentials. Please specify credentials in <domain\user|password> format.");
            if (chunks.Length == 2)
            {
                return new Tuple<string, string>(chunks[0], chunks[1]);
            }
            return new Tuple<string, string>(chunks[0], string.Empty);
        }

        public static Exception GetException(this Exception ex)
        {
            var innerEx = ex;
            while (innerEx.InnerException != null)
            {
                innerEx = innerEx.InnerException;
            }
            return innerEx;
        }
    }
}
