using Otkat.Engine;

if (args.Length == 0 || args[0] is "--help" or "-h")
{
    Console.WriteLine("OTKAT Engine project/scene inspector");
    Console.WriteLine("Usage: otkat-editor <project-directory | scene.json>");
    return;
}
var target = Path.GetFullPath(args[0]);
if (File.Exists(target) && target.EndsWith(".json", StringComparison.OrdinalIgnoreCase))
{
    try { var scene = await SceneSerializer.LoadAsync(target); Console.WriteLine($"Scene: {scene.Name}\nEntities: {scene.Entities.Count}"); foreach (var e in scene.Entities) Console.WriteLine($" - {e.Name} at ({e.X}, {e.Y})"); }
    catch (Exception ex) { Console.Error.WriteLine($"Invalid scene: {ex.Message}"); Environment.ExitCode = 1; }
    return;
}
var meta = Path.Combine(target, "otkat.project.json");
if (!Directory.Exists(target) || !File.Exists(meta)) { Console.Error.WriteLine("Project directory or otkat.project.json not found."); Environment.ExitCode = 2; return; }
Console.WriteLine(await File.ReadAllTextAsync(meta));