using Godot;
using System;
using System.Collections.Generic;
using System.Linq;

public partial class Main : Control
{
    private sealed record Place(string City, string Country, string Clue, string Region);
    private readonly Place[] _places =
    {
        new("Хельсинки", "Финляндия", "Трамваи, северная архитектура и финские слова на вывесках", "Европа"),
        new("Токио", "Япония", "Плотная городская застройка, японская письменность и автоматы с напитками", "Азия"),
        new("Каир", "Египет", "Арабские вывески, сухой климат и пальмы вдоль улиц", "Африка"),
        new("Буэнос-Айрес", "Аргентина", "Испанские вывески, широкие проспекты и платаны", "Южная Америка"),
        new("Рейкьявик", "Исландия", "Скандинавские надписи, вулканические пейзажи и яркие крыши", "Европа"),
        new("Ванкувер", "Канада", "Английские и французские надписи, горы у океана и хвойные леса", "Северная Америка"),
        new("Марракеш", "Марокко", "Арабские и французские вывески, медина и охристые стены", "Африка"),
        new("Сеул", "Южная Корея", "Корейский хангыль, горные силуэты и современные высотки", "Азия")
    };

    private readonly RandomNumberGenerator _rng = new();
    private Label _round = null!;
    private Label _clue = null!;
    private Label _feedback = null!;
    private Label _score = null!;
    private VBoxContainer _answers = null!;
    private Button _next = null!;
    private Place? _current;
    private int _roundNumber;
    private int _points;
    private bool _answered;
    private bool _finished;

    public override void _Ready()
    {
        BuildUi();
        StartRound();
    }

    private void BuildUi()
    {
        var background = new ColorRect { Color = new Color("#101827") };
        background.SetAnchorsAndOffsetsPreset(Control.LayoutPreset.FullRect);
        AddChild(background);

        var center = new CenterContainer();
        center.SetAnchorsAndOffsetsPreset(Control.LayoutPreset.FullRect);
        AddChild(center);

        var panel = new PanelContainer { CustomMinimumSize = new Vector2(640, 0) };
        center.AddChild(panel);
        var layout = new VBoxContainer();
        layout.AddThemeConstantOverride("separation", 14);
        panel.AddChild(layout);

        var title = new Label { Text = "OTKAT · WORLD DETECTIVE", HorizontalAlignment = HorizontalAlignment.Center };
        title.AddThemeFontSizeOverride("font_size", 28);
        layout.AddChild(title);
        _round = new Label { HorizontalAlignment = HorizontalAlignment.Center };
        layout.AddChild(_round);
        var intro = new Label { Text = "Определи город по подсказкам. За верный ответ — 100 очков.", HorizontalAlignment = HorizontalAlignment.Center, AutowrapMode = TextServer.AutowrapMode.WordSmart };
        layout.AddChild(intro);
        _clue = new Label { AutowrapMode = TextServer.AutowrapMode.WordSmart, CustomMinimumSize = new Vector2(560, 100), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
        _clue.AddThemeFontSizeOverride("font_size", 20);
        layout.AddChild(_clue);
        _answers = new VBoxContainer();
        _answers.AddThemeConstantOverride("separation", 8);
        layout.AddChild(_answers);
        _feedback = new Label { HorizontalAlignment = HorizontalAlignment.Center, AutowrapMode = TextServer.AutowrapMode.WordSmart };
        layout.AddChild(_feedback);
        _score = new Label { HorizontalAlignment = HorizontalAlignment.Center };
        layout.AddChild(_score);
        _next = new Button { Text = "Следующая локация", CustomMinimumSize = new Vector2(0, 48), Disabled = true };
        _next.Pressed += Advance;
        layout.AddChild(_next);
        var credit = new Label { Text = "Created by OTKAT Games · Offline prototype", HorizontalAlignment = HorizontalAlignment.Center };
        credit.AddThemeFontSizeOverride("font_size", 11);
        layout.AddChild(credit);
    }

    private void StartRound()
    {
        if (_roundNumber >= 5)
        {
            _finished = true;
            _round.Text = "Экспедиция завершена";
            _clue.Text = $"Итоговый результат: {_points} из 500 очков.";
            _answers.Visible = false;
            _feedback.Text = "Ты прошёл первый маршрут World Detective.";
            _next.Text = "Начать заново";
            _next.Disabled = false;
            return;
        }

        _finished = false;
        _roundNumber++;
        _answered = false;
        _current = _places[_rng.RandiRange(0, _places.Length - 1)];
        _round.Text = $"Маршрут · раунд {_roundNumber}/5";
        _clue.Text = _current.Clue + $"\n\nРегион: {_current.Region}. Какой это город?";
        _feedback.Text = "";
        _score.Text = $"Очки: {_points}";
        _next.Text = "Следующая локация";
        _next.Disabled = true;
        _answers.Visible = true;
        foreach (Node child in _answers.GetChildren()) child.QueueFree();

        var choices = new List<Place> { _current };
        while (choices.Count < 4)
        {
            var candidate = _places[_rng.RandiRange(0, _places.Length - 1)];
            if (!choices.Any(p => p.City == candidate.City)) choices.Add(candidate);
        }
        choices = choices.OrderBy(_ => _rng.Randf()).ToList();
        foreach (var place in choices)
        {
            var button = new Button { Text = place.City, CustomMinimumSize = new Vector2(0, 46) };
            button.Pressed += () => Choose(place);
            _answers.AddChild(button);
        }
    }

    private void Choose(Place choice)
    {
        if (_answered || _current is null) return;
        _answered = true;
        foreach (Button button in _answers.GetChildren().OfType<Button>()) button.Disabled = true;
        if (choice.City == _current.City)
        {
            _points += 100;
            _feedback.Text = $"Верно! {_current.City}, {_current.Country}. +100";
        }
        else
        {
            _feedback.Text = $"Пока нет. Это {_current.City}, {_current.Country}.";
        }
        _score.Text = $"Очки: {_points}";
        _next.Disabled = false;
    }

    private void Advance()
    {
        if (_finished)
        {
            _roundNumber = 0;
            _points = 0;
        }
        StartRound();
    }
}