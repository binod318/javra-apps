using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace TrialApp.Services
{
    public interface IDataStore<T>
    {
        Task<bool> AddItemAsync(T item);
        Task<bool> UpdateItemAsync(T item);
        Task<bool> DeleteItemAsync(string id);
        Task<T> GetItemAsync(string id);
        Task<IEnumerable<T>> GetItemsAsync(bool forceRefresh = false);
    }

    public interface ICustomizeComboBoxBehavior
    {
        void GetRender(Syncfusion.XForms.ComboBox.SfComboBox comboBox);
        void UnHook(Syncfusion.XForms.ComboBox.SfComboBox comboBox);
    }
}
