# OTKAT World Detective

A first native Godot 4 .NET/C# prototype for Android and Windows.

## Included in this first slice
- Five-round offline city-guessing session.
- Eight original location clue sets across five continents.
- Four answer choices per round, immediate feedback and score.
- Restartable session and responsive Control-based UI.
- No external map tiles, Street View imagery, account, network or location permission.

## Current limitations
This is a playable vertical slice, not a GeoGuessr-equivalent release. It does not yet include real street panoramas, map navigation, multiplayer, daily challenges, user maps, cloud accounts or installers. Those require licensed/authorized geography imagery and further platform testing.

Open project.godot with Godot 4.4.1 .NET. Build with:

    dotnet build OTKAT.WorldDetective.csproj -c Release
