using System;
using System.Collections.Specialized;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace Enza.PSC.BusinessAccess.Proxies
{
    public class RestClient : IDisposable
    {
        private bool disposed;
        private readonly HttpClient _client;
        private readonly HttpClientHandler _handler;
        private const int DEFAULT_TIMEOUT = 100;//seconds

        public RestClient(string baseAddress)
        {
            _handler = new HttpClientHandler
            {
                PreAuthenticate = false,
                UseCookies = false,
                UseDefaultCredentials = false
            };
            _client = new HttpClient(_handler)
            {
                BaseAddress = new Uri(baseAddress),
                Timeout = Timeout.InfiniteTimeSpan
            };
            ServicePointManager.ServerCertificateValidationCallback = (sender, certificate, chain, errors) =>
            {
                return true;
            };
        }

        public void AddRequestHeaders(NameValueCollection headers)
        {
            foreach (string key in headers.Keys)
            {
                var values = headers.GetValues(key);
                _client.DefaultRequestHeaders.Add(key, values);
            }
        }

        public void AddRequestHeaders(Action<NameValueCollection> headers)
        {
            var list = new NameValueCollection();
            headers(list);
            AddRequestHeaders(list);
        }

        public async Task<HttpResponseMessage> GetAsync(string url, int timeout)
        {
            try
            {
                using (var cts = new CancellationTokenSource(TimeSpan.FromSeconds(timeout)))
                {
                    var response = await _client.GetAsync(url, cts.Token);
                    return response;
                }
            }
            catch (TaskCanceledException ex)
            {
                throw new TimeoutException("Request timeout occured.", ex);
            }
        }

        public Task<HttpResponseMessage> GetAsync(string url)
        {
            return GetAsync(url, DEFAULT_TIMEOUT);
        }



        public async Task<HttpResponseMessage> PostAsync(string url, object content, int timeout)
        {
            try
            {
                using (var cts = new CancellationTokenSource(TimeSpan.FromSeconds(timeout)))
                {
                    var json = Newtonsoft.Json.JsonConvert.SerializeObject(content);
                    var stringContent = new StringContent(json, Encoding.UTF8, "application/json");
                    var response = await _client.PostAsync(url, stringContent, cts.Token);

                    return response;
                }
            }
            catch (TaskCanceledException ex)
            {
                throw new TimeoutException("Request timeout occured.", ex);
            }
        }

        public Task<HttpResponseMessage> PostAsync(string url, object content)
        {
            return PostAsync(url, content, DEFAULT_TIMEOUT);
        }

        protected virtual void Dispose(bool disposing)
        {
            if (disposed) return;

            if (disposing)
            {
                _handler?.Dispose();
                _client?.Dispose();
            }

            disposed = true;
        }

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }
    }
}
