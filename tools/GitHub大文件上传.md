# GitHub's file size limit of 100.00 MB解决办法

> 上传github发现不给上传100m以上文件的错误,按着提示进行了,用到一个叫lfs的工具专门用来上传大文件的。

## 具体流程

### 安装

```shell
brew install git-lfs

git lfs install
```

### 找出大文件

```shell
find ./ -size +100M
```

### 大文件加入git large file storage上面

```shell
git lfs track ".//huanxin/HXTest/Hyphenate.framework/Hyphenate"
```

### 基本的git操作

```shell
git add .//huanxin/HXTest/Hyphenate.framework/Hyphenate
或者 git add .

git commit -m "Add big file"

git push
```

## 备注

我们一般是已经commit并push一遍之后才发现存在大文件，这个时候需要进行版本会退才可以进行如下操作，不然上一次的commit里面还是存在大文件！

```shell
git log
git reset --hard ac89782e303fd38f423edc678dec823d43a65f35
git lfs track ".//huanxin/HXTest/Hyphenate.framework/Hyphenate"
git add .
git commit -m "Add big file"
git push
```

## 参考
- [GitHub's file size limit of 100.00 MB解决办法](https://juejin.cn/post/6844904205476478989)
