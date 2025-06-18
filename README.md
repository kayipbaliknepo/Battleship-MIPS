# Battleship Game in MIPS Assembly (for MARS Simulator)

This project is a simplified **Battleship game** implemented entirely in **MIPS Assembly** language, designed to run on the **MARS simulator** with visual feedback via the **Bitmap Display** tool.

## 🎮 Game Overview

- Grid size: **5x5**
- Players: **Human vs AI**
- Each player has **3 ships**
- The game is **turn-based**: players take turns to guess grid cells
- **Hit** and **miss** feedback is shown on screen
- All logic is written in low-level MIPS assembly code

## 🧠 Features

- Manual ship placement for the human player
- Random, non-overlapping ship placement for AI
- Hit/miss detection and turn control
- Visual display using MARS Bitmap Display
- Color codes:
  - **Red:** Hit
  - **Blue:** Miss
  - **White:** Grid lines

## 💻 Technical Highlights

- Input/output via syscall instructions
- Random number generation using pseudo-random logic
- Data storage in static memory (`.data` section)
- Drawing to Bitmap Display by writing to memory

### 📺 Bitmap Display Settings (in MARS):

- Unit Width in Pixels: **1**
- Unit Height in Pixels: **1**
- Display Width in Pixels: **512**
- Display Height in Pixels: **512**
- Base Address for Display: **0x10010000 (static data)**

## 📂 File

- `battleshipGame.asm`: Main assembly source code (fully self-contained)

## 🎓 Educational Purpose

This project is developed for **educational purposes**, to gain hands-on experience in:

- Low-level memory manipulation
- Stack usage and procedure call conventions
- Conditional logic and loops in MIPS
- Bitmap-based graphics rendering
- Assembly debugging and modular organization

## ✅ Requirements

- MARS MIPS Simulator (recommended version: 4.5 or later)
- Basic understanding of MIPS instruction set

## 📜 License

This project is shared for academic and learning use. MIT License may be applied if open-sourced.

---

Author: [kayipbaliknepo](https://github.com/kayipbaliknepo)
