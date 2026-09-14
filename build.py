#!/usr/bin/env python3
"""
    Sell Ores Hub - Build Script
    Đóng gói các module trong src/ thành 1 file main.lua hoàn chỉnh duy nhất
"""

import os
import re

MODULES_ORDER = [
    'OresData.lua',
    'State.lua',
    'Utils.lua',
    'AutoRoll.lua',
    'SmartFuser.lua',
    'MoneyPipeline.lua',
    'ShowcaseBuff.lua',
    'ConfigManager.lua',
    'UI.lua'
]

SRC_DIR = os.path.join(os.path.dirname(__file__), 'src')
OUTPUT_FILE = os.path.join(os.path.dirname(__file__), 'main.lua')

HEADER = """--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║                 SELL ORES HUB - V7.8 ULTIMATE PRO                ║
    ║   • MODULAR ARCHITECTURE: CHIA TÁCH MODULE RÕ RÀNG & MƯỢT MÀ     ║
    ║   • FULL AUTO ROLL: TỰ MỞ BẢNG, BẤM START & TỰ ĐÓNG BẢNG 100%    ║
    ║   • SMART FUSER: NẠP QUẶNG AN TOÀN & BẢO VỆ TUYỆT ĐỐI QUẶNG XỊN  ║
    ║   • ORE BUFF SHOWCASE: DUY TRÌ TỰ ĐỘNG X2.75 BUFF 24/7           ║
    ║   • MONEY PIPELINE: ĐÀO MỎ -> NUNG LÒ -> BÁN TIỀN KHÉP KÍN       ║
    ║   • FLOATING TOGGLE BUTTON TRÒN NỔI MỞ LẠI MENU MỌI LÚC          ║
    ╚══════════════════════════════════════════════════════════════════╝
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer

-- Load Fluent UI Library
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

"""

def build():
    parts = [HEADER]
    
    for mod_name in MODULES_ORDER:
        mod_path = os.path.join(SRC_DIR, mod_name)
        if not os.path.exists(mod_path):
            print(f"Error: Missing module {mod_path}")
            return False
            
        with open(mod_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        lines = content.rstrip().splitlines()
        while lines and not lines[-1].strip():
            lines.pop()
            
        # Strip ONLY the final `return ModuleName` at the very end of module
        if lines and re.match(r'^\s*return\s+\w+\s*$', lines[-1]):
            print(f"Stripping module export from {mod_name}: '{lines[-1].strip()}'")
            lines.pop()
        else:
            print(f"Notice: {mod_name} does not end with 'return <Identifier>'. Last line: '{lines[-1] if lines else 'EMPTY'}'")
            
        parts.append(f"\n--------------------------------------------------------------------------------\n-- MODULE: {mod_name}\n--------------------------------------------------------------------------------\n")
        parts.append('\n'.join(lines) + '\n')
        
    # Bootstrap / Initialization execution
    bootstrap = """
--------------------------------------------------------------------------------
-- BOOTSTRAP INITIALIZATION
--------------------------------------------------------------------------------
local deps = {
    Fluent = Fluent,
    SaveManager = SaveManager,
    InterfaceManager = InterfaceManager,
    State = State,
    defaultBuy = defaultBuy,
    defaultFuse = defaultFuse,
    OresData = OresData,
    Utils = Utils,
    AutoRoll = AutoRoll,
    SmartFuser = SmartFuser,
    MoneyPipeline = MoneyPipeline,
    ShowcaseBuff = ShowcaseBuff,
    ConfigManager = ConfigManager
}

AutoRoll.init(deps)
SmartFuser.init(deps)
MoneyPipeline.init(deps)
ShowcaseBuff.init(deps)
ConfigManager.init(deps)
UI.init(deps)
"""
    parts.append(bootstrap)
    
    full_code = ''.join(parts)
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        f.write(full_code)
        
    # Also write to bundle.lua so both files are always identical and up to date
    bundle_file = os.path.join(os.path.dirname(__file__), 'bundle.lua')
    with open(bundle_file, 'w', encoding='utf-8') as f:
        f.write(full_code)
        
    print(f"Build complete! Output: {OUTPUT_FILE} and {bundle_file}")
    print(f"Lines: {len(full_code.splitlines())}, Bytes: {len(full_code.encode('utf-8'))}")
    
    # Validate with luaparser if available
    try:
        from luaparser import ast
        ast.parse(full_code)
        print("AST Syntax Check: PASSED (No syntax errors)")
    except Exception as e:
        print(f"AST Syntax Check: FAILED: {e}")
        return False
        
    return True

if __name__ == '__main__':
    build()
