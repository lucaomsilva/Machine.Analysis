# ==================================================================================
# Makefile for Zephyr Environment Setup (Fedora Linux + ESP32-S3)
# Project: SMID (Distributed Industrial Monitoring System)
# ==================================================================================

# --- Configuration ---
ZEPHYR_VERSION = v3.7-branch
SDK_VERSION    = 0.16.8
SDK_URL        = https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.8/zephyr-sdk-0.16.8_linux-x86_64.tar.xz
BOARD          = esp32s3_devkitm
VENV_DIR       = .venv
WEST           = $(VENV_DIR)/bin/west
PIP            = $(VENV_DIR)/bin/pip

# --- Main Commands ---

.PHONY: help setup_system setup_project install_sdk build clean menuconfig

help:
	@echo "--- Available Commands ---"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ==================================================================================
# 1. System Setup (Requires SUDO)
# ==================================================================================
setup_system: ## Installs Fedora dependencies (dnf) - Requires SUDO
	@echo "[SYS] Updating and installing Fedora dependencies..."
	sudo dnf update -y
	sudo dnf group install -y "C Development Tools and Libraries" "Development Tools"
	sudo dnf install -y cmake ninja-build gperf python3-pip python3-tkinter dtc python3-devel xz file wget
	@echo "[SYS] System dependencies installed successfully."

# ==================================================================================
# 2. Project Setup (User Space)
# ==================================================================================
setup_project:
	@echo "[PROJ] Creating Python virtual environment..."
	python3 -m venv $(VENV_DIR)
	
	@echo "[PROJ] Installing West..."
	$(PIP) install west
	
	@echo "[PROJ] Initializing Zephyr ($(ZEPHYR_VERSION))..."
	# Check if already initialized to avoid errors
	if [ ! -d "zephyr" ]; then \
		$(WEST) init -m https://github.com/zephyrproject-rtos/zephyr --mr $(ZEPHYR_VERSION) .; \
	fi
	
	@echo "[PROJ] Updating modules (this may take time)..."
	$(WEST) update
	
	@echo "[PROJ] Exporting Zephyr configurations..."
	$(WEST) zephyr-export
	
	@echo "[PROJ] Installing Zephyr Python dependencies..."
	$(PIP) install -r zephyr/scripts/requirements.txt
	
	@echo "[PROJ] Fetching Proprietary Blobs (Wi-Fi/BT)..."
	$(WEST) blobs fetch hal_espressif
	
	@echo "[OK] Project configured! Now run 'make install_sdk' if you haven't yet."

# ==================================================================================
# 3. SDK Installation (Assisted Manual)
# ==================================================================================
install_sdk:
	@echo "[SDK] Downloading Zephyr SDK $(SDK_VERSION)..."
	@if [ ! -d "zephyr-sdk-$(SDK_VERSION)" ]; then \
		wget -c $(SDK_URL); \
		echo "[SDK] Extracting archive (please wait)..."; \
		tar xvf zephyr-sdk-$(SDK_VERSION)_linux-x86_64.tar.xz; \
		echo ""; \
		echo "!!! ACTION REQUIRED !!!"; \
		echo "Enter the zephyr-sdk-$(SDK_VERSION) directory and run ./setup.sh manually to register the toolchain."; \
	else \
		echo "[SDK] SDK directory already exists. Skipping download."; \
	fi

# ==================================================================================
# 4. Development Commands
# ==================================================================================

build:
	@echo "[BUILD] Building for $(BOARD)..."
	$(WEST) build -p auto -b $(BOARD) app

flash:
	@echo "[FLASH] Flashing..."
	$(WEST) flash

monitor:
	@echo "[MONITOR] Opening serial monitor..."
	$(WEST) espressif monitor

menuconfig:
	$(WEST) build -t menuconfig

clean:
	rm -rf build
	@echo "[CLEAN] Build directory cleaned."
