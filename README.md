
<img width="629" alt="v1 13" src="https://user-images.githubusercontent.com/12215982/80066778-36793a80-856f-11ea-8f7f-504ee130222b.png">

# 码表助手 for Rime
> macOS version v10.15

该工具跟 [86极点码表配置方案](https://github.com/KyleBing/rime-wubi86-jidian) 搭配使用
有好的想法可以从 `issue` 中提出来

## 下载：
[码表助手v1.13](https://github.com/KyleBing/WubiBuddy/releases)

## 使用说明
1. 输入编码和词语后，回车添加用户词
2. 选中词条按<kbd>删除</kbd>按钮或 <kbd>Backspace</kbd> 键删除词条
3. 选中词条后选择【数据】中的【插入词条到主码表文件】会把选中的词条添加到 `wubi86_jidian.dict.yaml` 文件中，并删除当前码表中的词条
4. 点【数据】-【排序】实现当前码表排序
添加用户词后，需要手动布署一下，鼠须管的布署快捷键是：<kbd>control</kbd> + <kbd>option</kbd> + <kbd>`</kbd>

## 流程

<img width="500" alt="version1" src="https://user-images.githubusercontent.com/12215982/79714194-9fa84600-8302-11ea-995d-15239ef52c1e.png"/>


## 进度

- [ ] 修改用户词
- [ ] 候选词位置指定
- [ ] 拖动排序用户词
- [ ] 寻找更方便的方式添加用户词，而非独立app窗口模式
- [ ] 输入编码后，在当前用户词中查看已存在的词条（或者在原主词库文件中查找）
- [ ] 排序根字典文件


- **2020-04-22**
    - [x] 手动排序
    - [x] 选择指定词添加到主码表文件 `wubi86_jidian.dict.yaml` 
        - [x] 并删除当前码表中的词条
        - [ ] 检测主文件中的不规范词条
    - [x] 批量删除用户词
    - [x] 中英文界面支持

- **2020-04-19**
    - [x] 检测码表中不规范的词条，并做相关处理 `
    
- **2020-04-15**
    - [x] 挑选 `Rime` 配置文件中的一个文件，作为添加用户词的目的地   `wubi86_jidian_addition.dict.yaml`
    - [x] 定位用户目录并获取词库文件内容
    - [x] 表格显示内容
    - [x] 添加用户词
    - [x] 删除用户词



## 延伸
如果自己技术还可以，把工具做出来了，就想进一步优化了。

- [ ]  可以打开任意配置文件进行词库的整理操作
