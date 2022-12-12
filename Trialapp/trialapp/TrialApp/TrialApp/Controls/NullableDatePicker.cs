using System;
using System.Collections;
using System.Collections.Specialized;
using System.Reflection;
using Xamarin.Forms;

namespace TrialApp.Controls
{
    public class NullableDatePicker : DatePicker
    {
        

         private string _format = null;
         public static readonly BindableProperty NullableDateProperty =
            BindableProperty.Create("NullableDate", typeof(DateTime?), typeof(NullableDatePicker), null, BindingMode.TwoWay);
        

         public DateTime? NullableDate
         {
             get { return (DateTime?)GetValue(NullableDateProperty); }
             set { SetValue(NullableDateProperty, value); UpdateDate(); }
         }
         private void UpdateDate()
         {
             if (NullableDate.HasValue)
             {
                 if (null != _format) Format = _format;
                 Date = NullableDate.Value;
             }
             else
             {
                 _format = Format;
                 Format = "pick ...";
                 
             }
         }
         protected override void OnBindingContextChanged()
         {
             base.OnBindingContextChanged();
             UpdateDate();
         }
    }
}
