using System;
using System.Threading;
using Xamarin.Forms;

namespace TrialApp.Controls
{
    public class MyTimer
    {
        private readonly TimeSpan timespan;
        private readonly Action callback;

        private CancellationTokenSource cancellation;

        public MyTimer(TimeSpan timespan, Action callback)
        {
            this.timespan = timespan;
            this.callback = callback;
            this.cancellation = new CancellationTokenSource();
        }

        public void Start()
        {
            CancellationTokenSource cts = this.cancellation; // safe copy
            Device.StartTimer(this.timespan,
                () => {
                    if (cts.IsCancellationRequested) return false;
                    this.callback.Invoke();
                    return true;
                });
        }

        public void Stop()
        {
            Interlocked.Exchange(ref this.cancellation, new CancellationTokenSource()).Cancel();
        }
    }
}
