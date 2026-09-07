#!/bin/bash
function aws-profile() {
  local profile
  profile=$(aws configure list-profiles | fzf) && export AWS_PROFILE="$profile"
  if [[ -n $profile ]]; then
    echo "AWS_PROFILE set to $profile"
  else
    echo "No profile selected or no profiles available."
    return 0
  fi

  if ! aws sts get-caller-identity | grep -q "SSO"; then
    aws sso login
  fi
}

function aws-set-current-account-id () {
  AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  export AWS_ACCOUNT_ID
  echo "AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID"
}
function digitalocean ()
{
  curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $DIGITALOCEAN_API_TOKEN" "https://api.digitalocean.com/v2/$1?page=1&per_page=1000" | python -m json.tool
}

function da ()
{
  # Select a docker container to start and attach to
  local cid
  cid=$(docker ps -a | sed 1d | fzf -1 -q "$1" | awk '{print $1}')

  [ -n "$cid" ] && docker start "$cid" && docker attach "$cid"
}
function ds ()
{
  # Select a running docker container to stop
  local cid
  cid=$(docker ps | sed 1d | fzf -q "$1" | awk '{print $1}')

  [ -n "$cid" ] && docker stop "$cid"
}

function dlogs ()
{
  # Select a docker container (running or stopped) and stream its logs
  local cid
  cid=$(docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" \
    | sed 1d \
    | fzf -1 -q "$1" \
    | awk '{print $1}')

  [ -n "$cid" ] && docker logs -f --timestamps "$cid"
}
function supabase-profile() {
  local cfg="${SUPABASE_PROFILES:-$HOME/.config/supabase/profiles.tsv}"

  # Create config if missing
  if [[ ! -f "$cfg" ]]; then
    mkdir -p "$(dirname "$cfg")"
    umask 077
    cat > "$cfg" <<'EOF'
# name<TAB>token<TAB>project_ref(optional)<TAB>url(optional)
work	<paste-work-token-here>	<project-ref>	https://<project>.supabase.co
personal	<paste-personal-token-here>	<project-ref>	https://<project>.supabase.co
EOF
    chmod 600 "$cfg"
    echo "Created $cfg — please fill in your tokens and rerun." >&2
    return 1
  fi

  local sel name line token proj url
  sel="$(
    awk -F'\t' 'BEGIN{OFS="\t"} /^[^#]/ && NF>=2 {
      name=$1; token=$2; proj=(NF>=3?$3:""); url=(NF>=4?$4:"");
      mask=substr(token,1,6) "…" substr(token,length(token)-3,4);
      print name, (proj?proj:"—"), (url?url:"—"), mask
    }' "$cfg" \
    | fzf --header=$'Select a Supabase profile\n(name\tproject\turl\t(token masked))' \
          --with-nth=1,2,3 \
          --preview-window=down,3,wrap \
          --preview 'printf "Name: %s\nProject: %s\nURL: %s\nToken: %s\n" {1} {2} {3} {4}'
  )" || return 1
  [[ -n "$sel" ]] || return 1

  name=$(awk -F'\t' '{print $1}' <<<"$sel")
  line="$(awk -F'\t' -v n="$name" '/^[^#]/ && $1==n {print; exit}' "$cfg")" || return 1
  IFS=$'\t' read -r _ token proj url <<<"$line"

  export SUPABASE_ACCESS_TOKEN="$token"
  if [[ -n "$proj" ]]; then
    export SUPABASE_PROJECT_REF="$proj"
  else
    unset SUPABASE_PROJECT_REF
  fi
  if [[ -n "$url" ]]; then
    export SUPABASE_URL="$url"
  else
    unset SUPABASE_URL
  fi

  echo "Activated Supabase profile: $name  (project: ${proj:-n/a})"
}
function tf ()
{
  if [ -n "$1" ]
  then
    local SCRIPT="terraform $*"
    echo "$SCRIPT"
    echo
    eval "$SCRIPT"
  else
    histgrep terraform
  fi
}
alias gc='gcloud compute'
alias gci='gcloud compute instances'
alias k='kubectl'
alias kd='kubectl describe'
alias kg='kubectl get pods,rc,svc,ing -o wide --show-labels'
alias proxy-mini='ssh -D 8001 tbomini-remote'
alias remote-mini='ssh -L 9000:localhost:5900 -L 35729:localhost:35729 -L 4200:localhost:4200 -L 3000:localhost:3000 -L 8090:localhost:8090 -L 8000:localhost:8000 tbomini-remote'
alias sb='supabase'
alias setdotglob='shopt -s dotglob'
alias survey='sudo nmap -sP 10.0.1.1/24'
alias sb-profile='supabase-profile'
alias sso='aws sso login --sso-session tribou'
