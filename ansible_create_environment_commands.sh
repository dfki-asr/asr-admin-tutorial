# Commands from section "Creating an Ansible environment for automation"

# 1. On RedHat distributions, like Fedora, RedHat Enterprise Linux, CentOS

sudo yum check-update;
sudo yum install -y python3 libselinux-python3 python3-pip git gnupg2 pinentry which sshpass pwgen;

# 2. On Ubuntu

sudo apt-get update -y;
sudo apt-get install -y --no-install-recommends python3-minimal python3-pip python3-venv git openssh-client gnupg pinentry-tty sshpass pwgen;

# 3. On Debian

sudo apt-get update -y;
sudo apt-get install -y --no-install-recommends python3 python3-pip python3-venv git openssh-client gnupg pinentry-tty sshpass pwgen;

# 4. Switch to the root directory with the cd command, then run

# Set variable ROOT_DIR to the path of the current directory
# PWD variable contains the path to the current working directory
# PWD means present working directory
ROOT_DIR=$PWD;
# Set variable PASSWORDS_DIR to the path to asr-admin-rookie-passwords directory
PASSWORDS_DIR=$ROOT_DIR/asr-admin-rookie-passwords;

# Set variable PROJECT_DIR to the project directory and create it
PROJECT_DIR=$ROOT_DIR/asr-rookie-ansible-project;
# The -p option means that mkdir will not fail if the directory exists and all parent directories are also created
mkdir -p "$PROJECT_DIR";

# Create the requirements.txt file with all Ansible dependencies.
# Ansible is written in Python, so the dependencies are specified in the requirements.txt file!
cat > "$PROJECT_DIR/requirements.txt" <<EOF
ansible==2.9.20
netaddr
pyyaml
jmespath
selinux
paramiko
requests
yamllint
ansible-lint[yamllint]
EOF

# Set VENV_DIR variable
VENV_DIR=$PROJECT_DIR/venv;

# Check and install virtualenv module if required
python3 -m venv --help >/dev/null || python3 -m pip install --user virtualenv;

# Create virtualenv if required
[[ ! -e "$VENV_DIR/bin/activate" ]] && ( \
    set -e; \
    VENV_PD=$(dirname -- "$VENV_DIR"); \
    VENV_BN=$(basename -- "$VENV_DIR");  \
    mkdir -p "$VENV_PD"; \
    pushd "$VENV_PD"; \
    python3 -m venv "$VENV_BN"; \
    popd; \
    . "$VENV_DIR/bin/activate"; \
    python3 -m pip install --upgrade pip; \
    deactivate; \
);

# Install requirements
( set -e; \
  . "$VENV_DIR/bin/activate"; \
  set -x;  python3 -m pip install -r "$PROJECT_DIR/requirements.txt"; \
);

# In order to activate installed ansible environment run
cd "$PROJECT_DIR";
. venv/bin/activate;

# 5. Create Ansible inventory

mkdir -p "$PROJECT_DIR/inventory";
cat > "$PROJECT_DIR/inventory/hosts.ini" <<EOF
asr-novgorod ansible_host=usg-demo-6.sb.dfki.de ansible_port=2223
asr-verona ansible_host=usg-demo-6.sb.dfki.de ansible_port=2224
EOF

# 6. Decrypt private key

(cd "$PASSWORDS_DIR"; \
 blackbox_decrypt_file passwords/cluster_rookie_id_ecdsa; \
 chmod go-rwx passwords/cluster_rookie_id_ecdsa; )

# Running ad-hoc Ansible commands

# 7. Run ping command

cd "$PROJECT_DIR";
ansible -u cluster-rookie \
        --private-key "$PASSWORDS_DIR/passwords/cluster_rookie_id_ecdsa" \
        -i inventory/hosts.ini all -m ping;

# 8. Execute shell commands on all hosts

ansible -u cluster-rookie \
        --private-key "$PASSWORDS_DIR/passwords/cluster_rookie_id_ecdsa" \
        -i inventory/hosts.ini all -m shell -a 'hostname; whoami; ls -la;';

# Using inventory variables

# 9. Create hosts.ini file

# Note that the variables PROJECT_DIR and PASSWORDS_DIR must be defined
# when you execute the next command !
cat > "$PROJECT_DIR/inventory/hosts.ini" <<EOF
[frank]
asr-novgorod ansible_port=2223
asr-verona ansible_port=2224
[frank:vars]
ansible_host=usg-demo-6.sb.dfki.de
ansible_user=cluster-rookie
ansible_ssh_private_key_file=$PASSWORDS_DIR/passwords/cluster_rookie_id_ecdsa
EOF

# 10. Shorter Ansible commands

cd "$PROJECT_DIR";
ansible -i inventory/hosts.ini all -m ping;
ansible -i inventory/hosts.ini all -m shell -a 'hostname; whoami; ls -la;';

# 11. Run whoami

ansible -i inventory/hosts.ini all -m shell -a whoami;

# 12. Run whoami in become mode

ansible -i inventory/hosts.ini all --become --ask-become-pass -m shell -a 'whoami';

# Using encrypted variables

# 13. Decrypt encrypted password before use

ansible -i inventory/hosts.ini all --become \
 --extra-vars ansible_become_password="$(cd "$PASSWORDS_DIR"; \
 blackbox_cat "passwords/cluster-rookie-password.txt.gpg")" \
 -m shell -a 'whoami';

# 14.

# Create random password in ~/.ansible/my-vault-pass.txt file
# if it does not already exist
mkdir -p ~/.ansible; \
 [ ! -s ~/.ansible/my-vault-pass.txt ] && \
 pwgen -s 20 1 > ~/.ansible/my-vault-pass.txt;

# 15.

# Create a directory for all variables for our group frank
# Ansible will automatically read all YAML and encrypted files there and try to load them as variables
mkdir -p "$PROJECT_DIR/inventory/group_vars/frank";
# Create file with the secret variable
cat > "$PROJECT_DIR/inventory/group_vars/frank/vault.yml" <<EOF
vault_ansible_become_password: "$(cd "$PASSWORDS_DIR"; \
blackbox_cat "passwords/cluster-rookie-password.txt.gpg")"
EOF
# Encrypt our secret
ansible-vault encrypt \
 --vault-password-file ~/.ansible/my-vault-pass.txt \
 "$PROJECT_DIR/inventory/group_vars/frank/vault.yml";

 # 16. Edit contents of the vault file interactively

ansible-vault edit --vault-password-file ~/.ansible/my-vault-pass.txt \
                   "$PROJECT_DIR/inventory/group_vars/frank/vault.yml";

# 17.

ansible -i inventory/hosts.ini all \
        --vault-password-file ~/.ansible/my-vault-pass.txt \
        -m debug -a 'var=vault_ansible_become_password';

# 18.

cat > "$PROJECT_DIR/inventory/group_vars/frank/vars.yml" <<EOF
ansible_become_password: "{{ vault_ansible_become_password }}"
EOF

# 19.

ansible -i inventory/hosts.ini all \
        --vault-password-file ~/.ansible/my-vault-pass.txt \
        -m debug -a 'var=ansible_become_password';

# 20.

ansible -i inventory/hosts.ini all  \
        --vault-password-file ~/.ansible/my-vault-pass.txt \
        --become -m shell -a 'whoami';

# 21.

ansible-inventory -i inventory/hosts.ini    --vault-password-file ~/.ansible/my-vault-pass.txt --graph all;

# 22.

ansible-inventory -i inventory/hosts.ini    --vault-password-file ~/.ansible/my-vault-pass.txt --host asr-verona;

# 23. Run check-host.yml playbook

ansible-playbook -i inventory/hosts.ini  --vault-password-file ~/.ansible/my-vault-pass.txt check-host.yml;
