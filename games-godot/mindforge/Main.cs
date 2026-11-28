using Godot;
using System;

public partial class Main : Control
{
    private int _level = 1;
    private int _points;
    private int _expected;
    private Label _question = null!;
    private LineEdit _answer = null!;
    private Label _feedback = null!;
    private Label _progress = null!;
    private string _hint = "";

    public override void _Ready()
    {
        BuildUi();
        NewPuzzle();
    }

    private void BuildUi()
    {
        var bg = new ColorRect { Color = new Color("#111827") };
        bg.SetAnchorsAndOffsetsPreset(Control.LayoutPreset.FullRect);
        AddChild(bg);

        var panel = new VBoxContainer { OffsetLeft = 36, OffsetTop = 28, OffsetRight = -36, OffsetBottom = -28 };
        panel.SetAnchorsAndOffsetsPreset(Control.LayoutPreset.FullRect);
        panel.AddThemeConstantOverride("separation", 18);
        AddChild(panel);

        var title = new Label { Text = "OTKAT MINDFORGE" };
        title.AddThemeFontSizeOverride("font_size", 36);
        title.AddThemeColorOverride("font_color", new Color("#a5c8ff"));
        panel.AddChild(title);
        panel.AddChild(new Label { Text = "Логическая кампания · числа · закономерности · память · шифры" });

        _progress = new Label();
        _progress.AddThemeFontSizeOverride("font_size", 18);
        panel.AddChild(_progress);

        _question = new Label { CustomMinimumSize = new Vector2(0, 190), AutowrapMode = TextServer.AutowrapMode.WordSmart };
        _question.AddThemeFontSizeOverride("font_size", 30);
        panel.AddChild(_question);

        _answer = new LineEdit { PlaceholderText = "Твой ответ", CustomMinimumSize = new Vector2(0, 58) };
        _answer.AddThemeFontSizeOverride("font_size", 22);
        _answer.TextSubmitted += _ => CheckAnswer();
        panel.AddChild(_answer);

        var actions = new HBoxContainer();
        panel.AddChild(actions);
        var submit = new Button { Text = "Проверить ответ", CustomMinimumSize = new Vector2(220, 54) };
        submit.Pressed += CheckAnswer;
        actions.AddChild(submit);
        var hint = new Button { Text = "Подсказка", CustomMinimumSize = new Vector2(150, 54) };
        hint.Pressed += () => _feedback.Text = _hint;
        actions.AddChild(hint);

        _feedback = new Label();
        _feedback.AddThemeFontSizeOverride("font_size", 20);
        panel.AddChild(_feedback);
    }

    private void NewPuzzle()
    {
        _progress.Text = $"Уровень {_level} / 30     Очки: {_points}";
        _answer.Text = "";
        _feedback.Text = "";
        var a = GD.RandRange(3, 14);
        var b = GD.RandRange(2, 9);
        switch ((_level - 1) % 6)
        {
            case 0:
                _expected = a * b;
                _question.Text = $"ЧИСЛОВАЯ МАШИНА\n\n{a} × {b} = ?";
                _hint = $"Умножь {a} на {b}.";
                break;
            case 1:
                _expected = a + b * 2;
                _question.Text = $"ДВОЙНОЙ ШАГ\n\n{a}, {a + b}, {a + 2 * b}, ?";
                _hint = $"Каждый раз прибавляется {b}.";
                break;
            case 2:
                _expected = 36;
                _question.Text = "КВАДРАТЫ\n\n1, 4, 9, 16, 25, ?";
                _hint = "Это квадраты натуральных чисел.";
                break;
            case 3:
                _expected = a - b;
                _question.Text = $"БАЛАНС\n\nНа складе {a} кристаллов. Потратили {b}. Сколько осталось?";
                _hint = "Вычти потраченное из начального количества.";
                break;
            case 4:
                _expected = a + b;
                _question.Text = $"КОД ДОСТУПА\n\nПервая цифра {a}, вторая {b}. Введи их сумму.";
                _hint = "Сложи две цифры.";
                break;
            default:
                _expected = a * 2 + b;
                _question.Text = $"СИГНАЛ\n\nЕсли A={a}, B={b}, вычисли 2A+B.";
                _hint = "Сначала удвой A, затем прибавь B.";
                break;
        }
        _feedback.Text = "Реши задачу и введи целое число.";
    }

    private void CheckAnswer()
    {
        if (!int.TryParse(_answer.Text.Trim(), out var value))
        {
            _feedback.Text = "Введи целое число.";
            return;
        }
        if (value != _expected)
        {
            _feedback.Text = "Пока неверно. Попробуй ещё раз.";
            return;
        }
        _points += 10;
        _level++;
        if (_level > 30)
        {
            _question.Text = "КАМПАНИЯ ПРОЙДЕНА!\n\nТы решил все 30 задач.";
            _feedback.Text = $"Итог: {_points} очков. Нажми «Новая кампания», чтобы начать заново.";
            var restart = new Button { Text = "Новая кампания" };
            restart.Pressed += () => { _level = 1; _points = 0; restart.QueueFree(); NewPuzzle(); };
            AddChild(restart);
            return;
        }
        _feedback.Text = "Верно! +10 очков.";
        NewPuzzle();
    }
}