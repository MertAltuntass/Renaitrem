using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows;

namespace RenaitreGUI.ViewModels;

public abstract class BaseViewModel : INotifyPropertyChanged
{
    public event PropertyChangedEventHandler? PropertyChanged;

    protected void OnPropertyChanged([CallerMemberName] string? name = null)
        => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));

    protected bool Set<T>(ref T field, T value, [CallerMemberName] string? name = null)
    {
        if (EqualityComparer<T>.Default.Equals(field, value)) return false;
        field = value;
        OnPropertyChanged(name);
        return true;
    }

    // UI thread'e güvenli güncelleme
    protected void Dispatch(Action action)
        => Application.Current.Dispatcher.Invoke(action);

}
