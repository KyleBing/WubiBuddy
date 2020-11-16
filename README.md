
<img width="702" alt="main file" src="https://user-images.githubusercontent.com/12215982/81660658-9e83b800-946d-11ea-8689-879ea2674b12.png">
<img width="618" alt="root file" src="https://user-images.githubusercontent.com/12215982/81660669-a17ea880-946d-11ea-9cdc-72c0a6ccd517.png">


# 码表助手 for Rime

> macOS version v10.15

该工具跟 [86极点码表配置方案](https://github.com/KyleBing/rime-wubi86-jidian) 搭配使用
有好的想法可以从 `issue` 中提出来


## 下载：
[码表助手](https://github.com/KyleBing/WubiBuddy/releases)


## 使用说明

如果提示无法打开，文件损坏什么的，所 app 移到应用程序 `Applications` 文件夹后，这样操作：

```bash
sudo xattr -rd com.apple.quarantine /Applications/码表助手.app/
```

这样应该就能打开了。


1. __添加__：输入词条和编码后，回车添加用户词，用户词添加到 `wubi86_jidian_addition.dict.yaml` 文件中
2. __删除__：选中词条按<kbd>删除</kbd>按钮或 <kbd>Backspace</kbd> 键删除选中的词条
3. __加至主码表__：选中词条后选择『数据』中的『插入词条到主码表文件』会把选中的词条添加到 `wubi86_jidian.dict.yaml` 文件中，并删除当前码表中的词条  `wubi86_jidian_addition.dict.yaml` 
4. __排序__：词条添加至主码表之后，如果词条的优先级不对，你可以打开『主码表』搜索对应词条进行排序。 注意：该操作是调换的当前显示的上下两个词条的位置

添加用户词后，需要手动布署一下，鼠须管的布署快捷键是：<kbd>control</kbd> + <kbd>option</kbd> + <kbd>`</kbd>

## 流程

<img width="500" alt="version1" src="https://user-images.githubusercontent.com/12215982/79714194-9fa84600-8302-11ea-995d-15239ef52c1e.png"/>


## 进度

[码表助手：功能列表](https://github.com/KyleBing/WubiBuddy/projects/1)

