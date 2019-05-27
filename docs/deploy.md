# 站点部署

## 使用自己的 github.io

1.进入 https://github.com/zjcqoo/zjcqoo.github.io 点击 fork。

2.进入 Settings 页面，仓库重命名成 `my.github.io`（假设用户名为 `my`）

3.进入 `conf.js` 文件，参考备注修改：

* 节点列表（`node_map` 字段，包括节点 id 和节点主机）

* 默认节点（`node_default` 字段，指定节点 id）

4.访问 `https://my.github.io` 预览

> 本项目支持子路径。仓库可重命名成任何名字（例如 x），然后创建 `gh-pages` 分支，通过 `https://my.github.io/x` 也能访问。


## 使用任意域名

[自定义 github pages 域名](https://help.github.com/en/articles/using-a-custom-domain-with-github-pages)，或者将文件发布到其他 Web 服务器上。
