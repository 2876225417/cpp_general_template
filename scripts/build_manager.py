#!/usr/bin/env python3
import os
import sys
import subprocess
import curses
from curses import panel
import argparse
from pathlib import Path
import shutil

class Colors:
    """颜色定义"""
    @staticmethod
    def init_colors():
        curses.start_color()
        curses.init_pair(1, curses.COLOR_CYAN, curses.COLOR_BLACK)    # 标题
        curses.init_pair(2, curses.COLOR_GREEN, curses.COLOR_BLACK)   # 成功
        curses.init_pair(3, curses.COLOR_RED, curses.COLOR_BLACK)     # 错误
        curses.init_pair(4, curses.COLOR_YELLOW, curses.COLOR_BLACK)  # 警告
        curses.init_pair(5, curses.COLOR_BLUE, curses.COLOR_BLACK)    # 信息
        curses.init_pair(6, curses.COLOR_MAGENTA, curses.COLOR_BLACK) # 菜单选中
        curses.init_pair(7, curses.COLOR_WHITE, curses.COLOR_BLUE)    # 状态栏
        curses.init_pair(8, curses.COLOR_WHITE, curses.COLOR_BLACK)   # 普通文本

class BuildManager:
    def __init__(self, scripts_dir):
        self.scripts_dir = Path(scripts_dir)
        self.build_dir = self.scripts_dir / "building_scripts"
        self.available_scripts = self._get_available_scripts()
        
    def _get_available_scripts(self):
        """获取所有可用的构建脚本"""
        scripts = []
        if self.build_dir.exists():
            for script in self.build_dir.glob("b_*.sh"):
                scripts.append(script.name)
        return sorted(scripts)
    
    def run_script(self, script_name, platform, use_sudo=False):
        """运行指定的构建脚本"""
        script_path = self.build_dir / script_name
        if not script_path.exists():
            return False, f"Script {script_name} not found"
            
        cmd = ["sudo", "bash", str(script_path), f"--target_platform={platform}"] if use_sudo else \
              ["bash", str(script_path), f"--target_platform={platform}"]
              
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=self.scripts_dir)
            return result.returncode == 0, result.stdout if result.returncode == 0 else result.stderr
        except Exception as e:
            return False, str(e)
    
    def get_script_info(self, script_name):
        """获取脚本的基本信息"""
        lib_name = script_name.replace("b_", "").replace(".sh", "")
        return {
            "name": script_name,
            "library": lib_name,
            "path": str(self.build_dir / script_name)
        }

class Menu:
    def __init__(self, stdscr, build_manager):
        self.stdscr = stdscr
        self.build_manager = build_manager
        self.current_row = 0
        self.platform = "linux"
        self.use_sudo = False
        self.height, self.width = stdscr.getmaxyx()
        
    def center_text(self, text, start_row=None):
        """居中显示文本"""
        if start_row is None:
            start_row = self.height // 2
        text_len = len(text)
        start_col = (self.width - text_len) // 2
        return start_row, max(0, start_col)
        
    def draw_border(self, start_row, height, title="", color_pair=1):
        """绘制边框"""
        border_width = min(self.width - 4, 80)
        start_col = (self.width - border_width) // 2
        
        # 绘制顶部边框
        if title:
            title_text = f" {title} "
            left_padding = (border_width - len(title_text)) // 2
            right_padding = border_width - len(title_text) - left_padding
            border_line = "=" * left_padding + title_text + "=" * right_padding
        else:
            border_line = "=" * border_width
            
        self.stdscr.addstr(start_row, start_col, border_line, curses.color_pair(color_pair) | curses.A_BOLD)
        
        # 绘制侧边框
        for i in range(1, height - 1):
            self.stdscr.addstr(start_row + i, start_col, "|", curses.color_pair(5))
            self.stdscr.addstr(start_row + i, start_col + border_width - 1, "|", curses.color_pair(5))
            
        # 绘制底部边框
        self.stdscr.addstr(start_row + height - 1, start_col, "=" * border_width, curses.color_pair(1) | curses.A_BOLD)
        
        return start_col, border_width
        
    def draw_centered_menu(self, title, items, selected_idx=0, status_msg="", show_border=True):
        """绘制居中菜单"""
        self.stdscr.clear()
        self.height, self.width = self.stdscr.getmaxyx()
        
        # 计算菜单位置
        menu_height = len(items) + 8
        menu_width = min(self.width - 4, 80)
        start_row = max(1, (self.height - menu_height) // 2)
        start_col = (self.width - menu_width) // 2
        
        # 绘制边框
        if show_border:
            self.draw_border(start_row, menu_height, title, 1)
            content_start_row = start_row + 2
            content_start_col = start_col + 2
        else:
            content_start_row = start_row
            content_start_col = start_col
            
        # 绘制标题
        title_row = content_start_row
        title_x = start_col + (menu_width - len(title)) // 2
        self.stdscr.addstr(title_row, max(0, title_x), title, curses.color_pair(1) | curses.A_BOLD | curses.A_UNDERLINE)
        
        # 显示当前配置
        config_line = f"Platform: {self.platform} | Sudo: {'ON' if self.use_sudo else 'OFF'}"
        config_row = title_row + 1
        config_x = start_col + (menu_width - len(config_line)) // 2
        self.stdscr.addstr(config_row, max(0, config_x), config_line, curses.color_pair(4))
        
        # 分隔线
        separator = "-" * (menu_width - 4)
        self.stdscr.addstr(config_row + 1, start_col + 2, separator, curses.color_pair(5))
        
        # 绘制菜单项
        menu_start_row = config_row + 2
        for idx, item in enumerate(items):
            item_row = menu_start_row + idx
            if idx == selected_idx:
                display_text = f"▶ {item}"
                self.stdscr.addstr(item_row, start_col + 4, display_text, curses.color_pair(6) | curses.A_BOLD | curses.A_REVERSE)
            else:
                display_text = f"  {item}"
                self.stdscr.addstr(item_row, start_col + 4, display_text, curses.color_pair(8))
                
        # 状态消息
        if status_msg:
            status_row = menu_start_row + len(items) + 1
            if status_row < self.height - 2:
                # 分隔线
                self.stdscr.addstr(status_row, start_col + 2, separator, curses.color_pair(5))
                # 状态消息
                status_x = start_col + (menu_width - len(status_msg)) // 2
                color_pair = curses.color_pair(2) if "✓" in status_msg or "Success" in status_msg else curses.color_pair(3)
                self.stdscr.addstr(status_row + 1, max(0, status_x), status_msg, color_pair | curses.A_BOLD)
            
        self.stdscr.refresh()
        
    def draw_simple_menu(self, title, items, selected_idx=0, status_msg=""):
        """绘制简单菜单（无边框）"""
        self.stdscr.clear()
        self.height, self.width = self.stdscr.getmaxyx()
        
        # 居中标题
        title_row, title_col = self.center_text(title, 2)
        self.stdscr.addstr(title_row, title_col, title, curses.color_pair(1) | curses.A_BOLD | curses.A_UNDERLINE)
        
        # 显示当前配置
        config_line = f"Platform: {self.platform} | Sudo: {'ON' if self.use_sudo else 'OFF'}"
        config_row, config_col = self.center_text(config_line, 4)
        self.stdscr.addstr(config_row, config_col, config_line, curses.color_pair(4))
        
        # 分隔线
        separator = "=" * min(len(config_line), self.width - 4)
        sep_row, sep_col = self.center_text(separator, 5)
        self.stdscr.addstr(sep_row, sep_col, separator, curses.color_pair(5))
        
        # 绘制菜单项
        start_row = 7
        for idx, item in enumerate(items):
            item_row = start_row + idx
            if idx == selected_idx:
                display_text = f"▶ {item}"
                item_col = (self.width - len(display_text)) // 2
                self.stdscr.addstr(item_row, max(0, item_col), display_text, curses.color_pair(6) | curses.A_BOLD | curses.A_REVERSE)
            else:
                display_text = f"○ {item}"
                item_col = (self.width - len(display_text)) // 2
                self.stdscr.addstr(item_row, max(0, item_col), display_text, curses.color_pair(8))
                
        # 状态消息
        if status_msg:
            status_row, status_col = self.center_text(status_msg, start_row + len(items) + 2)
            color_pair = curses.color_pair(2) if "✓" in status_msg or "Success" in status_msg else curses.color_pair(3)
            self.stdscr.addstr(status_row, max(0, status_col), status_msg, color_pair | curses.A_BOLD)
            
        self.stdscr.refresh()
        
    def main_menu(self):
        """主菜单"""
        menu_items = [
            "Select Platform",
            "Toggle Sudo Mode",
            "Build Individual Library",
            "Build All Libraries",
            "List Available Libraries",
            "Exit"
        ]
        
        while True:
            self.draw_centered_menu("🔧 BUILD MANAGER - MAIN MENU", menu_items, self.current_row)
            key = self.stdscr.getch()
            
            if key == curses.KEY_UP and self.current_row > 0:
                self.current_row -= 1
            elif key == curses.KEY_DOWN and self.current_row < len(menu_items) - 1:
                self.current_row += 1
            elif key == curses.KEY_ENTER or key in [10, 13]:
                if self.current_row == 0:  # Select Platform
                    self.select_platform()
                elif self.current_row == 1:  # Toggle Sudo
                    self.use_sudo = not self.use_sudo
                elif self.current_row == 2:  # Build Individual Library
                    self.build_individual()
                elif self.current_row == 3:  # Build All Libraries
                    self.build_all()
                elif self.current_row == 4:  # List Available Libraries
                    self.list_libraries()
                elif self.current_row == 5:  # Exit
                    break
                self.current_row = 0
            elif key == ord('q') or key == 27:  # ESC or 'q'
                break
                
    def select_platform(self):
        """选择平台"""
        platforms = ["linux", "android", "all"]
        platform_names = ["🐧 Linux Only", "🤖 Android Only", "🔄 Both Platforms"]
        current_selection = platforms.index(self.platform) if self.platform in platforms else 0
        
        while True:
            self.draw_centered_menu("🌐 SELECT TARGET PLATFORM", platform_names, current_selection)
            key = self.stdscr.getch()
            
            if key == curses.KEY_UP and current_selection > 0:
                current_selection -= 1
            elif key == curses.KEY_DOWN and current_selection < len(platforms) - 1:
                current_selection += 1
            elif key == curses.KEY_ENTER or key in [10, 13]:
                self.platform = platforms[current_selection]
                break
            elif key == 27:  # ESC
                break
                
    def build_individual(self):
        """构建单个库"""
        if not self.build_manager.available_scripts:
            self.draw_centered_menu("❌ NO SCRIPTS AVAILABLE", ["Back"], 0, "No build scripts found!")
            self.stdscr.getch()
            return
            
        current_selection = 0
        while True:
            script_names = []
            for script in self.build_manager.available_scripts:
                lib_name = script.replace("b_", "").replace(".sh", "").upper()
                script_names.append(f"📦 {lib_name}")
                
            self.draw_centered_menu(f"🔨 SELECT LIBRARY TO BUILD", script_names, current_selection, 
                                  f"Platform: {self.platform}")
            key = self.stdscr.getch()
            
            if key == curses.KEY_UP and current_selection > 0:
                current_selection -= 1
            elif key == curses.KEY_DOWN and current_selection < len(script_names) - 1:
                current_selection += 1
            elif key == curses.KEY_ENTER or key in [10, 13]:
                script_name = self.build_manager.available_scripts[current_selection]
                self.execute_build(script_name)
                current_selection = 0
            elif key == 27:  # ESC
                break
                
    def build_all(self):
        """构建所有库"""
        if not self.build_manager.available_scripts:
            self.draw_centered_menu("❌ NO SCRIPTS AVAILABLE", ["Back"], 0, "No build scripts found!")
            self.stdscr.getch()
            return
            
        confirm_items = ["✅ Yes, Build All", "❌ No, Cancel"]
        confirm_selection = 1
        
        while True:
            self.draw_centered_menu("⚠️  CONFIRM BUILD ALL", confirm_items, confirm_selection,
                                  f"Build ALL {len(self.build_manager.available_scripts)} libraries for {self.platform}?")
            key = self.stdscr.getch()
            
            if key == curses.KEY_UP and confirm_selection > 0:
                confirm_selection -= 1
            elif key == curses.KEY_DOWN and confirm_selection < len(confirm_items) - 1:
                confirm_selection += 1
            elif key == curses.KEY_ENTER or key in [10, 13]:
                if confirm_selection == 0:  # Yes
                    for script_name in self.build_manager.available_scripts:
                        self.execute_build(script_name)
                break
            elif key == 27:  # ESC
                break
                
    def execute_build(self, script_name):
        """执行构建"""
        lib_name = script_name.replace("b_", "").replace(".sh", "").upper()
        status_msg = f"🚀 Building {lib_name} for {self.platform}..."
        self.draw_centered_menu("⚙️  BUILDING...", [f"📦 {lib_name}"], 0, status_msg)
        self.stdscr.refresh()
        
        success, output = self.build_manager.run_script(script_name, self.platform, self.use_sudo)
        
        if success:
            result_msg = f"✅ Successfully built {lib_name}"
        else:
            result_msg = f"❌ Failed to build {lib_name}"
            
        self.draw_centered_menu("🏁 BUILD RESULT", [f"📦 {lib_name}"], 0, result_msg)
        self.stdscr.getch()
        
    def list_libraries(self):
        """列出所有可用库"""
        if not self.build_manager.available_scripts:
            items = ["❌ No libraries found"]
        else:
            items = []
            for script in self.build_manager.available_scripts:
                lib_name = script.replace("b_", "").replace(".sh", "").upper()
                items.append(f"📦 {lib_name}")
                
        # 添加返回选项
        items.append("🔙 Back")
        
        # 计算合适的位置
        self.draw_centered_menu("📚 AVAILABLE LIBRARIES", items, len(items) - 1)
        self.stdscr.getch()

def draw_splash_screen(stdscr):
    """绘制启动画面"""
    stdscr.clear()
    height, width = stdscr.getmaxyx()
    
    # ASCII 艺术
    logo = [
        " ╔══════════════════════════════════════╗ ",
        "║       🚀 BUILD MANAGER 🚀           ║ ",
        " ║    🛠️  Multi-Platform Builder        ║ ",
        "║      🐍 Python TUI Interface         ║ ",
        " ╚══════════════════════════════════════╝ "
    ]
    
    # 居中显示 logo
    start_row = (height - len(logo)) // 2 - 2
    for i, line in enumerate(logo):
        line_col = (width - len(line)) // 2
        stdscr.addstr(start_row + i, max(0, line_col), line, curses.color_pair(1) | curses.A_BOLD)
    
    # 显示提示
    hint = "Press any key to continue..."
    hint_row = start_row + len(logo) + 2
    hint_col = (width - len(hint)) // 2
    stdscr.addstr(hint_row, max(0, hint_col), hint, curses.color_pair(4))
    
    stdscr.refresh()
    stdscr.getch()

def main(stdscr):
    # 初始化颜色
    Colors.init_colors()
    
    # 隐藏光标
    curses.curs_set(0)
    curses.noecho()
    curses.cbreak()
    stdscr.keypad(True)
    
    # 显示启动画面
    draw_splash_screen(stdscr)
    
    # 获取脚本目录
    script_dir = Path(__file__).parent.absolute()
    build_manager = BuildManager(script_dir)
    
    # 创建菜单
    menu = Menu(stdscr, build_manager)
    menu.main_menu()

if __name__ == "__main__":
    # 设置终端
    os.environ.setdefault('ESCDELAY', '25')
    curses.wrapper(main)

