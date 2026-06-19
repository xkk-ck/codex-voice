on run argv
  set inputText to item 1 of argv
  set shouldSend to false
  if (count of argv) > 1 then
    set shouldSend to ((item 2 of argv) is "true")
  end if

  set the clipboard to inputText

  tell application "Codex" to activate
  delay 0.25

  tell application "System Events"
    keystroke "v" using command down
    delay 0.1
    if shouldSend then
      key code 36
    end if
  end tell
end run
