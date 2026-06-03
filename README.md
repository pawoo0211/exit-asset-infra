# exit-asset-infra

로컬 kind(Colima Docker 런타임) 기반 인프라(Kafka, Airflow, PostgreSQL, MongoDB, Prometheus, Grafana, MinIO, Spark, StarRocks, Zeppelin, StreamPark, Flink, ClickHouse, Loki) +
맥미니 로컬 서비스(Hadoop, Hue)를 함께 운영하는 프로젝트입니다.

## 운영 포인트 (2026-03-28 기준)

- 권장 런타임: Colima Docker + kind 멀티노드(1 control-plane + 2 workers)
- 권장 리소스: Colima `10 vCPU / 16GiB / 140GiB`
- kind 클러스터 설정 파일: `scripts/kind-multinode.yaml`
- kubeconfig: `/tmp/kind-kubeconfig` (운영 스크립트에서 사용)
- 제외 모듈: OpenMetadata, Dinky
- 자동 복구: `./scripts/keep-infra-alive.sh start` (kubeconfig 갱신 + 포트포워드/Hue 유지)
- MM2는 상시 운영보다 필요 시 배포/검증/제거(on-demand) 권장
- 배포 기본 모드: Argo CD GitOps (`./scripts/deploy-all.sh` 실행 시 기본)

빠른 점검 명령:

```bash
kind export kubeconfig --name infra-local --kubeconfig /tmp/kind-kubeconfig
KUBECONFIG=/tmp/kind-kubeconfig kubectl get nodes
KUBECONFIG=/tmp/kind-kubeconfig kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded
KUBECONFIG=/tmp/kind-kubeconfig ./scripts/keep-infra-alive.sh status
```

## 중요: k3s 비포함 컴포넌트

아래는 **k3s에 올리지 않고 맥미니 로컬에서 직접 실행**합니다.

- Hadoop(HDFS/YARN/JobHistory)
- Hue

즉, `kubectl get ns` / `kubectl get pods -A` 에서 Hadoop/Hue는 보이지 않는 것이 정상입니다.

로컬 스크립트 위치:

- `/Users/parksang-kwon/hadoop-local`
- `/Users/parksang-kwon/hue-local`

로컬 실행:

```bash
/Users/parksang-kwon/hadoop-local/start-services.sh
/Users/parksang-kwon/hadoop-local/status-hadoop.sh
/Users/parksang-kwon/hue-local/status-hue.sh
```

로컬 중지:

```bash
/Users/parksang-kwon/hadoop-local/stop-services.sh
```

## 실행 방법

### 1) 클러스터 시작

현재 권장 방식(kind 멀티노드):

```bash
colima start --cpu 10 --memory 16 --disk 140 --runtime docker --kubernetes=false
kind create cluster --name infra-local --config ./scripts/kind-multinode.yaml
kind export kubeconfig --name infra-local --kubeconfig /tmp/kind-kubeconfig
```

기존 k3s 방식(레거시):

```bash
./scripts/setup-k3s-colima.sh
```

### 2) 전체 배포 (권장)

기본 배포 모드는 Argo CD GitOps이며, 현재는 GitOps-only로 운영합니다.

```bash
./scripts/deploy-all.sh
```

위 명령은 아래를 수행합니다.
- Argo CD 설치/업데이트
- `argocd/apps/root.yaml` + `argocd/apps/children/*.yaml` 적용
- 애플리케이션 자동 동기화(Automated Sync)
- 포트포워드 재기동

개별 모듈 `./scripts/deploy.sh <module>` 방식은 비활성화되었습니다.

```bash
./scripts/deploy.sh argocd
./scripts/deploy-via-argocd.sh
```

기존 실행 순서(레거시 참고용):

```bash
./scripts/setup-k3s-colima.sh       # 1) Colima/k3s 시작 (클러스터 없을 때)
./scripts/deploy-all.sh             # 2) 전체 배포 + port-forward
```

또는 한 번에:

```bash
./scripts/deploy-all.sh             # 클러스터 없으면 Colima 자동 시작 후 배포
```

**상태 확인 (k3s/파드/서비스/port-forward):**

```bash
./scripts/status.sh
```

- `deploy-all.sh`는 **맨 끝**에서 모든 UI용 port-forward를 백그라운드로 띄웁니다.
- **중간에 실패하면** port-forward 단계까지 오지 못해, Kafka UI / Airflow / Prometheus 등 URL이 동작하지 않습니다.

**UI 접속이 안 될 때 (localhost:18080, 18081, 19090 등 연결 거부):**

```bash
./scripts/start-port-forwards.sh    # 배포된 서비스만 port-forward 다시 실행
```

**port-forward를 계속 유지하고 싶을 때(자동 복구):**

```bash
./scripts/keep-port-forwards.sh start
./scripts/keep-port-forwards.sh status
./scripts/keep-port-forwards.sh stop
```

**클러스터/포트포워드/Hue까지 지속 유지(권장):**

```bash
./scripts/keep-infra-alive.sh start
./scripts/keep-infra-alive.sh status
./scripts/keep-infra-alive.sh stop
```

동작:
- kind kubeconfig 자동 갱신
- CrashLoopBackOff/Error 파드 자동 재생성
- 포트포워드 자동 재기동
- Hue 컨테이너(`hue-local`) 자동 재기동

**`another operation (install/upgrade/rollback) is in progress` (kafka-topics 등 Helm 멈춤):**

```bash
./scripts/fix-kafka-topics-helm.sh    # kafka-topics pending 상태 자동 정리
./scripts/deploy-all.sh                # 다시 배포
```

- `deploy-all.sh`가 자동으로 pending Helm 릴리스를 정리하고 재시도하지만, 완전히 막혀있으면 위 스크립트로 수동 정리 후 재배포하세요.

- `deploy-all.sh`가 끝까지 성공했는데도 브라우저에서 접속이 안 되면 (터미널을 닫았거나 port-forward가 죽은 경우) 위 스크립트만 다시 실행하면 됩니다.
- `deploy-all.sh`가 중간에 실패한 경우에도, 이미 배포된 서비스(Kafka UI, Airflow, Prometheus 등)는 위 스크립트로 port-forward만 걸 수 있습니다.

위 스크립트는 아래 **k3s 컴포넌트만** 처리합니다.
- Kafka(3 brokers, Strimzi Operator 기반)
- Kafka Mirror Cluster (`kafka-mirror`, optional)
- Kafka MirrorMaker2 (`mm2-local-to-mirror`, optional)
- Kafka Topics/ACL bootstrap
- Kafka UI
- MinIO
- Airflow
- PostgreSQL
- MongoDB
- Spark (Spark Operator + Spark History UI)
- StarRocks
- Prometheus
- Grafana
- Hive Metastore (external HDFS 연동)
- Iceberg catalog API (Nessie)
- Paimon/Iceberg Hive catalog 설정
- Schema Registry
- Kafka Connect
- Debezium Connect
- Harbor
- Argo CD
- Zeppelin
- StreamPark
- Flink
- PydanticAI Runtime
- ClickHouse
- Loki
- UI 포트포워딩 백그라운드 실행

제외된 모듈:
- OpenMetadata
- Dinky

### 3) 개별 배포

```bash
./scripts/deploy.sh kafka
./scripts/deploy.sh kafka-mm2
./scripts/deploy.sh kafka-topics
./scripts/deploy.sh airflow
./scripts/deploy.sh postgresql
./scripts/deploy.sh prometheus
./scripts/deploy.sh grafana
./scripts/deploy.sh minio
./scripts/deploy.sh mongodb
./scripts/deploy.sh spark
./scripts/deploy.sh starrocks
./scripts/deploy.sh hive-metastore
./scripts/deploy.sh iceberg
./scripts/deploy.sh paimon
./scripts/deploy.sh schema-registry
./scripts/deploy.sh kafka-connect
./scripts/deploy.sh debezium
./scripts/deploy.sh harbor
./scripts/deploy.sh argocd
./scripts/deploy.sh zeppelin
./scripts/deploy.sh streampark
./scripts/deploy.sh flink
./scripts/deploy.sh pydanticai
./scripts/deploy.sh clickhouse
./scripts/deploy.sh loki
```

## UI 접속 URL

- Kafka UI: `http://localhost:18080/ui` (클러스터: local-kafka, 브로커: `http://localhost:18080/ui/clusters/local-kafka/brokers`). 직접 URL/새로고침이 되도록 context path `/ui`로 배포됨.
- Airflow UI: `http://localhost:18081`
- MinIO Console(UI): `http://localhost:19001`
- MinIO API(S3): `http://localhost:19000`
- MongoDB: `mongodb://admin:admin1234@localhost:27017/?authSource=admin`
- StarRocks FE(MySQL): `localhost:19030`
- Hive Metastore(Thrift): `thrift://localhost:19083`
- Nessie API: `http://localhost:19120`
- Schema Registry: `http://localhost:18085`
- Kafka Connect REST: `http://localhost:18086`
- Debezium Connect REST: `http://localhost:18087`
- Prometheus UI: `http://localhost:19090`
- Grafana UI: `http://localhost:13000`
- Harbor UI: `http://localhost:18443`
- Argo CD UI: `http://localhost:18083`
- ksqlDB UI(사용 시): `http://localhost:18088`
- Spark History UI(k3s): `http://localhost:18084`
- Zeppelin UI: `http://localhost:18089`
- StreamPark UI: `http://localhost:18092`
- Flink UI: `http://localhost:18093`
- PydanticAI Runtime: `http://localhost:18094`
- ClickHouse Web UI: `http://localhost:18102`
- ClickHouse HTTP: `http://localhost:18101`
- Loki API: `http://localhost:18104`

로컬(비-k3s) UI:

- Hue: `http://localhost:18888`
- YARN ResourceManager: `http://localhost:8088`
- MapReduce JobHistory: `http://localhost:19888`

Hue가 열리지 않으면:

```bash
/Users/parksang-kwon/hue-local/start-hue.sh
/Users/parksang-kwon/hue-local/status-hue.sh
```

## Kafka 배포 방식

- 현재 Kafka는 Strimzi Operator로 배포됩니다.
- Strimzi Operator Helm 릴리즈: `strimzi-kafka-operator` (namespace: `kafka`)
- Kafka 클러스터 CR: `kafka/manifests/strimzi-kafka.yaml`
- 내부 bootstrap 주소: `kafka-local-kafka-bootstrap:9092`

### Kafka MM2 (MirrorMaker2)

- 소스 클러스터: `kafka-local`
- 타깃 클러스터: `kafka-mirror`
- MM2 리소스: `mm2-local-to-mirror`

배포:

```bash
./scripts/deploy.sh kafka-mm2
```

제거:

```bash
./kafka/mm2/scripts/remove.sh
```

확인:

```bash
kubectl -n kafka get kafka,kafkamirrormaker2,pods | grep -E 'kafka-local|kafka-mirror|mm2-local-to-mirror|NAME'
```

주의:
- MM2는 로컬 단일 노드에서 메모리/CPU 부담이 커서 기존 서비스 안정성에 영향을 줄 수 있습니다.
- 장시간 상시 운영보다는 필요 시 배포 후 검증하고 제거하는 방식(on-demand)을 권장합니다.

## Argo CD GitOps 구성

- Root App: `argocd/apps/root.yaml`
- Child Apps: `argocd/apps/children/apps.yaml`
- Project: `argocd/apps/children/project.yaml`

수동 적용:

```bash
kubectl -n argocd apply -f argocd/apps/children/project.yaml
kubectl -n argocd apply -f argocd/apps/children/apps.yaml
kubectl -n argocd apply -f argocd/apps/root.yaml
kubectl -n argocd get applications
```

GitOps 부트스트랩 스크립트:

```bash
./scripts/deploy-via-argocd.sh
```

주의(Private Repository):
- Argo CD가 GitHub private repo에 접근하려면 repository credential(PAT 또는 SSH key) 등록이 필요합니다.
- 미등록 시 Application의 Sync Status가 `Unknown`으로 남고, `Repository not found` 오류가 발생합니다.

등록 스크립트:

```bash
GITHUB_USERNAME=<github-id> GITHUB_TOKEN=<pat> ./scripts/argocd-register-repo.sh
```

## PydanticAI 설치/운영

로컬 Python venv 설치(권장):

```bash
python3.12 -m venv /Users/parksang-kwon/.venvs/pydanticai
/Users/parksang-kwon/.venvs/pydanticai/bin/pip install --upgrade pip
/Users/parksang-kwon/.venvs/pydanticai/bin/pip install pydantic-ai
```

Kubernetes Runtime(Argo CD 동기화 대상):
- 매니페스트: `pydanticai/manifests/pydanticai.yaml`
- 포트포워드: `./pydanticai/scripts/port-forward.sh 18094 --background`

## 관리자 계정 정보

- Airflow
  - ID: `admin`
  - PW: `admin`
- Grafana
  - ID: `admin`
  - PW: `admin1234`
- MinIO
  - ID: `minioadmin`
  - PW: `minioadmin123`
- MongoDB
  - ID: `admin`
  - PW: `admin1234`
- Harbor
  - ID: `admin`
  - PW: `Harbor12345`
- Argo CD
  - ID: `admin`
  - PW: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode`

참고:
- Kafka UI, Prometheus, ksqlDB는 기본적으로 별도 로그인 계정이 없습니다.
- Loki는 별도 웹 UI가 없어 기본적으로 Grafana(`http://localhost:13000`)의 Explore에서 사용합니다.
- PostgreSQL은 웹 UI가 아니라 DB 서비스입니다.
- MinIO는 기본 관리자 계정으로 배포됩니다. 운영 환경에서는 Secret 분리 및 비밀번호 변경을 권장합니다.
- MongoDB는 기본 root 계정으로 배포됩니다. 운영 환경에서는 Secret 분리 및 비밀번호 변경을 권장합니다.
- Harbor는 로컬 편의를 위해 TLS/persistence/trivy를 비활성화한 값으로 배포됩니다. 운영 환경에서는 TLS, 외부 저장소, 취약점 스캐너를 반드시 활성화하세요.

## Harbor + Argo CD 배포

```bash
./scripts/deploy.sh harbor
./harbor/scripts/port-forward.sh 18443 --background

./scripts/deploy.sh argocd
./argocd/scripts/port-forward.sh 18083 --background
```

## GitHub Private Repository 연동 가능 여부

가능합니다. Harbor/Argo CD 모두 GitHub private repository와 연동할 수 있습니다.

- Argo CD: Repository credential(HTTPS PAT 또는 SSH key)을 등록하면 private repo에서 매니페스트/Helm/Kustomize를 동기화할 수 있습니다.
- Harbor: GitHub 소스 자체를 직접 pull 하지는 않지만, GitHub Actions 등에서 이미지를 빌드해 Harbor private project로 push하는 방식으로 안전하게 사용할 수 있습니다.
- 핵심 권한: Argo CD에는 `repo:read` 수준 최소 권한, CI에는 Harbor push 권한 최소 계정을 분리해 사용하는 것이 좋습니다.

## 로컬 Hadoop/Hue 운영

- Hadoop 토폴로지: NameNode 1, DataNode 2, ResourceManager 1, NodeManager 2
- 점검 스크립트:
  - `/Users/parksang-kwon/hadoop-local/status-hadoop.sh`
  - `/Users/parksang-kwon/hadoop-local/check-paimon-iceberg.sh`
- Iceberg/Paimon 스모크 테스트:

```bash
/Users/parksang-kwon/hadoop-local/run-lakehouse-smoke-tests.sh
```

## Hadoop + MinIO 운영 메모

- 메인 스토리지는 HDFS, MinIO는 서브(S3 호환 연동/교환/아카이브) 용도로 사용 권장
- Spark s3a endpoint 예시: `http://minio.minio.svc.cluster.local:9000`
- MinIO Console은 `http://localhost:19001`로 접속 가능

## 외부 HDFS 기준 메타데이터 구성

- Hadoop(HDFS)은 k3s 내부가 아닌 맥미니 로컬에서 실행합니다.
- Hive Metastore warehouse는 `hdfs://192.168.5.2:9000`(Colima host) 를 사용하도록 설정되어 있습니다.
- Paimon/Iceberg catalog ConfigMap도 동일한 외부 HDFS URI를 기준으로 생성됩니다.

## dbt 설치

dbt는 Python 3.12 venv에 설치되어 있습니다.

```bash
/Users/parksang-kwon/.venvs/dbt/bin/dbt --version
```

원하면 셸에 alias를 추가해서 `dbt`로 바로 실행할 수 있습니다.

## Spark + 기존 HDFS 연동

- Spark는 k3s에 배포되고, HDFS는 맥미니 로컬 Hadoop을 사용합니다.
- 기본 HDFS URI: `hdfs://192.168.5.2:9000`
- HDFS 연동 설정 파일:
  - `spark/manifests/hadoop-config.yaml`
  - `spark/manifests/spark-pi-hdfs.yaml`

배포:

```bash
./scripts/deploy.sh spark
./spark/scripts/port-forward.sh 18084 --background
```

샘플 Spark 잡 실행:

```bash
./spark/scripts/submit-pi-hdfs.sh
```

Driver UI 확인(실행 중):

```bash
./spark/scripts/port-forward-driver-ui.sh spark-pi-hdfs 4040
```

## 종료 방법

### 런타임만 중지

```bash
./scripts/shutdown-all.sh
```

(다시 쓸 때: `./scripts/deploy-all.sh` 실행. UI 접속이 안 되면 `./scripts/start-port-forwards.sh` 실행.)

### 리소스까지 정리 후 중지

```bash
./scripts/shutdown-all.sh down
```
