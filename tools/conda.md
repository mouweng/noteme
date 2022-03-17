# anaconda环境搭建

## anaconda下载

- [Anaconda官网下载](https://www.anaconda.com/products/individual#macos)

## anaconda操作

- 查看conda版本

```shell
conda --version
```

- 显示当前存在环境

```shell
conda env list
```

- 创建虚拟环境

```shell
conda create -n [env_name]
conda create -n [env_name] python=3.6
```

⚠️ 创建新的conda环境时，一定要指定python的版本，否则在pycharm中导入conda虚拟环境时，在`/Users/用户名/opt/anaconda3/envs/环境名`这个目录下是没有bin选项的，这样就无法导入了。

- 删除虚拟环境

```shell
conda remove -n [env_name] --all
```

- 激活虚拟环境

```shell
conda activate [env_name]
```

- 退出虚拟环境

```shell
conda deactivate
```

- conda换国内源

```shell
# 清华源
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/

# 中科大源
conda config --add channels https://mirrors.ustc.edu.cn/anaconda/pkgs/free/
```

在`cat ~/.condarc`这个隐藏文件中可以看到目前使用的是哪个conda源

- 查看某个环境下安装的库

```shell
conda list
conda list -n [env_name]
```

- 查找包、安装包、更新包、删除包

```shell
conda search XXX
conda install XXX
conda update XXX
conda remove XXX
```

## jupyter安装与使用

- 下载jupyter

```shell
conda install jupyter notebook
```

- 使用jupyter

```shell
jupyter notebook
```

