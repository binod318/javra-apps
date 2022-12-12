using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using TrialApp.Models;

namespace TrialApp.Services
{
    public class MockDataStore : IDataStore<Trial>
    {
        readonly List<Trial> trials;

        public MockDataStore()
        {
            trials = new List<Trial>()
            {
                new Trial { EZID = Guid.NewGuid().ToString(), Name = "First item", Description="This is an item description." }
            };
        }

        public async Task<bool> AddItemAsync(Trial item)
        {
            trials.Add(item);

            return await Task.FromResult(true);
        }

        public async Task<bool> UpdateItemAsync(Trial item)
        {
            var oldItem = trials.Where((Trial arg) => arg.EZID == item.EZID).FirstOrDefault();
            trials.Remove(oldItem);
            trials.Add(item);

            return await Task.FromResult(true);
        }

        public async Task<bool> DeleteItemAsync(string id)
        {
            var oldItem = trials.Where((Trial arg) => arg.EZID == id).FirstOrDefault();
            trials.Remove(oldItem);

            return await Task.FromResult(true);
        }

        public async Task<Trial> GetItemAsync(string id)
        {
            return await Task.FromResult(trials.FirstOrDefault(s => s.EZID == id));
        }

        public async Task<IEnumerable<Trial>> GetItemsAsync(bool forceRefresh = false)
        {
            return await Task.FromResult(trials);
        }
    }
}