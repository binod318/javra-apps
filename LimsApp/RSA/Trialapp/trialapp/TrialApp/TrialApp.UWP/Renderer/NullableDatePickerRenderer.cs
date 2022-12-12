using System;
using TrialApp.Controls;
using TrialApp.UWP.Renderer;
using Xamarin.Forms;
using Xamarin.Forms.Platform.UWP;

[assembly: ExportRenderer(typeof(NullableDatePicker), typeof(NullableDatePickerRenderer))]
namespace TrialApp.UWP.Renderer
{
    public class NullableDatePickerRenderer : ViewRenderer<DatePicker, Windows.UI.Xaml.Controls.CalendarDatePicker>
    {
        protected override void OnElementChanged(ElementChangedEventArgs<DatePicker> e)
        {
            base.OnElementChanged(e);

            if (e.OldElement != null)
            {
                // Unsubscribe from event handlers and cleanup any resources
                if(Control != null)
                    Control.DateChanged -= OnDateChanged;

                if(Element != null)
                    Element.DateSelected -= OnDateSelected;
            }

            if (e.NewElement != null)
            {
                if (Control == null)
                {
                    // Instantiate the native control and assign it to the Control property with
                    // the SetNativeControl method
                    if (Control == null)
                    {
                        Windows.UI.Xaml.Controls.CalendarDatePicker datePicker = new Windows.UI.Xaml.Controls.CalendarDatePicker();
                        datePicker.FirstDayOfWeek = Windows.Globalization.DayOfWeek.Monday;
                        SetNativeControl(datePicker);
                    }
                }
                Control.DateChanged += OnDateChanged;
                Element.DateSelected += OnDateSelected;
            }
        }

        private void OnDateChanged(Windows.UI.Xaml.Controls.CalendarDatePicker sender, Windows.UI.Xaml.Controls.CalendarDatePickerDateChangedEventArgs e)
        {
            if (e.NewDate == null)
                return;
            DateTimeOffset dto = (DateTimeOffset)e.NewDate;
            Element.Date = dto.DateTime;
        }

        private void OnDateSelected(Object sender, DateChangedEventArgs e)
        {
            DateTime dt = e.NewDate;
            Control.Date = new DateTimeOffset(dt);
        }
    }
}
