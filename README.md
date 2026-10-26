# Fix: File Explorer / File Picker Causes Lag Spikes, Stream Freezes & High Ping on Windows

**Opening File Explorer or any Open/Save file dialog makes your network freeze for a few seconds.**
Remote desktop / game streams stutter, ping jumps to 300–1000 ms, and you get "slow connection" /
"poor network" warnings — but only at the moment a file window opens.

This repo has a **one-click, fully reversible fix** (one per-user registry value, no admin rights).

> Works around a Windows component called **"DLNA Media Servers Data Source"** that Explorer
> loads under *This PC* every time a file window or file picker opens.

---

## Do you have this problem?

You probably do if **all** of these sound familiar:

- Streaming / remote access runs smoothly, **until** you open File Explorer, a file picker
  ("Open…", "Save as…", "Browse…", "Upload file"), or a folder selector.
- At that moment the stream **lags, freezes or drops frames**, ping spikes, and the app shows
  **"slow connection" / "network unstable"** warnings.
- It happens with **every** streaming app, for example:
  - **Sunshine / Apollo** host with **Moonlight / Artemis** client (Android, iOS, PC)
  - **Chrome Remote Desktop**
  - **OnePlus / OPPO Device Connect (O+Connect)**, Phone Link / screen sharing
  - Likely also Parsec, Steam Link / Remote Play, RDP, AnyDesk, game streaming, online games, voice calls
- The PC is on **Wi-Fi** (most noticeable there).
- Task Manager may show a small **Wi-Fi / network spike** whenever a folder opens.

Common searches for this problem: *"file explorer causes lag spike"*, *"opening file explorer freezes
Moonlight stream"*, *"Sunshine stutter when opening file dialog"*, *"ping spike when opening folder
Windows 11"*, *"file picker freezes remote desktop"*, *"Wi-Fi lag when opening Explorer"*.

## Quick test (changes nothing)

Double-click **`TEST-lag.bat`**. It pings your router while Windows loads *This PC* (exactly
what Explorer and file pickers do) and tells you whether a spike occurs.

Example from an affected PC (Windows 11 25H2, MediaTek MT7921 Wi-Fi 6), measured during an active stream:

```
Fix currently applied: False
  Idle (baseline)              max    6 ms  | 6 3 1 1 1 1 1 1 1 1 1 1
  While loading "This PC"      max  262 ms  | 1 1 262 216 163 78 121 121 188 118 215 1

Fix currently applied: True
  Idle (baseline)              max    8 ms  | 8 1 1 2 1 6 1 8 3 2 1 1
  While loading "This PC"      max   14 ms  | 2 1 5 14 1 1 7 4 1 1 2 1
```

## How to fix

1. [Download this repo (ZIP)](https://github.com/likhonmain/explorer-stream-lag-fix/archive/refs/heads/main.zip) and extract it.
2. Double-click **`APPLY-fix.bat`**.
3. Restart apps that are already open (or sign out / restart *Windows Explorer* in Task Manager).

**To undo:** double-click **`UNDO-fix.bat`**. Windows goes back to its default behavior.

| File | What it does |
|---|---|
| `APPLY-fix.bat` | Applies the fix (current user only, no admin needed) |
| `UNDO-fix.bat` | Removes the fix completely |
| `TEST-lag.bat` | Read-only diagnostic: measures ping while *This PC* loads |
| `scripts\*.ps1` | The PowerShell scripts the `.bat` files run (read them — they are short) |

> The `.bat` files exist because `.ps1` files don't run on double-click by default. They call
> PowerShell with `-ExecutionPolicy Bypass` for that one script only; your system policy is not changed.

### Manual method (no scripts)

Apply (Command Prompt):
```bat
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" /v "{289AF617-1CC3-42A6-926C-E6A863F0E3BA}" /t REG_SZ /d "DLNA Media Servers Data Source" /f
```
Undo:
```bat
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" /v "{289AF617-1CC3-42A6-926C-E6A863F0E3BA}" /f
```

---

## What kind of problem is this?

It's a **Windows shell problem that shows up as a network problem**. It is **not** a bug in
Sunshine, Moonlight, Chrome Remote Desktop or any streaming app — they just suffer from it.

### What happens

1. Every File Explorer window and every standard Open/Save dialog shows the **This PC** folder
   (in the navigation pane or as the location) and enumerates everything under it.
2. Under *This PC* Windows registers a hidden virtual folder,
   **`{289AF617-1CC3-42A6-926C-E6A863F0E3BA}` – "DLNA Media Servers Data Source"**
   (in `HKLM\...\Explorer\MyComputer\NameSpace`). Its job is to show DLNA/UPnP media servers
   (smart TVs, NAS media servers, etc.) on your network.
3. Each time it loads, it starts **network device discovery**. On affected PCs this
   **stalls the Wi-Fi link for roughly 2–5 seconds**: all traffic, including your stream,
   sits in a queue, so latency shoots up to hundreds of ms or packets are lost.
4. The streaming app sees that as a bad connection → stutter, freeze, "slow connection" warning.

### How this was pinned down

Pinging the router while doing one thing at a time, on a live stream:

| Action | Worst ping |
|---|---|
| Idle | ~10 ms |
| Open a File Explorer window | 617–999 ms |
| 100% CPU load on all cores | 8 ms (not CPU) |
| Forced Wi-Fi scan | 41 ms (not scanning) |
| Phone Link / CrossDevice folder, Google Drive, OneDrive, local drives | 10–40 ms (not these) |
| Enumerate *This PC* only, no window | 422–999 ms |
| Enumerate **only** the DLNA Media Servers folder | **468 ms** ← culprit |
| File picker, fix applied | 10–12 ms |
| File picker, fix removed (control) | 667 ms |

Every other sub-folder of *This PC* was tested individually; only the DLNA one produced the spike.

> **Honest note:** the culprit component was identified by direct measurement. The exact
> low-level reason it stalls the Wi-Fi radio (driver/power-save/discovery behavior) is not proven
> and may vary by Wi-Fi chipset and driver. If the fix doesn't help you, your spike has a different cause —
> see *Troubleshooting*.

## What the fix changes (and doesn't)

- Writes **one string value** to
  `HKCU\Software\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked`
  telling Explorer not to load `{289AF617-1CC3-42A6-926C-E6A863F0E3BA}`.
  This is the standard, documented Windows mechanism for blocking a shell extension.
- **Current user only.** No admin rights. No system files, services, drivers, firewall or
  network settings are touched.
- **Side effect:** DLNA media servers (smart TVs / NAS media shares) will no longer appear inside
  File Explorer. Media apps (VLC, Kodi, Plex, "Cast to device", etc.) still find them on their own.
  Normal network shares (`\\PC\share`, mapped drives) are **not** affected.

## Troubleshooting

If `TEST-lag.bat` still shows spikes with the fix applied, other common causes are:

- **Disconnected network drives / dead shortcuts** in Quick access or Recent files pointing at
  offline network paths.
- **Cloud sync shell extensions** (OneDrive, Google Drive, Dropbox, iCloud) — try pausing sync.
- **Wi-Fi adapter power saving** — Device Manager → your Wi-Fi adapter → Power Management /
  Advanced; set the power plan to *High performance* while streaming.
- **Use Ethernet** for the host PC if possible — it removes most of these stalls.

## Compatibility

- Tested on **Windows 11 25H2 (build 26200)**. The same component exists on Windows 10, so it
  should work there too.
- The fix does nothing harmful if the component isn't present.

## License

[MIT](LICENSE) — use at your own risk. The change is one registry value and fully reversible.
