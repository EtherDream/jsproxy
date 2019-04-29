nginx 日志备份服务

## 说明

nginx 长时间运行会导致日志文件过大，该服务定期备份日志到 `backup` 目录，并进行压缩。


## 依赖

用到了 `brotli` 压缩工具，执行 `setup-brotli.sh` 安装。

最终安装在 `/home/jsproxy/tools/brotli`。


## 启动

```bash
./svc.sh &
```

使用 `jsproxy` 用户运行，无需 `root`。