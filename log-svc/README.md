nginx 日志备份服务

## 说明

nginx 长时间运行会导致日志文件过大，该服务定期备份日志到 `backup` 目录，并进行压缩。


## 启动

```bash
./svc.sh &
```

使用 `jsproxy` 用户运行，无需 `root`。