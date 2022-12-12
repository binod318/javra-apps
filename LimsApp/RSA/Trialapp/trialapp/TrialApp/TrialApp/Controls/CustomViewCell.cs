using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Input;
using Xamarin.Forms;
using ViewCell = MR.Gestures.ViewCell;

namespace TrialApp.Controls
{
    public partial class CustomViewCell:ViewCell
    {
        public new static readonly BindableProperty TappedCommandProperty =
        BindableProperty.Create("TappedCommandProperty", typeof(ICommand), typeof(CustomViewCell), null, propertyChanged: OnTappedCommandChanged);

        public new ICommand TappedCommand
        {
            get { return (ICommand)GetValue(TappedCommandProperty); }
            set { SetValue(TappedCommandProperty, value); }
        }

        protected override void OnAppearing()
        {
            base.OnAppearing();
            OnTappedCommandChanged(this, null, null);
        }

        private static void OnTappedCommandChanged(BindableObject bindable, object oldValue, object newValue)
        {
            var viewCell = bindable as CustomViewCell;

            if (viewCell == null)
                return;

            viewCell.View.GestureRecognizers.Clear();
            //viewCell.View.GestureRecognizers.Add(new TapGestureRecognizer() { Command = viewCell.TappedCommand });
        }
    }
}
