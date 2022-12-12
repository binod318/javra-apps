using System;
using Newtonsoft.Json.Serialization;

namespace Enza.PSC.Common.Serialization
{
    public sealed class StringValueProvider : IValueProvider
    {
        private readonly IValueProvider provider;

        public StringValueProvider(IValueProvider provider)
        {
            if (provider == null) throw new ArgumentNullException(nameof(provider));
            this.provider = provider;
        }

        public object GetValue(object target)
        {
            return provider.GetValue(target) ?? string.Empty;
        }

        public void SetValue(object target, object value)
        {
            provider.SetValue(target, value);
        }
    }
}