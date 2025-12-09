#!/bin/bash
# Infrastructure Management Launcher
# Source this or run it to set up your environment

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Set workspace
export INFRA_WORKSPACE="/tmp/k8s-deployments"
export KUBECONFIG="/root/KUBEDB/kubeconfig.yaml"

# Change to workspace
cd "$INFRA_WORKSPACE" 2>/dev/null || {
    echo -e "${YELLOW}Warning: Workspace not found at $INFRA_WORKSPACE${NC}"
}

# Display banner
echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Infrastructure Management System                       ║"
echo "║     Dokploy + Kubernetes Hybrid Architecture               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Quick status check
echo -e "${BLUE}Checking infrastructure status...${NC}"
echo ""

# Check Tailscale
if tailscale status &>/dev/null; then
    echo -e "  Tailscale:  ${GREEN}Connected${NC}"
else
    echo -e "  Tailscale:  ${YELLOW}Not connected - run 'tailscale up'${NC}"
fi

# Check kubectl
if kubectl get nodes &>/dev/null; then
    NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    echo -e "  Kubernetes: ${GREEN}$NODE_COUNT nodes ready${NC}"
else
    echo -e "  Kubernetes: ${YELLOW}Cannot connect${NC}"
fi

# Check ArgoCD
if kubectl get pods -n argocd 2>/dev/null | grep -q Running; then
    APP_COUNT=$(kubectl get applications -n argocd --no-headers 2>/dev/null | wc -l)
    echo -e "  ArgoCD:     ${GREEN}Running ($APP_COUNT apps)${NC}"
else
    echo -e "  ArgoCD:     ${YELLOW}Not accessible${NC}"
fi

echo ""
echo -e "${BLUE}Access URLs:${NC}"
echo "  ArgoCD Dashboard:  https://100.97.89.1:30443 (admin/62FThsisGJ9jnCDj)"
echo "  Dokploy UI:        http://100.120.113.6:3000"
echo "  Hello World:       http://100.97.89.1:30888"
echo "  pgAdmin:           http://100.97.89.1:30080"
echo "  Doppler:           https://dashboard.doppler.com/workplace/projects/k8s-apps"
echo ""

echo -e "${BLUE}Quick Commands:${NC}"
echo "  deploy-app <name>      - Start deploying a new app"
echo "  k get pods             - List all pods"
echo "  k get apps -n argocd   - List ArgoCD applications"
echo "  k logs -f deploy/<app> - Follow app logs"
echo ""

# Aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kga='kubectl get applications -n argocd'
alias kl='kubectl logs -f'
alias argocd-sync='kubectl annotate application $1 -n argocd argocd.argoproj.io/refresh=hard --overwrite'

# Helper function to deploy new app
deploy-app() {
    local APP_NAME=$1
    if [ -z "$APP_NAME" ]; then
        echo "Usage: deploy-app <app-name>"
        return 1
    fi

    echo "Creating deployment structure for: $APP_NAME"
    mkdir -p "$INFRA_WORKSPACE/apps/$APP_NAME"

    echo "Next steps:"
    echo "1. Create deployment.yaml, service.yaml, kustomization.yaml in apps/$APP_NAME/"
    echo "2. Create ArgoCD application in argocd/$APP_NAME.yaml"
    echo "3. Push Docker image to ghcr.io/akaich00/$APP_NAME"
    echo "4. git add -A && git commit -m 'Add $APP_NAME' && git push"
    echo ""
    echo "Or ask Claude: 'Deploy $APP_NAME to production'"
}

# Export function
export -f deploy-app 2>/dev/null

echo -e "${GREEN}Ready! Run 'claude' to start Claude Code${NC}"
echo ""
