# GKE Cost Management & Monitoring Guide

## 💰 Cost Estimation & Management

### Monthly Cost Breakdown (Estimated)

#### Standard GKE Cluster (e2-standard-2 × 3 nodes)

- **Compute Engine**: ~$120/month
- **GKE Management Fee**: ~$70/month
- **Load Balancer**: ~$18/month
- **Persistent Disks**: ~$10/month
- **Network Egress**: ~$5/month
- **Total**: ~$220/month

#### GKE Autopilot (Recommended for Learning)

- **Pod Resources**: ~$40-80/month (based on actual usage)
- **No management fees**
- **Automatic optimization**
- **Total**: ~$60/month

### 💡 Cost Optimization Tips

1. **Use Autopilot for Learning:**

   ```bash
   gcloud container clusters create-auto todo-app-autopilot --region us-central1
   ```

2. **Enable Cluster Autoscaler:**

   ```bash
   --enable-autoscaling --min-nodes 1 --max-nodes 3
   ```

3. **Use Preemptible Instances (50-90% cheaper):**

   ```bash
   --preemptible
   ```

4. **Set Resource Limits:**
   ```yaml
   resources:
     requests:
       memory: "128Mi"
       cpu: "100m"
     limits:
       memory: "256Mi"
       cpu: "200m"
   ```

### 📊 Visual Cost Monitoring

#### GCP Console Cost Monitoring:

1. **Billing Console**: https://console.cloud.google.com/billing
2. **Navigate to**: Billing > Reports
3. **Filter by**: Service = "Kubernetes Engine"
4. **Set up**: Budget alerts at $50, $100, $150

#### Real-time Cost Commands:

```bash
# Check current costs
gcloud billing budgets list --billing-account=YOUR_BILLING_ACCOUNT

# Monitor resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Check cluster info
gcloud container clusters describe todo-app-cluster --region us-central1
```

### 🔧 Resource Right-sizing

#### Monitor Resource Usage:

```bash
# Install metrics server (if not present)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Check resource usage
kubectl top nodes
kubectl top pods -A

# Get resource recommendations
gcloud container clusters describe todo-app-cluster --region us-central1 | grep -A 10 "resourceUsageExportConfig"
```

#### Recommended Instance Types by Usage:

- **Light Testing**: `e2-micro` or `e2-small`
- **Development**: `e2-standard-2`
- **Production**: `e2-standard-4` or higher

### ⚠️ Cost Alerts & Cleanup

#### Set Up Budget Alerts:

1. Go to **GCP Console > Billing > Budgets & Alerts**
2. Create budget for your project
3. Set threshold alerts at 50%, 80%, 100%
4. Add email notifications

#### Cleanup Commands (to avoid charges):

```bash
# Delete the cluster (saves ~80% of costs)
gcloud container clusters delete todo-app-cluster --region us-central1

# Delete container images (saves storage costs)
gcloud container images list --repository=gcr.io/YOUR_PROJECT_ID
gcloud container images delete gcr.io/YOUR_PROJECT_ID/IMAGE_NAME

# Delete persistent volumes
kubectl get pv
kubectl delete pv PV_NAME
```

### 🎯 Best Practices for Learning

1. **Use Autopilot**: Pay only for what you use
2. **Delete cluster nightly**: Automate cleanup
3. **Monitor daily costs**: Set up alerts
4. **Use development resources**: Lower CPU/memory limits
5. **Clean up regularly**: Don't leave resources running

### 📅 Recommended Learning Schedule

- **Week 1**: Deploy on Autopilot, basic testing
- **Week 2**: Standard cluster, scaling experiments
- **Week 3**: Production-like setup with monitoring
- **Week 4**: Cost optimization and cleanup

**Total estimated learning cost: $100-200 for complete hands-on experience**
