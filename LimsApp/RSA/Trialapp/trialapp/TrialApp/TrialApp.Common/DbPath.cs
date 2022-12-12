using Xamarin.Forms;

namespace TrialApp.Common
{
    public class DbPath
    {
        public static string GetMasterDbPath()
        {
            try
            {
                return DependencyService.Get<IFileHelper>().GetLocalFilePath("Master.db");
            }
            catch (System.Exception)
            {
                return "master db path not found";
            }
        }
        public static string GetTransactionDbPath()
        {
            try
            {
                return DependencyService.Get<IFileHelper>().GetLocalFilePath("Transaction.db");

            }
            catch (System.Exception)
            {
                return "transaction db path not found";
            }
            

        }
    }
}
