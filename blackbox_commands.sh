# Commands from section "Blackbox"

# 1. Clone password repository

git clone git@github.com:dfki-asr/asr-admin-rookie-passwords.git;
cd asr-admin-rookie-passwords; # Change to the directory of the cloned repository.
PASSWORD_REPOSITORY=$PWD;      # Save current working directory in the PASSWORD_REPOSITORY variable.
cd -;                          # Return to the previous directory.
# Later you can use following command to enter the password repository directory immediately:
cd "$PASSWORD_REPOSITORY";

# 2.

git clone https://github.com/StackExchange/blackbox;
cd blackbox;
cp bin/* ~/.local/bin/;

# 3.

git clone https://github.com/StackExchange/blackbox;
cd blackbox;
make PREFIX=$HOME/.local copy-install;

# 4.

gpg --gen-key;

# 5.

cd "$PASSWORD_REPOSITORY";
blackbox_addadmin jodo01@dfki.de;

# 6.

cd "$PASSWORD_REPOSITORY";
git commit -m'NEW ADMIN: jodo01@dfki.de' .blackbox/pubring.kbx .blackbox/trustdb.gpg .blackbox/blackbox-admins.txt;
git push;

# 7.

cd "$PASSWORD_REPOSITORY";
gpg --homedir=.blackbox --list-keys;

# 9.

cd "$PASSWORD_REPOSITORY";
# Update repository,
# using the --rebase option is usually safer than without it.
git pull --rebase;
# Decrypt all files
blackbox_decrypt_all_files;

# 10.

# Pre-check: Verify the new keys look good.
git pull --rebase;
gpg --homedir=.blackbox --list-keys;

# Import the keychain into your personal keychain and reencrypt:
gpg --no-default-keyring --keyring .blackbox/pubring.gpg  --export --armor | gpg --import;
gpg --no-default-keyring --keyring .blackbox/pubring.kbx  --export --armor | gpg --import;

# Re-encrypt all files
blackbox_update_all_files;

# Push newly encrypted files
git push;

# 11.

cd "$PASSWORD_REPOSITORY";
gpg --no-default-keyring --keyring .blackbox/pubring.gpg  --export --armor | gpg --import;
gpg --no-default-keyring --keyring .blackbox/pubring.kbx  --export --armor | gpg --import;
