@echo off
REM Infrastructure Management Launcher for Windows
REM Double-click this file to open WSL with Claude Code ready

REM Launch WSL, cd to workspace, and start Claude Code
wsl.exe -e bash -c "cd /tmp/k8s-deployments && export KUBECONFIG=/root/KUBEDB/kubeconfig.yaml && echo '=== Infrastructure Workspace Ready ===' && echo '' && echo 'Quick Commands:' && echo '  claude        - Start Claude Code' && echo '  kubectl get pods -A' && echo '  kubectl get applications -n argocd' && echo '' && echo 'Access URLs:' && echo '  ArgoCD:    https://100.97.89.1:30443' && echo '  Dokploy:   http://100.120.113.6:3000' && echo '  HelloWorld: http://100.97.89.1:30888' && echo '' && exec bash"

pause
