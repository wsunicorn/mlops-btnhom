# Run The System Again On Windows (Step-by-Step)

This guide is aligned with the actual run order we just executed on your machine (PowerShell-first flow).

## 0) Choose terminal mode

You have 2 valid ways:

- Option A (recommended): Git Bash or WSL (can run `.sh` scripts directly).
- Option B: PowerShell (run Docker/Kubernetes commands directly instead of `.sh` wrappers).

The commands below prioritize PowerShell because that is what you are using now.

## 1) Open project root

Project root (attached folder):

`d:/StudyDocument/CongNgheMoi/btNhom/mlops_project`

In Git Bash:

```bash
cd /d/StudyDocument/CongNgheMoi/btNhom/mlops_project
```

In PowerShell:

```powershell
Set-Location D:\StudyDocument\CongNgheMoi\btNhom\mlops_project
```

## 2) Prerequisites checklist

Verify all required tools:

```bash
docker --version
docker compose version
git --version
python --version
```

Optional for K8s:

```bash
kubectl version --client
```

Create shared Docker network (idempotent):

```bash
docker network create aio-network || true
```

PowerShell alternative:

```powershell
docker network create aio-network
```

If it already exists, Docker prints an "already exists" message and that is fine.

## 3) Start infrastructure (Docker)

### 3.1 Prepare MLflow env file

```bash
cp infra/docker/mlflow/.env.example infra/docker/mlflow/.env
```

PowerShell alternative:

```powershell
Copy-Item infra/docker/mlflow/.env.example infra/docker/mlflow/.env -Force
```

### 3.2 Start all stacks

```bash
cd infra/docker
./run.sh up
./run.sh status
cd ../..
```

PowerShell alternative (without shell script):

```powershell
Set-Location infra\docker\mlflow; docker compose up -d
Set-Location ..\kafka; docker compose up -d
Set-Location ..\monitor; docker compose up -d
Set-Location ..\airflow; docker compose up -d
Set-Location ..\..\..
```

### 3.3 Validate URLs

- MLflow: http://localhost:5000
- MinIO console: http://localhost:9001
- Airflow: http://localhost:8080
- Grafana: http://localhost:3000
- Prometheus: http://localhost:9090

## 4) Run data pipeline (current checkpoint)

```bash
cd data-pipeline
python -m venv .venv
./.venv/Scripts/Activate.ps1
pip install -r requirements.txt
```

Pull DVC data:

```bash
dvc pull
```

### Important note about your current state

You already reached this step and got:

- `NoSuchBucket: The specified bucket does not exist`

This means DVC remote is private/offline for your environment (not a local setup issue).

Continue with one of these branches:

### Branch A (if your team gives real S3 access)

```powershell
# Optional: remove MinIO override if you set it before
dvc remote modify --local mys3 --unset endpointurl
dvc remote modify --local mys3 --unset use_ssl
dvc remote modify --local mys3 --unset access_key_id
dvc remote modify --local mys3 --unset secret_access_key

# Set real AWS credentials provided by your team
$env:AWS_ACCESS_KEY_ID="<team_key>"
$env:AWS_SECRET_ACCESS_KEY="<team_secret>"
$env:AWS_DEFAULT_REGION="<team_region>"

dvc pull -v
```

### Branch B (no keys, implement like presentation/demo locally)

Skip `dvc pull` and recreate local data artifacts.

1. Download source dataset (from Kaggle notebook flow):

```powershell
pip install kagglehub
python -c "import kagglehub; print(kagglehub.dataset_download('mohamed444ashraf/customer-churn-data'))"
```

2. Put raw file at:

- `data-pipeline/data/raw/train_period_1.csv`

3. Run preprocessing notebook to create:

- `data-pipeline/data/processed/df_processed.csv`

4. Generate Feast parquet from processed CSV:

```powershell
Set-Location churn_feature_store\churn_features\feature_repo
python prepare_feast_data.py
```

Expected output file:

- `data-pipeline/churn_feature_store/churn_features/feature_repo/data/processed_churn_data.parquet`

Apply Feast registry:

```bash
feast apply
```

Start Redis for online store (new terminal):

```bash
docker run -d --name redis-feast -p 6379:6379 redis:7
```

Materialize features:

```powershell
$ts = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
feast materialize-incremental $ts
```

Quick retrieval test:

```powershell
Set-Location ..\..\..
python scripts/sample_retrieval.py
Set-Location ..\..
```

## 5) Train and register model

```bash
cd model_pipeline
python -m venv .venv
./.venv/Scripts/Activate.ps1
pip install -r requirements.txt
cd src
```

Train:

```bash
bash run_sh/train.sh --training-data-path ../../data-pipeline/churn_feature_store/churn_features/feature_repo/data/processed_churn_data.parquet
```

Copy the `Run ID` from training logs, then evaluate and register:

```bash
RUN_ID=<paste_run_id_here>
bash run_sh/eval.sh --run-id $RUN_ID --eval-data-path ../../data-pipeline/churn_feature_store/churn_features/feature_repo/data/test.parquet --output-path-prediction ../prediction_folder/prediction.csv
bash run_sh/register_model.sh --run-id $RUN_ID --model-name logistic_regression_churn
```

Set alias to champion (replace `<version>` with the registered version shown in logs):

```bash
bash run_sh/set_model_alias.sh --model-name logistic_regression_churn --version <version> --alias champion
bash run_sh/promote_model.sh --model-name logistic_regression_churn --version <version>
```

Return to root:

```bash
cd ../..
```

## 6) Start serving API + UI

```bash
cd serving_pipeline
cp .env.example .env
```

Edit `.env` and set:

- `MODEL_URI=models:/logistic_regression_churn@champion`
- Keep MLflow/MinIO values as default unless you changed infra ports.

Run serving stack:

```bash
docker compose up -d
docker compose ps
```

Check endpoints:

- API docs: http://localhost:8000/docs
- UI: http://localhost:7860
- Health: http://localhost:8000/health

## 7) Stop everything cleanly

Serving:

```bash
cd serving_pipeline
docker compose down
cd ..
```

Infra:

```bash
cd infra/docker
./run.sh down
cd ../..
```

Optional Redis cleanup:

```bash
docker rm -f redis-feast
```

## 8) Optional Kubernetes path

From `infra/k8s`:

```bash
./deploy.sh
./get-dashboard-token.sh
```

Dashboard only:

```bash
./deploy-dashboard.sh
./teardown-dashboard.sh
```

Full cleanup:

```bash
./teardown.sh
```

## 9) Common failures and fixes

- `docker network aio-network not found`:
  - Recreate with `docker network create aio-network`.
- `feast apply` fails because parquet is missing:
  - Re-run `python prepare_feast_data.py` in feature repo folder.
- `dvc pull` fails:
  - If error is `NoSuchBucket`, your remote bucket is not accessible from your environment.
  - Continue with Branch B local-rebuild path in Section 4.
- Serving cannot load model from MLflow:
  - Re-check `MODEL_URI`, alias `champion`, and MLflow endpoint in `.env`.
- Airflow permission warning on Windows:
  - Keep `infra/docker/airflow/.env` with `AIRFLOW_UID=50000`.

## 10) Git commit and push (after each completed milestone)

From project root:

```powershell
Set-Location D:\StudyDocument\CongNgheMoi\btNhom\mlops_project
git status
```

Create a working branch (recommended):

```powershell
git checkout -b feat/re-implement-mlops-windows
```

Commit infra/docs fixes (example):

```powershell
git add infra/docker/monitor/docker-compose.yaml infra/docker/run.sh infra/k8s/deploy-dashboard.sh infra/k8s/teardown-dashboard.sh infra/docker/mlflow/.env.example RUN_SYSTEM_WINDOWS.md README.md
git commit -m "docs+infra: make Windows rerun flow reproducible"
```

Commit data artifacts you generated locally (only if your team policy allows):

```powershell
git add data-pipeline/data/processed/df_processed.csv data-pipeline/churn_feature_store/churn_features/feature_repo/data/processed_churn_data.parquet
git commit -m "data: regenerate local processed artifacts"
```

Push branch:

```powershell
git push -u origin feat/re-implement-mlops-windows
```

If repository requires PR, open Pull Request from this branch to `main`.
