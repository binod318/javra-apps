using System.ComponentModel;
using System.Runtime.CompilerServices;
using XFMultiPickerSample.Annotations;

namespace Model
{
    public class MyType : NameType
    {
        private string _id;

        public string Id
        {
            get { return _id; }
            set
            {
                if (value == _id) return;
                _id = value;
                OnPropertyChanged();
            }
        }

        // ...

        // some more properties:
    }

    // some base class
    public class NameType : INotifyPropertyChanged
    {
        private string _name;

        public string Name
        {
            get { return _name; }
            set
            {
                if (value == _name) return;
                _name = value;
                OnPropertyChanged();
            }
        }

        public event PropertyChangedEventHandler PropertyChanged;

        [NotifyPropertyChangedInvocator]
        protected virtual void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }

    //public class MyAddress : MyAddress1
    //{
    //    private int _id1;

    //    public int Id1
    //    {
    //        get { return _id1; }
    //        set
    //        {
    //            if (value == _id1) return;
    //            _id1 = value;
    //            OnPropertyChanged();
    //        }
    //    }
    //}
    //public class MyAddress1 : INotifyPropertyChanged
    //{
    //    private string _name;

    //    public string Address1
    //    {
    //        get { return _name; }
    //        set
    //        {
    //            if (value == _name) return;
    //            _name = value;
    //            OnPropertyChanged();
    //        }
    //    }

    //    public event PropertyChangedEventHandler PropertyChanged;

    //    [NotifyPropertyChangedInvocator]
    //    protected virtual void OnPropertyChanged([CallerMemberName] string propertyName = null)
    //    {
    //        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    //    }
    //}
}