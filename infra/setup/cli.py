import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any, Dict, List, Optional

import typer
import yaml

app = typer.Typer(help="Interactive + non-interactive setup for Hetzner k3s (Terraform)")

ROOT = Path(__file__).resolve().parents[2]  # repo root
TF_DIR = ROOT / "infra" / "hetzner"
DEFAULTS: Dict[str, Any] = {
    "cluster_name": "k3s",
    "location": "fsn1",
    "control_plane_server_type": "cx31",
    "agent_server_type": "cx31",
    "agent_count": 2,
    "enable_public_ssh": False,
    "enable_public_k8s_api": False,
    "allowed_ssh_cidrs": [],
    "allowed_k8s_api_cidrs": [],
    "tailscale_authkey": None,
    "tailscale_tags": ["tag:k8s"],
    "ssh_public_key_path": str(Path.home() / ".ssh" / "id_ed25519.pub"),
}

DATABASE_CHOICES = ["postgres", "mysql", "redis", "none"]


def _run(cmd: List[str], cwd: Path) -> None:
    proc = subprocess.run(cmd, cwd=str(cwd), text=True)
    if proc.returncode != 0:
        typer.secho(f"Command failed: {' '.join(cmd)}", fg=typer.colors.RED)
        sys.exit(proc.returncode)


def _load_answers(path: Path) -> Dict[str, Any]:
    if not path.exists():
        typer.secho(f"Answers file not found: {path}", fg=typer.colors.RED)
        sys.exit(1)
    data = yaml.safe_load(path.read_text()) if path.suffix in {".yaml", ".yml"} else json.loads(path.read_text())
    if not isinstance(data, dict):
        typer.secho("Answers file must be a mapping", fg=typer.colors.RED)
        sys.exit(1)
    return data


def _resolve_env_refs(data: Dict[str, Any]) -> Dict[str, Any]:
    resolved = {}
    for k, v in data.items():
        if isinstance(v, str) and v.startswith("env:"):
            env_key = v.split(":", 1)[1]
            resolved[k] = os.environ.get(env_key)
        else:
            resolved[k] = v
    return resolved


def _prompt_missing(cfg: Dict[str, Any], starters: List[str]) -> Dict[str, Any]:
    cfg = dict(cfg)
    if cfg.get("cluster_name") in (None, ""):
        cfg["cluster_name"] = typer.prompt("Cluster name", default=DEFAULTS["cluster_name"])
    if cfg.get("location") in (None, ""):
        cfg["location"] = typer.prompt("Hetzner location", default=DEFAULTS["location"])
    if cfg.get("control_plane_server_type") in (None, ""):
        cfg["control_plane_server_type"] = typer.prompt("Control-plane server type", default=DEFAULTS["control_plane_server_type"])
    if cfg.get("agent_server_type") in (None, ""):
        cfg["agent_server_type"] = typer.prompt("Agent server type", default=DEFAULTS["agent_server_type"])
    if cfg.get("agent_count") in (None, ""):
        cfg["agent_count"] = int(typer.prompt("Agent count", default=str(DEFAULTS["agent_count"])))

    cfg["enable_public_ssh"] = typer.confirm(
        "Expose SSH (22) publicly?", default=bool(cfg.get("enable_public_ssh", DEFAULTS["enable_public_ssh"]))
    )
    if cfg["enable_public_ssh"] and not cfg.get("allowed_ssh_cidrs"):
        cidr = typer.prompt("Allowed SSH CIDR", default="0.0.0.0/0")
        cfg["allowed_ssh_cidrs"] = [cidr]

    cfg["enable_public_k8s_api"] = typer.confirm(
        "Expose Kubernetes API (6443) publicly?", default=bool(cfg.get("enable_public_k8s_api", DEFAULTS["enable_public_k8s_api"]))
    )
    if cfg["enable_public_k8s_api"] and not cfg.get("allowed_k8s_api_cidrs"):
        cidr = typer.prompt("Allowed Kubernetes API CIDR", default="0.0.0.0/0")
        cfg["allowed_k8s_api_cidrs"] = [cidr]

    if cfg.get("ssh_public_key_path") in (None, ""):
        cfg["ssh_public_key_path"] = typer.prompt("SSH public key path", default=DEFAULTS["ssh_public_key_path"])

    if cfg.get("tailscale_authkey") in (None, ""):
        cfg["tailscale_authkey"] = typer.prompt("Tailscale auth key (recommended, enter to skip)", default="", hide_input=True) or None

    if cfg.get("tailscale_tags") in (None, ""):
        cfg["tailscale_tags"] = DEFAULTS["tailscale_tags"]

    # Optional: pick database + starter app
    db_choice = typer.prompt(
        f"Choose database {DATABASE_CHOICES}",
        default="none",
    )
    cfg["database_choice"] = db_choice if db_choice in DATABASE_CHOICES else "none"

    if starters:
        typer.echo("Available starters: " + ", ".join(starters))
        starter = typer.prompt("Select starter app (or leave blank)", default="")
        cfg["starter_app"] = starter or None
    else:
        cfg["starter_app"] = None

    return cfg


def _gather_starters() -> List[str]:
    apps_dir = ROOT / "apps"
    if not apps_dir.exists():
        return []
    return sorted([p.name for p in apps_dir.iterdir() if p.is_dir()])


def _write_tfvars(cfg: Dict[str, Any]) -> Path:
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".tfvars.json")
    Path(tmp.name).write_text(json.dumps(cfg, indent=2))
    return Path(tmp.name)


def _print_summary(cfg: Dict[str, Any]) -> None:
    redacted = cfg.copy()
    if redacted.get("tailscale_authkey"):
        redacted["tailscale_authkey"] = "***"
    typer.secho("Configuration:", fg=typer.colors.CYAN)
    typer.echo(json.dumps(redacted, indent=2))


def _ensure_tools() -> None:
    for tool in ("terraform",):
        if not shutil.which(tool):
            typer.secho(f"Missing required tool: {tool}", fg=typer.colors.RED)
            sys.exit(1)


@app.command()
def apply(
    answers: Optional[Path] = typer.Option(None, help="Path to answers YAML/JSON for non-interactive runs."),
    auto_approve: bool = typer.Option(False, help="Pass -auto-approve to terraform apply."),
    interactive: bool = typer.Option(True, help="Prompt for missing values."),
):
    """Generate tfvars and run terraform apply."""
    starters = _gather_starters()

    cfg = dict(DEFAULTS)
    if answers:
        loaded = _resolve_env_refs(_load_answers(answers))
        cfg.update({k: v for k, v in loaded.items() if v is not None})
    if interactive:
        cfg = _prompt_missing(cfg, starters)

    _print_summary(cfg)
    tfvars = _write_tfvars(cfg)
    typer.echo(f"Using tfvars: {tfvars}")

    cmd = ["terraform", "apply", f"-var-file={tfvars}"]
    if auto_approve:
        cmd.append("-auto-approve")

    _run(["terraform", "init", "-input=false"], TF_DIR)
    _run(cmd, TF_DIR)

    typer.echo("Apply complete. Fetch kubeconfig using the control-plane IP from terraform outputs:")
    typer.echo("  terraform output control_plane_public_ip")
    typer.echo("Then: ssh root@<IP> 'sudo cat /etc/rancher/k3s/k3s.yaml' > kubeconfig && sed -i '' 's/127.0.0.1/<IP>/g' kubeconfig")


@app.command()
def plan(
    answers: Optional[Path] = typer.Option(None, help="Path to answers YAML/JSON for non-interactive runs."),
    interactive: bool = typer.Option(True, help="Prompt for missing values."),
):
    """Generate tfvars and run terraform plan."""
    starters = _gather_starters()

    cfg = dict(DEFAULTS)
    if answers:
        loaded = _resolve_env_refs(_load_answers(answers))
        cfg.update({k: v for k, v in loaded.items() if v is not None})
    if interactive:
        cfg = _prompt_missing(cfg, starters)

    _print_summary(cfg)
    tfvars = _write_tfvars(cfg)
    typer.echo(f"Using tfvars: {tfvars}")

    _run(["terraform", "init", "-input=false"], TF_DIR)
    _run(["terraform", "plan", f"-var-file={tfvars}"], TF_DIR)


@app.command()
def kubeconfig(ip: str = typer.Argument(..., help="Control-plane IP (public or Tailscale)") ):
    """Fetch kubeconfig from the control-plane and rewrite server to the given IP."""
    out_path = Path("kubeconfig")
    cmd = f"ssh root@{ip} 'sudo cat /etc/rancher/k3s/k3s.yaml'"
    typer.echo(f"Fetching kubeconfig from {ip} ...")
    result = subprocess.run(cmd, shell=True, text=True, capture_output=True)
    if result.returncode != 0:
        typer.secho(result.stderr, fg=typer.colors.RED)
        sys.exit(result.returncode)
    content = result.stdout.replace("127.0.0.1", ip)
    out_path.write_text(content)
    typer.echo(f"Wrote kubeconfig -> {out_path}. Export with: export KUBECONFIG={out_path}")


if __name__ == "__main__":
    import shutil
    _ensure_tools()
    app()
