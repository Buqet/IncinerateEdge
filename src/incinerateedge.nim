import winim/lean
import gui, resources

when defined(windows):
  var wc: WNDCLASSW
  wc.style = CS_HREDRAW or CS_VREDRAW
  wc.lpfnWndProc = windowProc
  wc.hInstance = GetModuleHandleW(nil)
  wc.lpszClassName = L"IncinerateEdgeClass"
  wc.hbrBackground = cast[HBRUSH](COLOR_WINDOW + 1)
  wc.hCursor = LoadCursorW(nil, IDC_ARROW)

  if RegisterClassW(addr wc) == 0:
    quit(1)

  let hwnd = CreateWindowExW(0, L"IncinerateEdgeClass", L"IncinerateEdge — Испепелитель Edge",
                             WS_OVERLAPPEDWINDOW and not WS_MAXIMIZEBOX and not WS_THICKFRAME,
                             CW_USEDEFAULT, CW_USEDEFAULT, 420, 220,
                             nil, nil, wc.hInstance, nil)
  if hwnd == nil:
    quit(1)

  ShowWindow(hwnd, SW_SHOW)
  UpdateWindow(hwnd)

  var msg: MSG
  while GetMessageW(addr msg, nil, 0, 0) > 0:
    TranslateMessage(addr msg)
    DispatchMessageW(addr msg)
