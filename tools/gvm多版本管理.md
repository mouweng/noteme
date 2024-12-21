# gvm多版本管理

## 安装
- [Golang - 使用 GVM 管理器安裝 Golang 在 Mac 上](https://note.koko.guru/posts/golang-install-on-mac-with-gvm)

## gvm常用命令
```shell
# 展示可以下载的所有go版本
gvm listall
# list已经下载的go版本
gvm list
# 安装某个go版本，如果失败，可以加上-B
gvm install go1.23.3
# 写在某个go版本
gvm uninstall go1.23.3
# 使用某个版本
gvm use go1.23.3
# 默认使用某个版本
gvm use go1.23.3 --default
```

## vscode搭配Go

- [Gvm在Vscode中无法识别并且无法安装Vscode的go环境, vs无法安装Go: Install/Update Tools](https://segmentfault.com/a/1190000043593778)
- [vscode golang环境配置的一些坑](https://neroblackstone.github.io/2019/04/16/vscode-golang-setting/)

vscode中默认的Go环境是不会随着gvm的切换而切换的，可以在设置里面搜索gopath，修改下面的两个参数，指定到gvm中的具体所在的位置。

```json
    "go.goroot": "/Users/wengyifan/.gvm/gos/go1.23.3",
    "go.gopath": "/Users/wengyifan/.gvm/pkgsets/go1.23.3/global",
```

**建议在切换go环境的同时，同时切换vscode里面的go版本。**

但是会忘记切换，所以vscode里面配置一个较高的版本：

- 在使用低版本的go的时候，也会将相关的包安装到高版本的go中，在编译器里面跳转到包的时候，其实是跳转到高版本的go。

- 但在本地go run的时候，用的还是低版本的环境。

相当于在两个环境里面都会安装同样的依赖，不过这样容易导致环境混乱，不建议！