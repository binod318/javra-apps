using System;
using TrialApp.ViewModels.Interfaces;
using Xamarin.Forms;

namespace TrialApp.ViewModels
{
    public class DependencyServiceWrapper : IDependencyService
    {
        public T Get<T>() where T : class
        {
            return DependencyService.Get<T>();
        }

        public void Register<T>(T impl)
        {
            throw new NotImplementedException();
        }
    }
}
