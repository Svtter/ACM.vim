ACM.vim
===

支持ACM的vim插件，用于对单文件的编译运行。

操作系统
---

- Linux
    - 需要gcc，g++，gnome-terminal, gdb的支持。
- Windows
    - 需要将gcc添加到PATH中.

安装
---

本插件支持vundle进行安装，安装vundle请参见: https://github.com/gmarik/Vundle.vim

安装方法是，将'Svtter/ACM.vim'添加到你的vimrc, 然后`:PluginInstall`

注意
---

编译选项可以从本插件的源码中找到并且修改。

按键
---

本插件在一定程度上限制了这几个键位使用，如果有更好的方案请pull request

- F9 一键保存、编译、连接存并运行
- Ctrl + F9 一键保存并编译
- Ctrl + F10 一键保存并连接
- F8 编译调试（仅限于单文件)(gdb)


LICENSE
---

