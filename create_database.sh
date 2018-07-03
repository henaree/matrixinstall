#!/bin/bash
touch create_database.psql
read -sp "Password: " $synapse_user_passwd
export $synapse_user_passwd
cat > create_database.psql << EOF
CREATE USER synapse_user WITH PASSWORD '$synapse_user_passwd';

CREATE DATABASE synapse (
ENCODING 'UTF8'
LC_COLLATE='C'
LC_CTYPE='C'
template=template0
OWNER synapse_user
);
EOF
