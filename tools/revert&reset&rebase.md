# git reset、revert、rebase总结

- [git重置(reset)、回滚(revert)、变基(rebase)总结](https://blog.csdn.net/I_AM_KK/article/details/109864776?spm=1001.2101.3001.6661.1&utm_medium=distribute.pc_relevant_t0.none-task-blog-2~default~CTRLIST~default-1-109864776-blog-72897693.pc_relevant_multi_platform_whitelistv2_ad_hc&depth_1-utm_source=distribute.pc_relevant_t0.none-task-blog-2~default~CTRLIST~default-1-109864776-blog-72897693.pc_relevant_multi_platform_whitelistv2_ad_hc&utm_relevant_index=1)

> 前提：每次我们看到的commit都是经过-本地（工作区）->add(缓存区)->commit(提交）才会有哈希值出现。

## git reset

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202207262231002.png)

#### git reset有三种模式

- `git reset (–mixed)`（默认）

重置到2，工作区内容是2～3之间的内容，暂存区为空，离3差add和commit

- `git reset –soft`

重置到2，工作区内容是2～3之间的内容，暂存区为2～3的内容，离3差commit

- `git reset –hard`

重置到2，工作区内容空，暂存区内容空，再也回不去啦

## git rebase

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202207262235683.png)

git rebase 当两个分支不在一条直线上，需要执行merge操作时，使用该命令操作。

## git revert

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202207262235851.png)

revert执行所有与3到4相反（增加就删除，删除就增加）的操作形成新的提交，这个提交所有内容和3一模一样。

再执行一次revert操作会怎么样？（撤回撤回的操作->就会回到4啦。当然，还是新增加一个提交，这个提交和4一模一样。）

![](https://cdn.jsdelivr.net/gh/mouweng/FigureBed/img/202207262236702.png)