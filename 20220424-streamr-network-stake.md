# Streamr DATA 质押赚取Token

> 入坑需谨慎，本文不构成任何投资建议

## 操作步骤

[Streamr 网络](https://streamr.network/)质押 mining 具体步骤：

1. 申请 EVM 兼容链钱包，推荐 [Metamask](https://metamask.io/)。[参考教程](https://academy.binance.com/en/articles/how-to-use-metamask)
2. [将 MetaMask 钱包切换至 Polygon 链](https://academy.binance.com/en/articles/how-to-add-polygon-to-metamask) 
3. 向钱包内转入 Matic，可以由交易所转入，注意转账时需选择 Polygon 链。得益于 Polygon 链的超低费用，可以转入 10 Matic 或更少均可，来作为 Gas 费。
4. 向钱包内转入 DATA，单账户支持最大 10000 DATA 质押
5. 部署 Streamr Miner 程序，自动生成 Miner 公钥
6. 将私钥导入到 Streamr Miner 
7. 启动 miner 开始 mining

## 前期准备

正式开始安装质押程序前需做如下准备：

- Ubuntu 20.04 LTS 系统用于安装矿机程序
- Metamask 钱包**私钥**（存入一定数量的 MATIC、DATA）

## 安装部署

如下所有操作均在 `root` 用户下完成。操作前请使用 `sudo su` 切换至 `root` 用户。

- 安装 docker 及 docker-compose

```


curl -SL https://github.com/docker/compose/releases/download/v2.4.1/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
```
- 创建工作目录

```
mkdir  /opt/streamr/docker
```
- 

```
 
```
- 

```
```
- 

```
```
- 

```
```