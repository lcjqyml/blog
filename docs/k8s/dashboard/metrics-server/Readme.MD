# 概述
* 需要`metrics-server`配合`heapster`使用，才能在`dashboard`看到图形界面统计

# heapster配置说明

* 需要配置`/var/lib/kubelet/config.yaml`，增加如下配置：

```yaml
readOnlyPort: 10255
```
