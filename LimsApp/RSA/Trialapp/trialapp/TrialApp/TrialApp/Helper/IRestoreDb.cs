using System;
using TrialApp.ViewModels;

namespace TrialApp.Helper
{
    public interface IRestoreDb
    {
        void RestoreMyDb(string sourceFilename, string restoreZipPath, Action showMessage );
    }
}
