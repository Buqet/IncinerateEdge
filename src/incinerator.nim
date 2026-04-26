import winim/lean, os, strutils, times

proc removeDirRecursively(path: string): bool =
  let wpath = (path & "\0").WideCString
  var shfo: SHFILEOPSTRUCTW
  shfo.wFunc = FO_DELETE
  shfo.pFrom = wpath
  shfo.fFlags = FOF_SILENT or FOF_NOCONFIRMATION or FOF_NOERRORUI
  result = SHFileOperationW(addr shfo) == 0

proc regDeleteTree(hKey: HKEY, subKey: string): bool =
  var key: HKEY
  if RegOpenKeyExW(hKey, subKey, 0, KEY_ALL_ACCESS, addr key) == ERROR_SUCCESS:
    discard RegDeleteTreeW(key, nil)
    RegCloseKey(key)
    result = true
  else:
    result = false

proc runCmd(cmd: string): bool =
  var si: STARTUPINFOW
  var pi: PROCESS_INFORMATION
  si.cb = sizeof(si).cint
  let cmdW = cmd.WideCString
  result = CreateProcessW(nil, cmdW, nil, nil, FALSE, CREATE_NO_WINDOW,
                          nil, nil, addr si, addr pi)
  if result:
    WaitForSingleObject(pi.hProcess, 30000)
    CloseHandle(pi.hProcess)
    CloseHandle(pi.hThread)

proc killEdgeProcesses*(): bool =
  let procsToKill = ["msedge.exe", "MicrosoftEdgeUpdate.exe", "msedgewebview2.exe"]
  echo "[+] Останавливаем процессы Edge..."
  for p in procsToKill:
    let cmd = &"taskkill /F /IM {p} 2>nul"
    discard runCmd(cmd)
  # Резервное убийство через snapshot
  var entry: PROCESSENTRY32W
  entry.dwSize = sizeof(entry).DWORD
  let hSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
  if hSnap != INVALID_HANDLE_VALUE:
    if Process32FirstW(hSnap, addr entry):
      while true:
        let name = $entry.szExeFile
        if name.toLowerAscii() in procsToKill:
          let hProc = OpenProcess(PROCESS_TERMINATE, FALSE, entry.th32ProcessID)
          if hProc != nil:
            discard TerminateProcess(hProc, 1)
            CloseHandle(hProc)
        if not Process32NextW(hSnap, addr entry): break
    CloseHandle(hSnap)
  result = true

proc removeEdgeFiles*(): bool =
  let folders = [
    r"C:\Program Files (x86)\Microsoft\Edge",
    r"C:\Program Files (x86)\Microsoft\EdgeUpdate",
    r"C:\ProgramData\Microsoft\Edge"
  ]
  echo "[+] Удаляем системные папки Edge..."
  for f in folders:
    if dirExists(f):
      echo "    Удаление: ", f
      discard removeDirRecursively(f)
  result = true

proc removeEdgeUserData*(): bool =
  let userFolders = [
    getEnv("LOCALAPPDATA") & r"\Microsoft\Edge",
    getEnv("APPDATA") & r"\Microsoft\Edge",
    getEnv("USERPROFILE") & r"\AppData\Local\Microsoft\Edge",
    getEnv("USERPROFILE") & r"\AppData\Roaming\Microsoft\Edge"
  ]
  echo "[+] Удаляем пользовательские данные Edge..."
  for f in userFolders:
    if dirExists(f):
      echo "    Удаление: ", f
      discard removeDirRecursively(f)
  result = true

proc cleanEdgeRegistry*(): bool =
  let rootKeys = [
    (HKEY_LOCAL_MACHINE, r"Software\Microsoft\Edge"),
    (HKEY_LOCAL_MACHINE, r"Software\Microsoft\EdgeUpdate"),
    (HKEY_LOCAL_MACHINE, r"Software\WOW6432Node\Microsoft\Edge"),
    (HKEY_LOCAL_MACHINE, r"Software\WOW6432Node\Microsoft\EdgeUpdate"),
    (HKEY_CURRENT_USER,  r"Software\Microsoft\Edge"),
    (HKEY_CURRENT_USER,  r"Software\Microsoft\EdgeUpdate")
  ]
  echo "[+] Очищаем реестр..."
  for (root, sub) in rootKeys:
    echo "    Удаление ключа: ", sub
    discard regDeleteTree(root, sub)

  echo "[+] Удаляем задачи планировщика..."
  discard runCmd("schtasks /Delete /TN \"MicrosoftEdgeUpdateTaskMachine*\" /F 2>nul")
  echo "[+] Останавливаем и удаляем службы..."
  discard runCmd("sc stop edgeupdate 2>nul")
  discard runCmd("sc delete edgeupdate 2>nul")
  result = true

proc removeWebView2*(): bool =
  let wv2Folders = [
    r"C:\Program Files (x86)\Microsoft\EdgeWebView",
    getEnv("LOCALAPPDATA") & r"\Microsoft\EdgeWebView"
  ]
  echo "[+] Удаляем WebView2..."
  for f in wv2Folders:
    if dirExists(f):
      echo "    Удаление: ", f
      discard removeDirRecursively(f)
  discard regDeleteTree(HKEY_LOCAL_MACHINE, r"Software\Microsoft\EdgeWebView")
  result = true

var gCancelBurn*: bool = false

type BurnOptions = object
  skipWebView2: bool
  dryRun: bool
  force: bool

proc burnEverything*(options: BurnOptions) =
  if options.dryRun:
    echo "=== РЕЖИМ СУХОГО ПРОГОНА (ничего не будет удалено) ==="
    echo "Будут убиты процессы: msedge.exe, MicrosoftEdgeUpdate.exe, msedgewebview2.exe"
    echo "Будут удалены папки: Program Files, ProgramData, AppData\\Local, AppData\\Roaming"
    echo "Будут удалены ключи реестра: HKLM\\Software\\Microsoft\\Edge*, HKCU\\... и т.д."
    echo "Будут удалены задачи планировщика и службы edgeupdate"
    if not options.skipWebView2: echo "Будет удалён WebView2"
    echo "=============================================="
    return

  echo "=== НАЧАЛО УНИЧТОЖЕНИЯ ==="
  killEdgeProcesses()
  if gCancelBurn: return

  removeEdgeFiles()
  if gCancelBurn: return

  removeEdgeUserData()
  if gCancelBurn: return

  cleanEdgeRegistry()
  if gCancelBurn: return

  if not options.skipWebView2:
    removeWebView2()
  else:
    echo "[!] Пропускаем удаление WebView2 по запросу"

  echo "=== УНИЧТОЖЕНИЕ ЗАВЕРШЕНО ==="
  echo "Рекомендуется перезагрузить компьютер для полной очистки."