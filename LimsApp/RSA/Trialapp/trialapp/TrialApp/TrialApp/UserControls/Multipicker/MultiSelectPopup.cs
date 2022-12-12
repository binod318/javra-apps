using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using Rg.Plugins.Popup.Pages;
using Rg.Plugins.Popup.Services;
using Xamarin.Forms;

namespace XFMultiPicker
{
    public class MultiPickerPopupPage<T> : PopupPage
    {
        private IList<T> _items;
        private IList<T> _selectedItems;

        private IList<WrappedSelection<T>> _wrappedItems;
        private readonly ListView _listView;

        public string Source { get; set; }

        // event callback
        public event EventHandler<object> CallbackEvent;

        public MultiPickerPopupPage()
        {
            HasSystemPadding = true;
            Padding = new Thickness(50, 50);

            _listView = new ListView
            {
                BackgroundColor = Color.FromRgb(240, 240, 240),
                ItemTemplate = new DataTemplate(typeof(WrappedItemSelectionTemplate)),
            };
            
            var lblClose = new MR.Gestures.Label
            {
                HeightRequest = 40,
                Text = "  CLOSE ( X )  ",
                HorizontalOptions = LayoutOptions.Center,
                VerticalOptions = LayoutOptions.Center,
                HorizontalTextAlignment = TextAlignment.Center,
                VerticalTextAlignment = TextAlignment.Center
            };

            lblClose.Tapped += async(sender, args) => await PopupNavigation.Instance.PopAsync();
            
            var stck = new StackLayout
            {
                Orientation = StackOrientation.Vertical,
                Spacing = 5,
                Children =
                {
                    _listView, lblClose
                }
            };

            Content = new Frame
            {
                Padding = 10,
                BackgroundColor = Color.Silver,
                Content = stck
            };
        }

        public IList<T> Items
        {
            get { return _items; }
            set
            {
                _items = value;
                WrappedItems = _items.Select(item => new WrappedSelection<T> { Item = item}).ToList();
            }
        }

        public IList<T> SelectedItems
        {
            get { return _selectedItems; }
            set
            {
                _selectedItems = value;
                SetSelection(value);
            }
        }

        public IList<WrappedSelection<T>> WrappedItems
        {
            get { return _wrappedItems; }
            set
            {
                _wrappedItems = value;
                _listView.ItemsSource = value;
            }
        }

        protected override void OnDisappearing()
        {
            base.OnDisappearing();

            _selectedItems.Clear();
            foreach (T item in GetSelection())
                    _selectedItems.Add(item);

            //New code after it stopped working
            object[] data = new object[2];
            data[0] = Source;
            data[1] = _selectedItems;
            CallbackEvent?.Invoke(this, data);
        }

        private IList<T> GetSelection()
        {
            return WrappedItems.Where(item => item.IsSelected).Select(wrappedItem => wrappedItem.Item).ToList();
        }

        private void SetSelection(IList<T> selectedItems)
        {
            foreach (WrappedSelection<T> wrappedItem in WrappedItems)
                if (selectedItems != null)
                    wrappedItem.IsSelected = selectedItems.Contains(wrappedItem.Item);
                //else
                //    wrappedItem.IsSelected = false;
        }

        public class WrappedSelection<T> : INotifyPropertyChanged
        {
            private bool _isSelected;
            public T Item { get; set; }

            public bool IsSelected
            {
                get { return _isSelected; }
                set
                {
                    if (_isSelected != value)
                    {
                        _isSelected = value;
                        PropertyChanged(this, new PropertyChangedEventArgs(nameof(IsSelected)));
                    }
                }
            }

            public event PropertyChangedEventHandler PropertyChanged = delegate { };
        }

        public class WrappedItemSelectionTemplate : ViewCell
        {
            public WrappedItemSelectionTemplate()
            {
                var name = new Label();
                name.SetBinding(Label.TextProperty, new Binding("Item.Name"));

                var mainSwitch = new Switch();
                mainSwitch.SetBinding(Switch.IsToggledProperty, new Binding("IsSelected"));
                
                Grid layout = new Grid();
                layout.Margin = new Thickness(10);
                layout.ColumnDefinitions.Add(new ColumnDefinition
                {
                    Width = GridLength.Star
                });
                layout.ColumnDefinitions.Add(new ColumnDefinition
                {
                    Width = GridLength.Auto
                });
                layout.Children.Add(mainSwitch,1,0);
                layout.Children.Add(name);

                View = layout;
            }
        }
    }
}