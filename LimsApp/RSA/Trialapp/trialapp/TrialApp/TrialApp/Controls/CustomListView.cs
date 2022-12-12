using Xamarin.Forms;

namespace TrialApp.Controls
{
    public class CustomListView:ListView
    {
        public CustomListView()
        {
            this.ItemTapped += (object sender, ItemTappedEventArgs e) => {
                if (e.Item == null) return;
                ((ListView)sender).SelectedItem = null;
            };
        }
    }
}
