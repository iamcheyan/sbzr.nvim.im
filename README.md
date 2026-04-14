# sbzr.nvim.im - Neovim 中文输入法插件

基于 [ZSaberLv0/ZFVimIM](https://github.com/ZSaberLv0/ZFVimIM)，适配 Neovim 0.11+。

## 目录

- [快速开始](#快速开始)
- [核心功能](#核心功能)
- [命令](#命令)
- [配置](#配置)
- [按键映射](#按键映射)
- [故障排除](#故障排除)

## 快速开始

### 1. 安装插件

> 💡 **最简单方式**：复制配置文件 [`assast/config/sbzr.nvim.im.lua`](assast/config/sbzr.nvim.im.lua) 到 `~/.config/nvim/lua/plugins/sbzr.nvim.im.lua`

或者手动创建配置文件：

```lua
-- ~/.config/nvim/lua/plugins/sbzr.nvim.im.lua
return {
  {
    "iamcheyan/sbzr.nvim.im",
    lazy = false,
  },
}
```

### 2. 使用输入法

1. 按 `;;` 启动输入法
2. 输入编码（SBZR模式）
3. 选择候选词：
   - 使用数字键选择候选词，行为对齐当前 Rime 配置
   - `<Space>` 选第一个，`1-5` 选第 2-6 个，`,`/`.` 翻页
4. 按 `;;` 再次切换关闭

## 核心功能

| 功能 | 说明 |
|------|------|
| **浮动窗口** | 使用 Neovim 原生浮动窗口显示候选词 |
| **智能排序** | 基于使用频率、单字优先、完全匹配优先 |
| **自动造词** | 连续选择多个词后自动组合成新词 |
| **缩写编码** | 3字词：首+二+尾；4字+：首+二+三+尾 |
| **翻页功能** | 支持候选词列表翻页浏览 |

## 命令

### 命令清单

#### 词库管理

| 命令 | 功能 | 说明 |
|------|------|------|
| `:IMInit` | 初始化数据库 | 从 YAML 导入到 DB（强制覆盖 DB） |
| `:IMBackup` | 备份词库 | 从 DB 导出到 YAML（覆盖 YAML 文件） |
| `:IMSync` | 同步词库 | 从 YAML 新增到 DB（只增加，不删除） |
| `:IMInfo` | 显示词库信息 | 显示词库详细信息 |
| `:IMClear` | 清理缓存 | 清理缓存并重新加载词库 |

#### 字典编辑

| 命令 | 功能 | 说明 |
|------|------|------|
| `:IMAdd` | 批量添加词 | 打开批量添加界面，可输入多行 `编码<Tab>词` |
| `:IMRemove <词1> [词2] ...` | 删除词 | 支持批量删除 |
| `:IMReorder <词> [编码]` | 重排序 | 调整词在对应编码下的显示顺序 |
| `:IMSearch <词>` | 搜索词 | 在词库中搜索指定词，显示所有编码 |

#### 插件管理

| 命令 | 功能 |
|------|------|
| `:IMReload` | 重新加载插件和词库 |

### 词库同步逻辑对比

| 功能 | 命令 | 数据源 | 目标 | 删除行为 |
|------|------|--------|------|----------|
| **初始化** | `:IMInit` | YAML | DB | YAML 中删除的，DB 中也会删除（强制覆盖） |
| **备份** | `:IMBackup` | DB | YAML | DB 中删除的，YAML 中也会删除（强制覆盖） |
| **同步** | `:IMSync` | YAML | DB | YAML 中删除的，DB 中**不删除**（只增加） |

**使用建议**：
- **日常添加新词**：编辑 YAML → `:IMSync`（推荐）
- **批量添加新词**：`:IMAdd` → 自动保存到 YAML → 自动同步到 DB
- **初始化数据库**：修改 YAML → `:IMInit`（用 YAML 强制覆盖 DB）
- **备份词库**：使用输入法自动添加的词 → `:IMBackup`（用 DB 覆盖 YAML）


## 配置

### 文件路径说明

插件的文件存储路径如下：

- **数据库文件**：`~/.config/nvim/sbzr.nvim.im.db/` 目录
  - 例如：`~/.config/nvim/sbzr.nvim.im.db/base.dict.db`
- **词库文件（YAML）**：`~/.local/share/nvim/lazy/sbzr.nvim.im/dict/` 目录
  - 例如：`~/.local/share/nvim/lazy/sbzr.nvim.im/dict/base.dict.yaml`
- **缓存文件**：`~/.vim_cache/sbzr_nvim_im/` 目录
- **频率文件**：`~/.local/share/nvim/sbzr_nvim_im_word_freq.txt`

### 高级配置

```lua
-- 补全设置
vim.g.ZFVimIM_matchLimit = 2000      -- 匹配结果的最大数量（默认: 2000）
vim.g.ZFVimIM_predictLimit = 1000    -- 预测输入的最大数量（默认: 1000）
vim.g.ZFVimIM_sentence = 1           -- 启用句子补全（默认: 1）
vim.g.ZFVimIM_crossable = 2          -- 跨数据库搜索（默认: 2）
                                    -- 0: 禁用, 1: 仅完全匹配, 2: 包含预测, 3: 包含部分匹配

-- 显示设置
vim.g.ZFVimIM_freeScroll = 0         -- 自由滚动模式（默认: 0）
                                    -- 1 时，候选超过 10 个也可滚动

-- 按键映射设置
vim.g.ZFVimIM_keymap = 1             -- 启用按键映射（默认: 1）
vim.g.ZFVimIM_key_pageUp = ['-', ',']    -- 上翻页键
vim.g.ZFVimIM_key_pageDown = ['=', '.']  -- 下翻页键

-- 状态栏显示设置
vim.g.ZFVimIME_IMEStatus_tagL = ' <'  -- 左标签
vim.g.ZFVimIME_IMEStatus_tagR = '> '  -- 右标签
```

### 词库文件格式

```yaml
# YAML 格式（推荐）
a	啊	阿	吖
ai	爱	唉	埃
nihao	你好	你号
ceshi	测试	测时
```

## 按键映射

### 基本操作

| 按键 | 功能 |
|------|------|
| `;;` | 切换输入法开/关（Normal/Insert/Visual 模式） |
| `;,` | 打开添加词对话框 |
| `;.` | 打开删除词对话框 |

### 输入中的操作（Insert 模式，输入法启用时）

| 按键 | 功能 |
|------|------|
| `0-9` | 选择候选词（0 是第 10 个候选） |
| `<Space>` | 确定第一个候选 |
| `<Enter>` | 关闭候选菜单 |
| `<Esc>` | 取消输入并关闭候选菜单 |
| `<Backspace>` | 删除 1 个字符 |
| `<Tab>` / `<S-Tab>` | 上下移动候选 |
| `-` / `=` 或 `,` / `.` | 上下翻页 |
| `[` / `]` | 左/右分割确定 |
| `<C-d>` | 删除当前选中的候选词 |

## 故障排除

### 词库未加载

**首先运行 `:IMInfo` 查看详细状态信息！**

**检查方法**：

```vim
" 检查词库文件是否存在
:lua print(vim.fn.filereadable(vim.fn.stdpath("data") .. "/lazy/sbzr.nvim.im/dict/base.dict.yaml"))

" 查看错误信息
:messages
```

### 常见问题

| 问题 | 解决方法 |
|------|----------|
| UTF-8 编码错误 | 确保词库文件是 UTF-8 编码，不是二进制 `.db` 文件 |
| 词库更改后未反映 | 运行 `:IMClear` 清理缓存并重新加载 |
| 需要重新加载插件 | 运行 `:IMReload` |

### 词库管理

**添加新词**：
- 使用 `:IMAdd` 批量添加（推荐）
- 或直接编辑 YAML 文件，然后运行 `:IMSync`

**删除词**：
- 使用 `:IMRemove <词1> [词2] ...` 批量删除

**词库管理**：
- **初始化**：`:IMInit` - 从 YAML 导入到 DB（强制覆盖）
- **备份**：`:IMBackup` - 从 DB 导出到 YAML（覆盖 YAML）
- **同步**：`:IMSync` - 从 YAML 新增到 DB（只增加，不删除）

## 相关链接

- 原项目：[ZSaberLv0/ZFVimIM](https://github.com/ZSaberLv0/ZFVimIM)
- 本插件仓库：[iamcheyan/sbzr.nvim.im](https://github.com/iamcheyan/sbzr.nvim.im)
- 基础适配版本：[iamcheyan/ZFVimIM](https://github.com/iamcheyan/ZFVimIM)
