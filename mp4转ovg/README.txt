MP4 / MOV -> OGV (for Godot)
============================

What it does
------------
Converts video to .ogv (Theora + Vorbis) so Godot VideoStreamPlayer can play it.
Output is next to the source file with the same name, .ogv extension.
Existing .ogv files are skipped (safe to re-run).

How to use
----------
1. Install FFmpeg (essentials build is enough):
   https://www.gyan.dev/ffmpeg/builds/
   Unzip, then either:
   - Add the bin folder to system PATH, or
   - Edit FfmpegFallback in mp4_to_ogv.ps1 to your ffmpeg.exe full path

2. Drag one or more .mp4 / .mov files onto mp4_to_ogv.bat
   Or drag a whole folder (it converts recursively).

3. Put the .ogv under your Godot project (res://), assign to VideoStreamPlayer.stream

Command line
------------
  mp4_to_ogv.bat "D:\videos\clip.mp4"
  powershell -File mp4_to_ogv.ps1 "D:\videos\folder"

Notes
-----
- Renaming .mp4 to .ogv does NOT work; this tool re-encodes.
- Green-screen keying is a separate Shader on VideoStreamPlayer, not this tool.
