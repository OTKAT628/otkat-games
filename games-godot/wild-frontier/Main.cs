using Godot;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;

public partial class Main : Node2D
{
    private const int Cell = 48, MapW = 22, MapH = 12;
    private Vector2I _player = new(10, 6);
    private readonly List<(Vector2I Pos, string Kind)> _resources = new();
    private int _wood, _stone, _food = 3, _health = 100, _day = 1;
    private double _hunger = 100, _elapsed, _moveCooldown;
    private Label _hud = null!;
    private string _message = "Исследуй остров. WASD/стрелки — движение, E — собрать, F — поесть, C — укрытие.";

    public override void _Ready()
    {
        bool loaded = LoadProgress();
        if (!loaded)
        {
            for (int i = 0; i < 45; i++)
            {
                var p = new Vector2I(GD.RandRange(1, MapW - 2), GD.RandRange(1, MapH - 2));
                if (p != _player) _resources.Add((p, new[] { "tree", "rock", "berry" }[GD.RandRange(0, 2)]));
            }
        }
        var layer = new CanvasLayer(); AddChild(layer);
        _hud = new Label { Position = new Vector2(18, 14) };
        _hud.AddThemeFontSizeOverride("font_size", 18);
        _hud.AddThemeColorOverride("font_color", Colors.White);
        layer.AddChild(_hud); UpdateHud();
    }

    public override void _Process(double delta)
    {
        _elapsed += delta; _moveCooldown = Math.Max(0, _moveCooldown - delta);
        _hunger = Math.Max(0, _hunger - delta * 0.55);
        if (_hunger <= 0) _health = Math.Max(0, _health - (int)(delta * 2));
        if (_elapsed > 90) { _day++; _elapsed = 0; _hunger = Math.Max(0, _hunger - 8); _message = $"Наступил день {_day}. Следи за запасами еды."; }
        UpdateHud(); QueueRedraw();
    }

    public override void _UnhandledKeyInput(InputEvent e)
    {
        if (e is not InputEventKey key || !key.Pressed || key.Echo) return;
        if (key.Keycode == Key.E) { Gather(); return; }
        if (key.Keycode == Key.F) { Eat(); return; }
        if (key.Keycode == Key.C) { Craft(); return; }
        if (_moveCooldown > 0) return;
        Vector2I dir = key.Keycode switch
        {
            Key.W or Key.Up => Vector2I.Up, Key.S or Key.Down => Vector2I.Down,
            Key.A or Key.Left => Vector2I.Left, Key.D or Key.Right => Vector2I.Right,
            _ => Vector2I.Zero
        };
        if (dir != Vector2I.Zero) { _player = new Vector2I(Math.Clamp(_player.X + dir.X, 0, MapW - 1), Math.Clamp(_player.Y + dir.Y, 0, MapH - 1)); _moveCooldown = 0.12; SaveProgress(); }
    }

    private void Gather()
    {
        int found = _resources.FindIndex(r => r.Pos.DistanceTo(_player) <= 1.2f);
        if (found < 0) { _message = "Рядом нет ресурса. Подойди ближе."; return; }
        var item = _resources[found];
        if (item.Kind == "tree") { _wood++; _message = "Собрано дерево."; }
        else if (item.Kind == "rock") { _stone++; _message = "Собран камень."; }
        else { _food++; _message = "Собраны ягоды."; }
        _resources.RemoveAt(found); UpdateHud(); SaveProgress();
    }
    private void Eat()
    {
        if (_food <= 0) { _message = "Еды нет. Найди кусты с ягодами."; return; }
        _food--; _hunger = Math.Min(100, _hunger + 35); _message = "Ты поел. Голод уменьшился."; SaveProgress();
    }
    private void Craft()
    {
        if (_wood >= 3 && _stone >= 2) { _wood -= 3; _stone -= 2; _health = Math.Min(100, _health + 25); _message = "Ты построил укрытие и восстановил здоровье."; SaveProgress(); }
        else _message = "Для укрытия нужно 3 дерева и 2 камня.";
    }
    private sealed record SavedResource(int X, int Y, string Kind);
    private sealed record SavedGame(int X, int Y, int Wood, int Stone, int Food, int Health, int Day, double Hunger, List<SavedResource> Resources);

    private void SaveProgress()
    {
        var snapshot = new SavedGame(_player.X, _player.Y, _wood, _stone, _food, _health, _day, _hunger,
            _resources.Select(r => new SavedResource(r.Pos.X, r.Pos.Y, r.Kind)).ToList());
        using var file = Godot.FileAccess.Open("user://wild-frontier-save.json", Godot.FileAccess.ModeFlags.Write);
        file?.StoreString(JsonSerializer.Serialize(snapshot));
    }

    private bool LoadProgress()
    {
        if (!Godot.FileAccess.FileExists("user://wild-frontier-save.json")) return false;
        try
        {
            var snapshot = JsonSerializer.Deserialize<SavedGame>(Godot.FileAccess.GetFileAsString("user://wild-frontier-save.json"));
            if (snapshot is null) return false;
            _player = new Vector2I(Math.Clamp(snapshot.X, 0, MapW - 1), Math.Clamp(snapshot.Y, 0, MapH - 1));
            _wood = Math.Max(0, snapshot.Wood); _stone = Math.Max(0, snapshot.Stone); _food = Math.Max(0, snapshot.Food);
            _health = Math.Clamp(snapshot.Health, 0, 100); _day = Math.Max(1, snapshot.Day); _hunger = Math.Clamp(snapshot.Hunger, 0, 100);
            _resources.Clear();
            foreach (var r in snapshot.Resources ?? new List<SavedResource>())
                if (r.X >= 0 && r.X < MapW && r.Y >= 0 && r.Y < MapH && (r.Kind == "tree" || r.Kind == "rock" || r.Kind == "berry"))
                    _resources.Add((new Vector2I(r.X, r.Y), r.Kind));
            return true;
        }
        catch (Exception ex) { GD.PushWarning($"Save could not be loaded: {ex.Message}"); return false; }
    }

    public override void _Notification(int what)
    {
        if (what == NotificationWMCloseRequest || what == NotificationPredelete) SaveProgress();
    }

    private void UpdateHud() => _hud.Text = $"OTKAT WILD FRONTIER   День {_day}   Здоровье {_health}   Голод {(int)_hunger}\nДерево {_wood}   Камень {_stone}   Еда {_food}\n{_message}\nE — собрать   F — поесть   C — построить укрытие";

    public override void _Draw()
    {
        var origin = new Vector2(24, 112);
        for (int y = 0; y < MapH; y++)
            for (int x = 0; x < MapW; x++)
                DrawRect(new Rect2(origin + new Vector2(x * Cell, y * Cell), new Vector2(Cell - 2, Cell - 2)), (x + y) % 2 == 0 ? new Color("#315a49") : new Color("#294f40"));
        foreach (var item in _resources)
        {
            var p = origin + new Vector2(item.Pos.X * Cell + Cell / 2f, item.Pos.Y * Cell + Cell / 2f);
            DrawCircle(p, 13, item.Kind == "rock" ? new Color("#a5abb4") : item.Kind == "berry" ? new Color("#d66a88") : new Color("#4aa66a"));
        }
        var player = origin + new Vector2(_player.X * Cell + Cell / 2f, _player.Y * Cell + Cell / 2f);
        DrawCircle(player, 15, new Color("#f4d36d")); DrawCircle(player, 5, new Color("#fff4d0"));
    }
}
