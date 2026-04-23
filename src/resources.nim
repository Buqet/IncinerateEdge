const
  ID_PROGRESS_BAR = 1001
  ID_BTN_BURN = 1002
  ID_LBL_STATUS = 1003
  ID_LBL_PHASE = 1004

type BurnPhase = enum
  phKillProcesses = "Остановка процессов Edge..."
  phRemoveExe = "Удаление EXE и системных файлов..."
  phRemoveUserData = "Удаление пользовательских данных (профили, кэш)..."
  phCleanRegistry = "Зачистка реестра..."
  phRemoveWebView2 = "Удаление WebView2 (по желанию)..."
  phDone = "Edge уничтожен. Рекомендуется перезагрузка."
