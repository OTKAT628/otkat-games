using System.Diagnostics;
using System.Numerics;
using System.Text.Json;
using Otkat.Engine.Scene;

namespace Otkat.Engine;

public readonly record struct EngineTime(double DeltaSeconds, double TotalSeconds, long Frame);

public abstract class EngineObject
{
    public Guid Id { get; } = Guid.NewGuid();
    public string Name { get; set; } = "Object";
    public bool IsEnabled { get; set; } = true;
}

public sealed class Transform2D
{
    public Vector2 Position { get; set; }
    public float RotationRadians { get; set; }
    public Vector2 Scale { get; set; } = Vector2.One;
}

public abstract class Component : EngineObject
{
    public Entity? Owner { get; internal set; }
    public virtual void OnAttached() { }
    public virtual void OnDetached() { }
    public virtual void FixedUpdate(in EngineTime time) { }
    public virtual void Update(in EngineTime time) { }
}

public sealed class Entity : EngineObject
{
    private readonly List<Component> _components = [];
    public IReadOnlyList<Component> Components => _components;
    public Transform2D Transform { get; } = new();
    public T Add<T>(T component) where T : Component
    {
        ArgumentNullException.ThrowIfNull(component);
        if (component.Owner is not null) throw new InvalidOperationException("Component already attached.");
        component.Owner = this; _components.Add(component); component.OnAttached(); return component;
    }
    public bool Remove(Component component)
    {
        if (!_components.Remove(component)) return false;
        component.OnDetached(); component.Owner = null; return true;
    }
    public T? Get<T>() where T : Component => _components.OfType<T>().FirstOrDefault();
    internal void FixedUpdate(in EngineTime t) { foreach (var c in _components) if (c.IsEnabled) c.FixedUpdate(t); }
    internal void Update(in EngineTime t) { foreach (var c in _components) if (c.IsEnabled) c.Update(t); }
}

public sealed class Scene : EngineObject
{
    private readonly List<Entity> _entities = [];
    public IReadOnlyList<Entity> Entities => _entities;
    public Entity CreateEntity(string name) { var e = new Entity { Name = name }; _entities.Add(e); return e; }
    public bool RemoveEntity(Entity entity) => _entities.Remove(entity);
    internal void FixedUpdate(in EngineTime t) { foreach (var e in _entities) if (e.IsEnabled) e.FixedUpdate(t); }
    internal void Update(in EngineTime t) { foreach (var e in _entities) if (e.IsEnabled) e.Update(t); }
}

public sealed class EngineHost
{
    private readonly double _fixedStep;
    private double _accumulator, _total;
    private long _frame;
    public EngineHost(Scene initialScene, double fixedStepSeconds = 1.0 / 60.0)
    {
        CurrentScene = initialScene ?? throw new ArgumentNullException(nameof(initialScene));
        if (fixedStepSeconds <= 0 || double.IsNaN(fixedStepSeconds)) throw new ArgumentOutOfRangeException(nameof(fixedStepSeconds));
        _fixedStep = fixedStepSeconds;
    }
    public Scene CurrentScene { get; private set; }
    public event Action<EngineTime>? FrameUpdated;
    public void ChangeScene(Scene scene) => CurrentScene = scene ?? throw new ArgumentNullException(nameof(scene));
    public void Tick(double elapsedSeconds)
    {
        if (elapsedSeconds < 0 || double.IsNaN(elapsedSeconds) || double.IsInfinity(elapsedSeconds)) throw new ArgumentOutOfRangeException(nameof(elapsedSeconds));
        var dt = Math.Min(elapsedSeconds, 0.25); _total += dt; _accumulator += dt;
        while (_accumulator >= _fixedStep) { CurrentScene.FixedUpdate(new EngineTime(_fixedStep, _total, _frame)); _accumulator -= _fixedStep; }
        var time = new EngineTime(dt, _total, _frame++); CurrentScene.Update(time); FrameUpdated?.Invoke(time);
    }
    public void RunFor(TimeSpan duration, TimeSpan? frameInterval = null)
    {
        var interval = frameInterval ?? TimeSpan.FromMilliseconds(16.6667);
        if (duration < TimeSpan.Zero || interval <= TimeSpan.Zero) throw new ArgumentOutOfRangeException(nameof(duration));
        var clock = Stopwatch.StartNew(); var previous = clock.Elapsed;
        while (clock.Elapsed < duration) { var now = clock.Elapsed; Tick((now - previous).TotalSeconds); previous = now; Thread.Sleep(interval); }
    }
}

public interface IInputSource
{
    bool IsKeyDown(string key);
    bool WasKeyPressed(string key);
    Vector2 PointerPosition { get; }
    bool IsPointerButtonDown(int button);
}

public interface IRenderer : IDisposable
{
    string BackendName { get; }
    void BeginFrame(Vector4 clearColor);
    void DrawRectangle(Vector2 position, Vector2 size, Vector4 color);
    void EndFrame();
}

public sealed class ResourceRegistry
{
    private readonly Dictionary<string, object> _items = new(StringComparer.OrdinalIgnoreCase);
    public void Register<T>(string key, T resource) where T : notnull
    { if (string.IsNullOrWhiteSpace(key)) throw new ArgumentException("Resource key required.", nameof(key)); ArgumentNullException.ThrowIfNull(resource); _items[key] = resource; }
    public bool TryGet<T>(string key, out T? resource)
    { if (_items.TryGetValue(key, out var item) && item is T value) { resource = value; return true; } resource = default; return false; }
    public bool Remove(string key) => _items.Remove(key);
    public IReadOnlyCollection<string> Keys => _items.Keys;
}

public sealed record EntityDocument(string Name, float X = 0, float Y = 0, float Rotation = 0, float ScaleX = 1, float ScaleY = 1);
public sealed record SceneDocument(string Name, IReadOnlyList<EntityDocument> Entities);
public static class SceneSerializer
{
    private static readonly JsonSerializerOptions Options = new() { WriteIndented = true, PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
    public static string Serialize(SceneDocument scene) => JsonSerializer.Serialize(scene, Options);
    public static SceneDocument Deserialize(string json) => JsonSerializer.Deserialize<SceneDocument>(json, Options) ?? throw new InvalidDataException("Invalid scene document.");
    public static async Task SaveAsync(string path, SceneDocument scene, CancellationToken token = default)
    { var full = Path.GetFullPath(path); Directory.CreateDirectory(Path.GetDirectoryName(full)!); await File.WriteAllTextAsync(full, Serialize(scene), token); }
    public static async Task<SceneDocument> LoadAsync(string path, CancellationToken token = default) => Deserialize(await File.ReadAllTextAsync(path, token));
}
