using Otkat.Engine;
using System.Numerics;

var scene = new Scene { Name = "Starter Scene" };
var player = scene.CreateEntity("Player");
player.Transform.Position = new Vector2(100, 80);
player.Add(new MovementProbe());
var host = new EngineHost(scene);
var frames = 0;
host.FrameUpdated += _ => frames++;
host.RunFor(TimeSpan.FromMilliseconds(120));
Console.WriteLine($"OTKAT Engine runtime smoke test: scene={host.CurrentScene.Name}, entities={scene.Entities.Count}, frames={frames}");
if (frames == 0 || player.Get<MovementProbe>() is null) Environment.ExitCode = 1;
sealed class MovementProbe : Component
{
    public override void Update(in EngineTime time) { if (Owner is not null) Owner.Transform.Position += new Vector2(10 * (float)time.DeltaSeconds, 0); }
}