-- sbzr.nvim.im - Neovim 中文输入法插件配置
-- 使用方法：将此文件复制到 ~/.config/nvim/lua/plugins/sbzr.nvim.im.lua
-- 仓库地址：https://github.com/iamcheyan/sbzr.nvim.im

return {
  {
    "iamcheyan/sbzr.nvim.im",
    lazy = false,
    init = function()
      vim.g.ZFVimIM_dict_path = vim.fn.expand("~/.dotfiles/rime/sbzr.chrome.extension/dicts/base.dict.yaml")
    end,
  },
}
