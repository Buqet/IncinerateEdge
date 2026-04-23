
import winim/lean, os, strutils, registry

proc killEdgeProcesses: bool =
  result = true

proc removeEdgeFiles: bool =
  # C:\Program Files (x86)\Microsoft\Edge
  # C:\Program Files (x86)\Microsoft\EdgeUpdate
  # C:\ProgramData\Microsoft\Edge
  result = true

proc removeEdgeUserData: bool =
  # C:\Users\%USERNAME%\AppData\Local\Microsoft\Edge
  # C:\Users\%USERNAME%\AppData\Roaming\Microsoft\Edge

proc cleanEdgeRegistry: bool =
  # HKLM\Software\Microsoft\Edge*
  # HKLM\Software\WOW6432Node\Microsoft\Edge*
  # HKCU\Software\Microsoft\Edge*
  let keys = [
    "HKLM\\Software\\Microsoft\\Edge",
    "HKLM\\Software\\WOW6432Node\\Microsoft\\Edge",
    "HKCU\\Software\\Microsoft\\Edge",
    "HKCU\\Software\\Microsoft\\EdgeUpdate",
    "HKLM\\Software\\Microsoft\\EdgeUpdate"
  ]
  for k in keys:
    discard regDeleteKey(k)

# proc removeWebView2: bool =

proc burnEverything(callback: proc(phase: string, percent: int)) =
  callback("Уничтожение процессов...", 5)
  if not killEdgeProcesses(): callback("Предупреждение: не все процессы убиты", 5)
  callback("Удаление бинарников...", 20)
  removeEdgeFiles()
  callback("Очистка пользовательских данных...", 45)
  removeEdgeUserData()
  callback("Зачистка реестра...", 70)
  cleanEdgeRegistry()
  callback("WebView2 (опционально)", 90)
  removeWebView2()
  callback("Готово!", 100)