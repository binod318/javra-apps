using System.Threading.Tasks;
using Xamarin.Forms;
using System;
namespace TrialApp.Controls
{
    public class HideableToolbarItem : ToolbarItem
    {
        [Obsolete]
        public HideableToolbarItem() : base()
        {
            this.InitVisibility();
        }

        [Obsolete]
        private async void InitVisibility()
        {
            await Task.Delay(100);
            OnIsVisibleChanged(this, false, IsVisible);
        }

        public ContentPage Source  { set; get; }

        [Obsolete]
        public bool IsVisible
        {
            get { return (bool)GetValue(IsVisibleProperty); }
            set { SetValue(IsVisibleProperty, value); }
        }

        [Obsolete]
        public static BindableProperty IsVisibleProperty =
            BindableProperty.Create<HideableToolbarItem, bool>(o => o.IsVisible, false, propertyChanged: OnIsVisibleChanged);

        private static void OnIsVisibleChanged(BindableObject bindable, bool oldvalue, bool newvalue)
        {
            var item = bindable as HideableToolbarItem;

            if (item.Source == null)
                return;

            var items = item.Source.ToolbarItems;

            if (newvalue && !items.Contains(item))
            {
                items.Add(item);
            }
            else if (!newvalue && items.Contains(item))
            {
                items.Remove(item);
            }
        }
    }
}
