# CI/CD Pipeline Setup Guide

Dự án này có 3 GitHub Actions workflows tự động:

## 1. **CI Pipeline** (`.github/workflows/ci.yml`)
Chạy tự động khi push lên `main` hoặc `develop`, hoặc khi tạo Pull Request.

✅ **Những gì nó làm:**
- Test data-pipeline
- Test model-pipeline  
- Test serving-pipeline
- Build Docker images
- Kiểm tra code quality (linting, formatting)

### Thời gian chạy: ~10-15 phút

---

## 2. **Build and Push Docker** (`.github/workflows/build-and-push.yml`)
Chạy khi push vào `main` và có thay đổi trong thư mục `serving_pipeline/` hoặc `infra/docker/`.

✅ **Những gì nó làm:**
- Build serving pipeline image
- Build UI image
- Build Airflow image
- Lưu images cục bộ (hoặc push lên registry nếu bạn enable)

### Enable push lên Docker Registry:
1. Đến GitHub Repo → Settings → Secrets and variables → Actions
2. Thêm secrets:
   - `REGISTRY_URL` (Docker Hub hoặc private registry)
   - `REGISTRY_USERNAME`
   - `REGISTRY_PASSWORD`
3. Uncomment phần "Login to Docker Registry" và "Push" images trong workflow file

---

## 3. **Deploy to Kubernetes** (`.github/workflows/deploy-k8s.yml`)
Chạy manual hoặc tự động khi push vào `main`.

✅ **Những gì nó làm:**
- Deploy Airflow
- Deploy Kafka
- Deploy MLflow
- Deploy PostgreSQL
- Deploy Minio
- Deploy Serving Pipeline

### Enable deployment:
1. **Chuẩn bị kubeconfig:**
   ```bash
   cat ~/.kube/config | base64 -w 0
   ```
2. **Đến GitHub Repo → Settings → Secrets → ADD Secret:**
   - Name: `KUBE_CONFIG`
   - Value: Base64-encoded kubeconfig từ bước trên

3. **Trigger deployment:**
   - Push vào `main` branch, hoặc
   - Vào "Actions" tab → Select workflow → "Run workflow" button

---

## Setup Steps

### Step 1: Cấu hình Git (nếu chưa có)
```bash
git config --global user.name "Tên của bạn"
git config --global user.email "email@example.com"
```

### Step 2: Commit và push các workflow files
```bash
cd mlops_project
git add .
git commit -m "Add CI/CD workflows"
git push origin main
```

### Step 3: Checkout GitHub Actions
- Vào repo trên GitHub
- Click "Actions" tab
- Chọn workflow để xem chi tiết

### Step 4: (Optional) Setup Kubernetes Deployment

Nếu bạn có Kubernetes cluster:

1. **Chuẩn bị kubeconfig:**
   - Lấy từ cluster của bạn
   - Encode thành base64

2. **Thêm vào GitHub Secrets:**
   ```
   Settings → Secrets and variables → Actions → New repository secret
   Name: KUBE_CONFIG
   Value: <your-base64-encoded-kubeconfig>
   ```

3. **Deploy:**
   - Vào Actions tab
   - Chọn "Deploy to Kubernetes"
   - Click "Run workflow"

---

## Debugging Tips

### View Workflow Logs
1. Vào GitHub repo → Actions tab
2. Click vào workflow run
3. Click vào job để xem detailed logs

### Common Issues

**Problem: "Python module not found"**
- Kiểm tra `requirements.txt` có đầy đủ dependencies không
- Kiểm tra Python version (project dùng Python 3.9)

**Problem: Docker build failed**
- Kiểm tra Dockerfile syntax
- Kiểm tra tất cả dependencies trong requirements.txt

**Problem: Kubernetes deployment failed**
- Kiểm tra kubeconfig validity
- Kiểm tra cluster access: `kubectl cluster-info`
- Kiểm tra YAML syntax

---

## Customization

### Thay đổi Python version
Edit `ci.yml`, tìm:
```yaml
python-version: '3.9'
```
Đổi sang phiên bản khác (ví dụ: '3.10', '3.11')

### Thêm thêm test frameworks
Trong `ci.yml` thêm:
```yaml
- name: Install pytest
  run: pip install pytest

- name: Run tests
  run: pytest tests/
```

### Schedule CI chạy định kỳ
Thêm vào đầu workflow file:
```yaml
on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM UTC every day
```

---

## Next Steps

1. ✅ Push workflows lên GitHub
2. ✅ Kiểm tra Actions tab xem CI chạy không
3. ⚠️ Fix bất kỳ lỗi nào
4. 🔑 Setup secrets nếu cần deploy
5. 🚀 Trigger deployment (manual hoặc auto)

---

**Cần giúp? Kiểm tra GitHub Actions logs để xem chi tiết lỗi!**
