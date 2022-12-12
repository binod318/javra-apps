using Enza.UTM.Common.Extensions;
using System;

namespace Enza.UTM.Services.EmailTemplates
{
    public class EmailTemplate
    {
        public static string GetMissingConversionMail(string type = null)
        {
            //if type is SH return SH missing conversion
            if (type == "SH")
            {
                return typeof(EmailTemplate).Assembly.GetString("Enza.UTM.Services.EmailTemplates.SHMissingConversionMail.st");
            }
            //if not return general conversion missing email
            return typeof(EmailTemplate).Assembly.GetString("Enza.UTM.Services.EmailTemplates.MissingConversionMail.st");
        }

        public static string GetTestCompleteNotificationEmailTemplate(string testType)
        {
            if (testType.EqualsIgnoreCase("rdt"))
                return typeof(EmailTemplate).Assembly.GetString("Enza.UTM.Services.EmailTemplates.RDTTestCompleteNotification.st");
            return typeof(EmailTemplate).Assembly.GetString("Enza.UTM.Services.EmailTemplates.TestCompleteNotification.st");
        }

        public static string GetColumnSetErrorEmailTemplate(string type)
        {
            if (type.EqualsIgnoreCase("rdtmissingcolumn"))
                return typeof(EmailTemplate).Assembly.GetString("Enza.UTM.Services.EmailTemplates.RDTSetColumnErrorMissingColumn.st");
            else if (type.EqualsIgnoreCase("rdt"))
                return typeof(EmailTemplate).Assembly.GetString("Enza.UTM.Services.EmailTemplates.RDTSetColumnError.st");
            else if (type.EqualsIgnoreCase("missingcolumn"))
                return typeof(EmailTemplate).Assembly.GetString("Enza.UTM.Services.EmailTemplates.SetColumnErrorMissingColumn.st");
            return typeof(EmailTemplate).Assembly.GetString("Enza.UTM.Services.EmailTemplates.SetColumnError.st");
        }

        public static string GetLeafDiskTestResultEmailTemplate(string resultType)
        {
            if (resultType.EqualsIgnoreCase("positive"))
                return typeof(EmailTemplate).Assembly.GetString("Enza.UTM.Services.EmailTemplates.LeafDiskTestResultPositive.st");
            return typeof(EmailTemplate).Assembly.GetString("Enza.UTM.Services.EmailTemplates.LeafDiskTestResultNegative.st");
        }

        public static string GetPartiallyResultSentEmailTemplate()
        {
            return typeof(EmailTemplate).Assembly.GetString("Enza.UTM.Services.EmailTemplates.RDTPartiallySentResult.st");
        }
    }
}
