@echo off
set NIMFLAGS=-d:release --app:gui --opt:speed
nim c %NIMFLAGS% -o:bin\IncinerateEdge.exe src\incinerateedge.nim
echo Build complete: bin\IncinerateEdge.exe
pause