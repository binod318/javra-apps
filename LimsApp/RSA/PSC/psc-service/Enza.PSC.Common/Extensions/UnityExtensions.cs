using System;
using Unity;
using Unity.Injection;
using Unity.Lifetime;

namespace Enza.PSC.Common.Extensions
{
    public static class UnityExtensions
    {
        /// <summary>
        /// Creates instance per-request
        /// </summary>
        /// <typeparam name="T1"></typeparam>
        /// <typeparam name="T2"></typeparam>
        /// <param name="container"></param>
        public static void AddScoped<T1, T2>(this IUnityContainer container) where T2 : T1
        {
            container.RegisterType<T1, T2>(new HierarchicalLifetimeManager());
        }

        public static void AddScoped<T1, T2>(this IUnityContainer container, params object[] args) where T2 : T1
        {
            container.RegisterType<T1, T2>(new HierarchicalLifetimeManager(), new InjectionConstructor(args));
        }

        public static void Register<T1>(this IUnityContainer container, Func<T1> impl, IInstanceLifetimeManager lifetimeManager)
        {
            var obj = impl();
            container.RegisterInstance(obj, lifetimeManager);
        }


        /// <summary>
        /// Creates single instance
        /// </summary>
        /// <typeparam name="T1"></typeparam>
        /// <typeparam name="T2"></typeparam>
        /// <param name="container"></param>
        public static void AddSingleton<T1, T2>(this IUnityContainer container) where T2 : T1
        {
            container.RegisterType<T1, T2>(new ContainerControlledLifetimeManager());
        }

        /// <summary>
        /// Creates new instance each time
        /// </summary>
        /// <typeparam name="T1"></typeparam>
        /// <typeparam name="T2"></typeparam>
        /// <param name="container"></param>
        public static void AddTransient<T1, T2>(this IUnityContainer container) where T2 : T1
        {
            container.RegisterType<T1, T2>(new TransientLifetimeManager());
        }
    }
}
