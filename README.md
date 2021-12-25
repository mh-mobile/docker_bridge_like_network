# Network Namespace用のスクリプトの使い方

## Network Namespaceの作成

```bash
$ ./create_docker_like_bridge_network.sh 
```

## Network Namespaceの削除

```bash
$ ./delete_docker_like_bridge_network.sh 
```

# tinetの設定ファイル用の使い方

## Dockerコンテナの起動

```bash
$ tinet up -c docker_bridge_like_network_spec.yaml | sudo sh -x
```

## Dockerコンテナの設定

```bash
$ tinet conf -c docker_bridge_like_network_spec.yaml | sudo sh -x
```

## Dockerコンテナの削除

```bash
$ tinet down -c docker_bridge_like_network_spec.yaml | sudo sh -x
```

