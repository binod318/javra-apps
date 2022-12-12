using System.Collections.Generic;

namespace TrialApp.Helper
{
    public class CaseInsensitiveEqualityComparer : IEqualityComparer<object>
    {
        public new bool Equals(object x, object y)
        {
            if (x != null && x.ToString().ToLower().Contains(y.ToString().ToLower()))
                return true;

            return false;
        }

        public int GetHashCode(object obj)
        {
            return obj.GetHashCode();
        }
    }
}
