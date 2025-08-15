#!/usr/bin/env bash
# Shared helper for kustomize + ksops environment setup.
# Usage: source this file, then call run_kustomize_build <environment> or use ensure_ksops_plugin then invoke kustomize yourself.

set -euo pipefail

parse_deploy_args() {
  # Accept long flags passed directly to the script and set usage_* vars
  while ((${#})); do
    case "$1" in
      --provider)
        usage_provider="${2:-}"
        shift 2
        ;;
      --provider=*)
        usage_provider="${1#*=}"
        shift 1
        ;;
      --environment)
        usage_environment="${2:-}"
        shift 2
        ;;
      --environment=*)
        usage_environment="${1#*=}"
        shift 1
        ;;
      --context)
        usage_context="${2:-}"
        shift 2
        ;;
      --context=*)
        usage_context="${1#*=}"
        shift 1
        ;;
      --)
        shift; break
        ;;
      *)
        # Ignore unknown args; they might be consumed upstream
        shift 1
        ;;
    esac
  done
  export usage_provider usage_environment usage_context
}

ensure_env() {
  if [ -z "${usage_provider:-}" ]; then
    echo "Provider is required (-p/--provider)" >&2
    exit 1
  fi
  if [ -z "${usage_environment:-}" ]; then
    echo "Environment is required" >&2
    exit 1
  fi
}

create_ephemeral_plugin_home() {
  _tmp_plugin_root=$(mktemp -d 2>/dev/null || mktemp -d -t kplugs)
  export KUSTOMIZE_PLUGIN_HOME="$_tmp_plugin_root"
  trap 'rm -rf "$_tmp_plugin_root" || true' EXIT INT TERM
}

wire_ksops() {
  ksops_bin=$(mise which ksops 2>/dev/null || command -v ksops || { echo "ksops binary not found on PATH" >&2; exit 2; })
  plugin_dir="$KUSTOMIZE_PLUGIN_HOME/viaduct.ai/v1/ksops"
  mkdir -p "$plugin_dir"
  ln -s "$ksops_bin" "$plugin_dir/ksops" 2>/dev/null || true
}

ensure_ksops_plugin() {
  ensure_env
  create_ephemeral_plugin_home
  wire_ksops
}

kustomize_build() {
  kustomize build --enable-helm --enable-alpha-plugins "$@"
}

run_kustomize_build() {
  local env="$1"
  kustomize_build "k8s/stacks/${usage_provider}/$env"
}

kubectl_apply() {
  local extra=( )
  if [ -n "${usage_context:-}" ]; then
    extra+=("--context=${usage_context}")
  fi

  kubectl apply \
    -f - \
    --server-side \
    --force-conflicts \
    --wait=true \
    --timeout=60s \
    --field-manager=deploy \
    "${extra[@]}" \
    "$@"
}
