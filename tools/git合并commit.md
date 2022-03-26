# Git合并commit

## 参考

- [(Git)合并多个commit](https://segmentfault.com/a/1190000007748862)

- [Git log 不太好看，我们来合并 commit吧](https://learnku.com/articles/9377/git-log-is-not-very-good-lets-merge-commit)

## 合并

> 有时候我们完成✅一个feature，可能会有多次commit。但是commit多了之后呢，我们的git log就会非常乱，所以合并commit就有存在的必要。

#### 1. 查看git log

```shell
$ git log
commit 3ca6ec340edc66df13423f36f52919df......
commit 1b4056686d1b494a5c86757f9eaed844......
commit 53f244ac8730d33b353bee3b24210b07......
commit 3a4226b4a0b6fa68783b07f1cee7b688......
```

#### 2. git rebase

- 从HEAD版本开始往过去数n个版本

```shell
git rebase -i HEAD~[n]

git rebase -i HEAD~3
```

- 指名要合并的版本之前的版本号（请注意这个版本号不参与合并）

```shell
git rebase -i [版本号]

git rebase -i 3a4226b
```

#### 3. 选取要合并的提交

- 执行了rebase命令之后，会弹出一个窗口，头几行如下：

```shell
pick 3ca6ec3   'commit log'
pick 1b40566   'commit log'
pick 53f244a   'commit log'
pick 73f5423   'commit log'

# Commands:
# p, pick = use commit
# r, reword = use commit, but edit the commit message
# e, edit = use commit, but stop for amending
# s, squash = use commit, but meld into previous commit
# f, fixup = like "squash", but discard this commit's log message
# x, exec = run command (the rest of the line) using shell
# d, drop = remove commit
```

- 将`pick`改为`s`（保留`commit log`）或者`f`（不保留`commit log`）:

```shell
pick 3ca6ec3    'commit log'
s    1b40566   	'commit log'
s    53f244a   	'commit log'
pick 73f5423    'commit log'
```

版本`1b40566`和`53f244a`将合并到`3ca6ec3`,且会保留`commit log`。越往下，版本越新，只会向前合并！

#### 4. 合并提交/放弃提交

保存完成后，你有两个选择:合并提交/放弃提交

- 放弃提交

 ```shell
 git rebase --abort  
 ```

- 合并提交

```shell
git rebase --continue
```

- 如果没有冲突，或者冲突已经解决，则会出现如下的编辑窗口：

```shell
# This is a combination of 4 commits.  
#The first commit’s message is:  
conmmit log
# The 2nd commit’s message is:  
conmmit log
# The 3rd commit’s message is:  
conmmit log
# Please enter the commit message for your changes. Lines starting # with ‘#’ will be ignored, and an empty message aborts the commit.
```

输入wq保存并推出, 再次输入git log查看 commit 历史信息，你会发现这两个 commit 已经合并了。

#### 5.如果commit已经push到远程

> ⚠️建议不要这么做！除非是个人项目或者个人分支

```shell
git push -f  //强制覆盖远程
```

只要合并了commit，合并commit以及之后的commit的hash值都会改变！

## 总结

> 合并commit是一把双刃剑。

建议只在本地仓库(未push到远程)下进行commit合并，合并之后再进行push!

