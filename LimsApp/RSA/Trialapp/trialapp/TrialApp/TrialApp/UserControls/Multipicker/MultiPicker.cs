using System;
using System.Collections.Generic;
using Rg.Plugins.Popup.Services;
using Xamarin.Forms;

namespace XFMultiPicker
{
    public class MultiPickerView<T> : Button where T : class
    {
        public static readonly BindableProperty ItemsSourceProperty =
            BindableProperty.Create("ItemsSource", typeof(IList<T>), typeof(MultiPickerView<T>),
                null,BindingMode.TwoWay, propertyChanged: OnItemsSourceChanged);

        public static readonly BindableProperty SelectedItemsProperty =
            BindableProperty.Create("SelectedItems", typeof(IList<T>), typeof(MultiPickerView<T>),
                null, BindingMode.TwoWay, propertyChanged: OnSelectedItemsChanged);
        
        public EventHandler<object> CallbackEx;

        //[System.Obsolete]
        public MultiPickerView()
        {
            Command = new Command(async () => { await PopupNavigation.Instance.PushAsync(PopupPage); }, () => SelectedItems != null);
            PopupPage = new MultiPickerPopupPage<T>();
            PopupPage.CallbackEvent += OnCallback; // the method where you do whatever you want to after the popup is closed
        }

        private void OnCallback(object sender, object e)
        {
            CallbackEx?.Invoke(sender, e);
        }

        public MultiPickerPopupPage<T> PopupPage { get; set; }

        public IList<T> ItemsSource
        {
            get { return (IList<T>) GetValue(ItemsSourceProperty); }
            set { SetValue(ItemsSourceProperty, value); }
        }

        public IList<T> SelectedItems
        {
            get { return (IList<T>) GetValue(SelectedItemsProperty); }
            set { SetValue(SelectedItemsProperty, value); }
        }

        private static void OnItemsSourceChanged(BindableObject bindable, object oldvalue, object newvalue)
        {
            var picker = bindable as MultiPickerView<T>;
            var source = picker.ClassId;
            picker.PopupPage.Source = source;
            if (newvalue is IList<T> items)
                picker.PopupPage.Items = items;

        }

        private static void OnSelectedItemsChanged(BindableObject bindable, object oldvalue, object newvalue)
        {
            var picker = bindable as MultiPickerView<T>;
            ((Command)picker.Command).ChangeCanExecute();
            var items = newvalue as IList<T>;
                picker.PopupPage.SelectedItems = items;
        }
    }
}