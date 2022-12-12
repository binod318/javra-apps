using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TrialApp.Common
{
  public interface ILogger
    {
         Task Log(string text);
    }
}
