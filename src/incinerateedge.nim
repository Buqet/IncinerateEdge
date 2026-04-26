import os, strutils, parseopt, incinerator

proc printHelp() =
  echo """
Испепелитель Edge — удаление Microsoft Edge с остатками

Использование:
  incinerateedge.exe [опции]

Опции:
  -h, --help          Показать эту справку
  --no-webview2       Не удалять WebView2 (может нарушить работу некоторых приложений)
  --dry-run           Режим примерки: показать, что будет сделано, но не удалять
  --force             Не запрашивать подтверждение (автоматическое выполнение)
  --silent            Минимум вывода (только ошибки)

Примеры:
  incinerateedge.exe --force           # Удалить всё без вопросов
  incinerateedge.exe --dry-run         # Посмотреть что будет
  incinerateedge.exe --no-webview2     # Оставить WebView2
"""
proc confirm(message: string): bool =
  stdout.write(message & " (y/N): ")
  let answer = stdin.readLine().toLowerAscii()
  result = answer == "y" or answer == "yes"

when isMainModule:
  var options: BurnOptions
  var silent = false

  var parser = initOptParser(commandLineParams())
  for kind, key, val in parser.getopt():
    case kind
    of cmdShortOption, cmdLongOption:
      case key
      of "h", "help":
        printHelp()
        quit(0)
      of "no-webview2":
        options.skipWebView2 = true
      of "dry-run":
        options.dryRun = true
      of "force":
        options.force = true
      of "silent":
        silent = true
      else:
        echo "Неизвестная опция: ", key
        printHelp()
        quit(1)
    of cmdArgument:
      echo "Лишний аргумент: ", key
      printHelp()
      quit(1)
    else: discard

  if not options.dryRun:
    var token: HANDLE
    var isElevated = false
    if OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, addr token):
      var elev: TOKEN_ELEVATION
      var size: DWORD = sizeof(elev).DWORD
      if GetTokenInformation(token, TokenElevation, addr elev, size, addr size):
        isElevated = elev.TokenIsElevated != 0
      CloseHandle(token)
    if not isElevated:
      echo "[ОШИБКА] Необходимы права администратора. Запустите программу от имени Администратора."
      echo "Нажмите любую клавишу для выхода..."
      discard stdin.readLine()
      quit(1)

  if not silent:
    echo "=== IncinerateEdge — Уничтожитель Microsoft Edge ==="
    echo "ВНИМАНИЕ: Эта программа удалит:\n" &
         "  - все файлы Edge из Program Files, ProgramData\n" &
         "  - профили и кэш из AppData\n" &
         "  - ключи реестра Edge\n" &
         "  - запланированные задачи и службы\n" &
         (if not options.skipWebView2: "  - WebView2 (может нарушить работу Spotify, Teams и др.)\n" else: "") &
         "Это действие необратимо.\n"

  if not options.force and not options.dryRun:
    if not confirm("Продолжить уничтожение Edge?"):
      echo "Отменено."
      quit(0)

  if not options.skipWebView2 and not options.force and not options.dryRun:
    echo "\n[!] ВНИМАНИЕ: WebView2 используется такими приложениями как Teams, Spotify, Outlook."
    if not confirm("Удалить WebView2? (рекомендуется НЕТ, если не уверены)"):
      options.skipWebView2 = true
      echo "WebView2 не будет удалён."

  # Запуск
  burnEverything(options)

  if not options.dryRun and not silent:
    echo "\nНажмите Enter для выхода..."
    discard stdin.readLine()