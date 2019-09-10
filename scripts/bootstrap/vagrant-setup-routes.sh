#!/bin/bash

set -euo pipefail

case "$(hostname)" in
  worker-0)
    # 10.200.1.0/24はworker-0のCNIのブリッジネットワーク設定用のサブネット
    # 10.240.0.21はworker-1のprivateIP
    route add -net 10.200.1.0/24 gw 10.240.0.21
    route add -net 10.200.2.0/24 gw 10.240.0.22
    ;;
  worker-1)
    route add -net 10.200.0.0/24 gw 10.240.0.20
    route add -net 10.200.2.0/24 gw 10.240.0.22
    ;;
  worker-2)
    route add -net 10.200.0.0/24 gw 10.240.0.20
    route add -net 10.200.1.0/24 gw 10.240.0.21
    ;;
  *)
    route add -net 10.200.0.0/24 gw 10.240.0.20
    route add -net 10.200.1.0/24 gw 10.240.0.21
    route add -net 10.200.2.0/24 gw 10.240.0.22
    ;;
esac
