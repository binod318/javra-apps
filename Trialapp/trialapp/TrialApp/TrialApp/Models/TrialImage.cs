using TrialApp.ViewModels;

namespace TrialApp.Models
{
    public class TrialImage: ObservableViewModel
    {
        private bool deletevisible;
        public string Title { get; set; }
        public string ImageLocation { get; set; }
        public bool FromBlob { get; set; }
        public Xamarin.Forms.ImageSource ImageSource { get; set; }
        public bool Deletevisible 
        {
            get { return deletevisible; }
            set
            {
                deletevisible = value;
                OnPropertyChanged();
            }
        }
    }
}