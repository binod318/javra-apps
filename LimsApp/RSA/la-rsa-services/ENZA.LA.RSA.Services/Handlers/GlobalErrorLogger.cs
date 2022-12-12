using System.Web.Http.ExceptionHandling;
using log4net;

namespace ENZA.LA.RSA.Services.Handlers
{
    public class GlobalErrorLogger : ExceptionLogger
    {
        private readonly ILog logger;
        public GlobalErrorLogger()
        {
            logger = LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);
        }
        public override void Log(ExceptionLoggerContext context)
        {
            if (logger.IsErrorEnabled)
            {
                var exception = context.Exception;
                logger.Error(exception);
                
            }
        }

    }
}
