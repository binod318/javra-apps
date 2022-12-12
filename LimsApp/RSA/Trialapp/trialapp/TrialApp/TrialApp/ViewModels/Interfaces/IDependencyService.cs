namespace TrialApp.ViewModels.Interfaces
{
    public interface IDependencyService
    {
        T Get<T>() where T : class;
        void Register<T>(T impl);
    }
    public interface INotificationHelper
    {

        void UpdateToken(string userName);

    }
}
