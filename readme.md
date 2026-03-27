# 🚀 FlowMonitor

A lightweight system monitoring toolkit for tracking disk changes, capturing domain traffic, and managing wallpaper integrity.

---

## 🧠 Features

* 💽 Monitor disk partitions and detect changes
* 🌐 Capture domain traffic using `tshark`
* 🖼️ Detect and control wallpaper changes
* 🧾 CLI tools for log analysis

---

## 📦 Project Structure

```
FLOWMONITOR/
├── bin/                    # CLI commands (flowdisk, flowdomain)
├── logs/                  # Output logs
├── modules/               # PowerShell modules
├── python_service/        # Python processing scripts
├── FlowMonitor_*.ps1      # Runner scripts
```

---

## ⚙️ Requirements

### Python

* Install Python 3.x
* Enable "Add to PATH"

### Wireshark (tshark)

* Install Wireshark
* Ensure `tshark` is available in PATH

---

## 🛠️ Setup

### 1. Create Virtual Environment

```
python -m venv python_service/venv
```

### 2. Install Dependencies

```
python_service\venv\Scripts\pip install -r python_service\requirements.txt
```

### 3. Add CLI to PATH

Add the `bin/` directory to your system PATH.

---

## ⏱️ Scheduled Tasks

Configure the following in Task Scheduler:

* **FlowMonitor_Disk.ps1** → At startup + every 10 minutes
* **FlowMonitor_Domain_Names.ps1** → At startup
* **FlowMonitor_wallpaper.ps1** → At startup + every 10 minutes

---

## 💻 Usage

### Disk Monitoring

```
flowdisk
flowdisk --date YYYY-MM-DD
flowdisk --time HH:MM:SS
flowdisk --date YYYY-MM-DD --time HH:MM:SS
```

### Domain Monitoring

```
flowdomain
flowdomain 20
flowdomain --date YYYY-MM-DD
flowdomain --time HH:MM:SS
flowdomain --date YYYY-MM-DD --time HH:MM:SS
```

---

## 📝 Notes

* Logs are stored in the `logs/` directory
* PowerShell scripts handle scheduled execution
* Python processes and analyzes data
* `tshark` handles network capture
