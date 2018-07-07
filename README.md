# matrixinstall

A series of scripts that will automate some or all of the parts of the matrix install

# Compatibility

This has been run and tested on CentOS Linux release 7.5.1804 (Core)


# Usage

Currently only the prerequisites and initial synapse installation has been automated. Firewall ports, nginx, Postgresql database setup and matrix useage creation are currently manual.

Get the script and make it executable

```bash
wget https://github.com/henaree/matrixinstall/blob/master/dependencyinstall.sh
chmod u+x dependencyinstall.sh
```

Then run it

```
sudo ./dependencyinstall.sh
```

Enter in the requested input, and the script will create a synapse install with a homesever.yaml file genereated to match the donain name you entered.

# After installation

Now that the script has run, there are some manual parts to complete before we can run synapse.

## Step 1. Create Postgresql Database

Create a database cluster:

```bash
sudo postgresql-setup initdb
```

Enable md5 authentication

```bash
sudo vi /var/lib/pgsql/data/pg_hba.conf
```

Find these lines

```
host		all		all		127.0.0.1/32		ident
host		all		all		::1/128			ident
```

Replace ```ident``` with ```md5```

```
host		all		all		127.0.0.1/32		md5
host		all		all		::1/128			md5
```
Now start and enable PostgreSQL:

```bash
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

Log in to the postgres user account that was automatically created during installation

```bash
sudo -i -u postgres
```

Create a new user called ```synapse_user``` and assign it a password

```bash
createuser --pwprompt synapse_user
```
enter the postgresql cli by entering command ```psql```

Create a database called ```synapse```

```postgresql
CREATE DATABASE synapse
ENCODING 'UTF8'
LC_COLLATE='C'
LC_CTYPE='C'
template=template0
OWNER synapse_user;
```

Exit the propmpt by typing ```\q```


## Step 2. Adding Postgresql Database to Synapse

Edit the homeserver.yaml file

```bash
vi ~/.synapse homeserver.yaml
```

Edit the ```#database configuration``` section to resemble the following

```homeserver.yaml
database:
    name: psycopg2
    args:
        user: <user>
        password: <pass>
        database: <db>
        host: <host>
        cp_min: 5
        cp_max: 10
```
In this case, ```<user>``` should be ```synapse_user```,```<pass>``` should be the password you set during the user set up, ```db``` is ```synapse``` and ```<host>``` should be ```/var/run/postgresql```

We need to make a dumb change to the pg_hba.conf cus idk why. Something is up the way authentication is being handled.

Deactivate virtual environment by entering the command ```deactivate```

edit pg_hba.conf

```bash
sudo vi /var/lib/pgsql/data/pg_hba.conf
```

Find this line

```
local   	all            all                                     	peer
```

and change it to

```
host		all		all				md5
```

Now stop and start postgres again

```bash
sudo systemctl stop postgresql
sudo systemctl start postgresql
```

Step 3. Start Synapse and Create a new user

Start Synapse

```bash
cd ~/.synapse 
source ~/.synapse/bin/activate
synctl start
```

Create a new user. Username will display publicly as @username:domain.com

```bash
register_new_matrix_user -c homeserver.yaml http://localhost:8008
```

### TODO:

-add nginx configuration, firwall ports, lets ecnrypt

