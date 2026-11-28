using Godot;
using System;
using System.Collections.Generic;

public partial class Main : Node3D
{
    private CharacterBody3D _player = null!;
    private Camera3D _camera = null!;
    private DirectionalLight3D _sun = null!;
    private Label _hud = null!;
    private readonly List<(Node3D Node, string Kind)> _resources = new();
    private readonly Random _random = new();
    private int _wood, _stone, _food = 3, _health = 100, _day = 1;
    private double _hunger = 100, _dayClock;
    private string _message = "Исследуй остров. WASD — движение · E — собрать · F — поесть · C — укрытие.";

    public override void _Ready()
    {
        BuildWorld();
        BuildPlayer();
        BuildHud();
        if (!LoadSave()) PopulateResources();
        UpdateHud();
    }

    private void BuildWorld()
    {
        var environment = new WorldEnvironment();
        environment.Environment = new Godot.Environment
        {
            BackgroundMode = Godot.Environment.BGMode.Color,
            BackgroundColor = new Color("#8ab9d4"),
            AmbientLightSource = Godot.Environment.AmbientSource.Color,
            AmbientLightColor = new Color("#b8cbd8"),
            AmbientLightEnergy = 0.7f
        };
        AddChild(environment);

        _sun = new DirectionalLight3D { RotationDegrees = new Vector3(-48, -32, 0), LightEnergy = 1.15f, ShadowEnabled = true };
        AddChild(_sun);

        var floor = new StaticBody3D { Position = new Vector3(0, -0.3f, 0) };
        var floorMesh = new MeshInstance3D { Mesh = new PlaneMesh { Size = new Vector2(80, 80) } };
        floorMesh.MaterialOverride = Material("#477a52");
        floor.AddChild(floorMesh);
        var floorCollision = new CollisionShape3D { Shape = new BoxShape3D { Size = new Vector3(80, 0.6f, 80) } };
        floor.AddChild(floorCollision);
        AddChild(floor);

        for (int i = 0; i < 10; i++)
        {
            var rock = new MeshInstance3D { Mesh = new SphereMesh { Radius = 0.55f, Height = 1.0f }, Position = new Vector3((i - 5) * 5, 0.35f, -12 + (i % 3) * 8) };
            rock.Scale = new Vector3(1.2f, 0.7f, 1.0f);
            rock.MaterialOverride = Material("#89939c");
            AddChild(rock);
        }
    }

    private void BuildPlayer()
    {
        _player = new CharacterBody3D { Position = new Vector3(0, 1.0f, 0) };
        var collider = new CollisionShape3D { Shape = new CapsuleShape3D { Radius = 0.45f, Height = 1.8f }, Position = new Vector3(0, 0.9f, 0) };
        _player.AddChild(collider);
        var body = new MeshInstance3D { Mesh = new CapsuleMesh { Radius = 0.45f, Height = 1.8f }, Position = new Vector3(0, 0.9f, 0) };
        body.MaterialOverride = Material("#e9c46a");
        _player.AddChild(body);

        _camera = new Camera3D { Position = new Vector3(0, 6.5f, 10.5f), Current = true, Fov = 70 };
        _player.AddChild(_camera);
        _camera.LookAt(new Vector3(0, 1, -3), Vector3.Up);
        AddChild(_player);
    }

    private void BuildHud()
    {
        var layer = new CanvasLayer();
        AddChild(layer);
        var panel = new PanelContainer { Position = new Vector2(16, 16), CustomMinimumSize = new Vector2(650, 120) };
        layer.AddChild(panel);
        _hud = new Label { AutowrapMode = TextServer.AutowrapMode.WordSmart };
        _hud.AddThemeFontSizeOverride("font_size", 17);
        _hud.AddThemeColorOverride("font_color", Colors.White);
        panel.AddChild(_hud);
        var credit = new Label { Text = "Created by OTKAT Games · 3D survival prototype", Position = new Vector2(18, 690) };
        credit.AddThemeFontSizeOverride("font_size", 12);
        credit.AddThemeColorOverride("font_color", Colors.White);
        layer.AddChild(credit);
    }

    private void PopulateResources()
    {
        for (int i = 0; i < 48; i++)
        {
            var x = _random.Next(-28, 29);
            var z = _random.Next(-28, 29);
            if (Math.Abs(x) < 5 && Math.Abs(z) < 5) continue;
            var kind = new[] { "tree", "rock", "berry" }[_random.Next(3)];
            var node = new Node3D { Position = new Vector3(x, 0, z) };
            if (kind == "tree")
            {
                var trunk = new MeshInstance3D { Mesh = new CylinderMesh { TopRadius = 0.18f, BottomRadius = 0.28f, Height = 2.0f }, Position = new Vector3(0, 1, 0), MaterialOverride = Material("#79533a") };
                node.AddChild(trunk);
                var leaves = new MeshInstance3D { Mesh = new SphereMesh { Radius = 1.0f, Height = 2.0f }, Position = new Vector3(0, 2.2f, 0), MaterialOverride = Material("#2f8f58") };
                node.AddChild(leaves);
            }
            else
            {
                var mesh = new MeshInstance3D { Mesh = new SphereMesh { Radius = kind == "rock" ? 0.65f : 0.38f, Height = 1.0f }, Position = new Vector3(0, 0.45f, 0), MaterialOverride = Material(kind == "rock" ? "#929da8" : "#c85b77") };
                mesh.Scale = kind == "rock" ? new Vector3(1.3f, 0.8f, 1.0f) : Vector3.One;
                node.AddChild(mesh);
            }
            AddChild(node);
            _resources.Add((node, kind));
        }
    }

    private static StandardMaterial3D Material(string color) => new() { AlbedoColor = new Color(color), Roughness = 0.92f };

    public override void _PhysicsProcess(double delta)
    {
        var direction = Vector3.Zero;
        if (Input.IsKeyPressed(Key.W) || Input.IsKeyPressed(Key.Up)) direction.Z -= 1;
        if (Input.IsKeyPressed(Key.S) || Input.IsKeyPressed(Key.Down)) direction.Z += 1;
        if (Input.IsKeyPressed(Key.A) || Input.IsKeyPressed(Key.Left)) direction.X -= 1;
        if (Input.IsKeyPressed(Key.D) || Input.IsKeyPressed(Key.Right)) direction.X += 1;
        if (direction.LengthSquared() > 0) direction = direction.Normalized();
        _player.Velocity = new Vector3(direction.X * 6.0f, _player.Velocity.Y, direction.Z * 6.0f);
        if (!_player.IsOnFloor()) _player.Velocity += Vector3.Down * 22.0f * (float)delta;
        _player.MoveAndSlide();
        _player.Position = new Vector3(Mathf.Clamp(_player.Position.X, -36, 36), _player.Position.Y, Mathf.Clamp(_player.Position.Z, -36, 36));
        _camera.LookAt(_player.Position + new Vector3(0, 0.6f, -3), Vector3.Up);
    }

    public override void _Process(double delta)
    {
        _dayClock += delta;
        _hunger = Math.Max(0, _hunger - delta * 0.35);
        if (_hunger <= 0) _health = Math.Max(0, _health - (int)Math.Ceiling(delta * 1.5));
        if (_dayClock >= 120)
        {
            _dayClock = 0;
            _day++;
            _hunger = Math.Max(0, _hunger - 7);
            _message = $"Наступил день {_day}. Пополни запасы еды.";
            SaveGame();
        }
        _sun.RotationDegrees = new Vector3(-48 + (float)(_dayClock / 120.0 * 360.0), -32, 0);
        UpdateHud();
    }

    public override void _UnhandledKeyInput(InputEvent e)
    {
        if (e is not InputEventKey key || !key.Pressed || key.Echo) return;
        if (key.Keycode == Key.E) Gather();
        else if (key.Keycode == Key.F) Eat();
        else if (key.Keycode == Key.C) CraftShelter();
    }

    private void Gather()
    {
        var index = _resources.FindIndex(r => r.Node.GlobalPosition.DistanceTo(_player.GlobalPosition) < 2.4f);
        if (index < 0) { _message = "Подойди ближе к дереву, камню или ягодам."; return; }
        var item = _resources[index];
        if (item.Kind == "tree") { _wood++; _message = "Собрано дерево."; }
        else if (item.Kind == "rock") { _stone++; _message = "Собран камень."; }
        else { _food++; _message = "Собраны ягоды."; }
        item.Node.QueueFree();
        _resources.RemoveAt(index);
        SaveGame();
    }

    private void Eat()
    {
        if (_food <= 0) { _message = "Еды нет. Найди кусты с ягодами."; return; }
        _food--;
        _hunger = Math.Min(100, _hunger + 35);
        _message = "Ты поел. Голод уменьшился.";
        SaveGame();
    }

    private void CraftShelter()
    {
        if (_wood < 3 || _stone < 2) { _message = "Для укрытия нужно 3 дерева и 2 камня."; return; }
        _wood -= 3;
        _stone -= 2;
        _health = Math.Min(100, _health + 25);
        var shelter = new MeshInstance3D { Mesh = new BoxMesh { Size = new Vector3(2.5f, 1.8f, 2.5f) }, Position = _player.Position + new Vector3(3, 0.9f, 0), MaterialOverride = Material("#9c714a") };
        AddChild(shelter);
        _message = "Построено укрытие. Здоровье восстановлено.";
        SaveGame();
    }

    private void UpdateHud() => _hud.Text = $"OTKAT SURVIVAL · 3D\nДень {_day} · Здоровье {_health} · Голод {(int)_hunger}\nДерево {_wood} · Камень {_stone} · Еда {_food}\n{_message}\nWASD/стрелки — движение · E — собрать · F — поесть · C — укрытие";

    private void SaveGame()
    {
        var cfg = new ConfigFile();
        cfg.SetValue("player", "x", _player.Position.X);
        cfg.SetValue("player", "z", _player.Position.Z);
        cfg.SetValue("stats", "wood", _wood);
        cfg.SetValue("stats", "stone", _stone);
        cfg.SetValue("stats", "food", _food);
        cfg.SetValue("stats", "health", _health);
        cfg.SetValue("stats", "hunger", _hunger);
        cfg.SetValue("stats", "day", _day);
        cfg.Save("user://otkat-survival.cfg");
    }

    private bool LoadSave()
    {
        var cfg = new ConfigFile();
        if (cfg.Load("user://otkat-survival.cfg") != Error.Ok) return false;
        _player.Position = new Vector3((float)cfg.GetValue("player", "x", 0.0), 1.0f, (float)cfg.GetValue("player", "z", 0.0));
        _wood = (int)cfg.GetValue("stats", "wood", 0);
        _stone = (int)cfg.GetValue("stats", "stone", 0);
        _food = (int)cfg.GetValue("stats", "food", 3);
        _health = Math.Clamp((int)cfg.GetValue("stats", "health", 100), 0, 100);
        _hunger = Math.Clamp((double)cfg.GetValue("stats", "hunger", 100.0), 0, 100);
        _day = Math.Max(1, (int)cfg.GetValue("stats", "day", 1));
        return true;
    }

    public override void _Notification(int what)
    {
        if (what == NotificationWMCloseRequest || what == NotificationPredelete) SaveGame();
    }
}
