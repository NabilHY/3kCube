echo "=========> Deploying apps <========="
kubectl apply -f /vagrant/confs/app1.yaml
kubectl apply -f /vagrant/confs/app2.yaml
kubectl apply -f /vagrant/confs/app3.yaml
kubectl apply -f /vagrant/confs/ingress.yaml


echo "=========> Waiting for apps pods to be ready <========="
kubectl wait --for=condition=Ready pods --all --timeout=120s

echo "=========> apps deployed <========="
kubectl get pods -o wide
kubectl get ingress
