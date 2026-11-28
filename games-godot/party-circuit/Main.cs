using Godot;
using System;
using System.Collections.Generic;
using System.Linq;

public partial class Main : Control
{
    private readonly int[] _scores = new int[4];
    private int _players = 2, _round = 1, _task;
    private bool _roundOpen;
    private Label _prompt = null!, _status = null!, _score = null!;
    private readonly List<Button> _playerButtons = new();

    public override void _Ready() { BuildUi(); NewRound(); }

    private void BuildUi()
    {
        var bg = new ColorRect { Color = new Color("#101525") };
        bg.SetAnchorsAndOffsetsPreset(Control.LayoutPreset.FullRect);
        AddChild(bg);
        var root = new VBoxContainer { Position = new Vector2(32, 24), Size = new Vector2(1216, 672), Theme = new Theme() };
        root.AddThemeConstantOverride("separation", 14);
        AddChild(root);
        var title = new Label { Text = "OTKAT PARTY CIRCUIT" };
        title.AddThemeFontSizeOverride("font_size", 34);
        title.AddThemeColorOverride("font_color", new Color("#9fe8cf"));
        root.AddChild(title);
        root.AddChild(new Label { Text = "Локальная вечеринка · 2–4 игрока · раунды и общий счёт" });
        var settings = new HBoxContainer();
        settings.AddChild(new Label { Text = "Игроков:" });
        var count = new OptionButton();
        for (int n = 2; n <= 4; n++) count.AddItem(n.ToString(), n);
        count.Select(0);
        count.ItemSelected += index => { _players = (int)index + 2; NewRound(); };
        settings.AddChild(count); root.AddChild(settings);
        _prompt = new Label { CustomMinimumSize = new Vector2(0, 170), AutowrapMode = TextServer.AutowrapMode.WordSmart };
        _prompt.AddThemeFontSizeOverride("font_size", 24); root.AddChild(_prompt);
        _status = new Label(); root.AddChild(_status);
        var grid = new GridContainer { Columns = 2, SizeFlagsVertical = Control.SizeFlags.ExpandFill };
        root.AddChild(grid);
        for (int i = 0; i < 4; i++)
        {
            int player = i;
            var button = new Button { CustomMinimumSize = new Vector2(260, 100) };
            button.AddThemeFontSizeOverride("font_size", 22);
            button.Pressed += () => Claim(player);
            grid.AddChild(button); _playerButtons.Add(button);
        }
        _score = new Label(); _score.AddThemeFontSizeOverride("font_size", 18); root.AddChild(_score);
        var next = new Button { Text = "Следующий раунд", CustomMinimumSize = new Vector2(0, 48) };
        next.Pressed += NewRound; root.AddChild(next);
    }

    private void NewRound()
    {
        _roundOpen = true;
        _task = (_round - 1) % 4;
        string[] titles = { "РЕАКЦИЯ", "СЧЁТ НА СКОРОСТЬ", "ПАМЯТЬ", "ВНИМАТЕЛЬНОСТЬ" };
        string[] prompts = {
            "Кто первым нажмёт свою кнопку — получает очко.",
            "Реши пример на экране. Первый правильный ответ приносит очко.",
            "Запомни последовательность цветов и повтори её вслух.",
            "Найди нужный символ среди отвлекающих знаков."
        };
        string challenge = "";
        if (_task == 1) { int a = GD.RandRange(3, 18), b = GD.RandRange(2, 12); challenge = $"\n\nСколько будет {a} × {b}?"; _prompt.SetMeta("answer", a * b); }
        else if (_task == 2) { challenge = "\n\n🟦  🟨  🟥  🟩  🟦"; _prompt.SetMeta("answer", -1); }
        else if (_task == 3) { challenge = "\n\nНайди три одинаковых знака: ▲ ◆ ▲ ● ▲"; _prompt.SetMeta("answer", -1); }
        else _prompt.SetMeta("answer", -1);
        _prompt.Text = $"{titles[_task]}\n{prompts[_task]}{challenge}";
        _status.Text = $"Раунд {_round} · Первый нажавший получает очко";
        for (int i = 0; i < 4; i++) { _playerButtons[i].Visible = i < _players; _playerButtons[i].Disabled = false; _playerButtons[i].Text = $"ИГРОК {i + 1}\nНАЖАТЬ"; }
        UpdateScores();
    }

    private void Claim(int player)
    {
        if (!_roundOpen || player >= _players) return;
        _roundOpen = false; _scores[player]++;
        _status.Text = $"Раунд забрал игрок {player + 1}!";
        foreach (var button in _playerButtons) button.Disabled = true;
        _round++; UpdateScores();
    }

    private void UpdateScores() => _score.Text = string.Join("     ", Enumerable.Range(0, _players).Select(i => $"Игрок {i + 1}: {_scores[i]}"));
}
