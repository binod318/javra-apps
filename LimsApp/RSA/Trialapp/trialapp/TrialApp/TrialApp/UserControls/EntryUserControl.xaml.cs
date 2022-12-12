using System;
using System.Windows.Input;
using TrialApp.Controls;
using Xamarin.Forms;

namespace TrialApp.UserControls
{
    public partial class EntryUserControl : ContentView
    {
        public EventHandler<FocusEventArgs> UnFocusEx;
        public EventHandler<FocusEventArgs> FocusEx;
        public EventHandler SelectedIndexChangedEx;
        public EventHandler<DateChangedEventArgs> DateSelectedEx;
        public EventHandler ClickedEx;
        public EventHandler RevertClickedEx;
        public EventHandler lv_ItemTapped;
        public EventHandler<FocusEventArgs> DatePickerUnFocusedEx;
        public EventHandler<TextChangedEventArgs> EntryTextChangedEx;
        public EventHandler<MR.Gestures.LongPressEventArgs> lv_LongPressed;

        public EntryUserControl()
        {
            InitializeComponent();
            if (Device.RuntimePlatform == Device.Android)
            {
                listView.RowHeight = 50;
            }
            
        }

        public void OnRevertClickedEX(object sender, EventArgs e)
        {
            RevertClickedEx?.Invoke(sender, e);
        }

        public void OnUnFocusEx(object sender, FocusEventArgs e)
        {
            UnFocusEx?.Invoke(sender, e);
        }

        public void OnDateSelectedEx(object sender, DateChangedEventArgs e)
        {
            DateSelectedEx?.Invoke(sender, e);
        }

        public void OnSelectedIndexChangedEx(object sender, EventArgs e)
        {
            SelectedIndexChangedEx?.Invoke(sender, e);
        }

        public void OnFocusEX(object sender, FocusEventArgs e)
        {
            FocusEx?.Invoke(sender, e);
        }

        public void OnClickedEx(object sender, EventArgs e)
        {
            ClickedEx?.Invoke(sender, e);
        }

        public void OnDatePicker_Unfocused(object sender, FocusEventArgs e)
        {
            DatePickerUnFocusedEx?.Invoke(sender, e);
        }

        public void Entry_OnTextChangedEx(object sender, TextChangedEventArgs e)
        {
            EntryTextChangedEx?.Invoke(sender, e);
        }
        
        private void TapGestureRecognizer_Tapped(object sender, EventArgs e)
        {
            lv_ItemTapped?.Invoke(sender, e);
        }

        private void Grid_LongPressing(object sender, MR.Gestures.LongPressEventArgs e)
        {
            var grid = sender as MR.Gestures.Grid;
            var a4 = grid.Children[3];
            var a5 = grid.Children[4];
            var a6 = grid.Children[5];
            var a7 = grid.Children[6];
            var a8 = grid.Children[7];

            var custentry1 = a4 as CustomEntry;
            var custentry2 = a5 as CustomEntry;
            var custentry3 = a6 as CustomEntry;
            var picker = a7 as Picker;
            var datepicker = a8 as NullableDatePicker;

            custentry1.Unfocus();
            custentry2.Unfocus();
            custentry3.Unfocus();
            picker.Unfocus();
            datepicker.Unfocus();

            lv_LongPressed?.Invoke(sender, e);
        }
    }
}
