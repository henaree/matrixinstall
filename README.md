# matrixinstall

A series of scripts that will automate some or all of the parts of the matrix install

# Compatibility

This has been run and tested on CentOS Linux release 7.5.1804 (Core)


# Usage

Currently only the prerequisites and initial synapse installation has been automated. Firewall ports, nginx, Postgresql database setup and matrix user creation are currently manual.

Get the script and make it executable

```bash
wget https://rawgit.com/henaree/matrixinstall/master/dependencyinstall.sh
chmod u+x dependencyinstall.sh
```

Then run it

```
sudo ./dependencyinstall.sh
```

Enter in the requested input, and the script will create a synapse install with a homesever.yaml file genereated to match the domain name you entered.

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

Create a new user called ```synapse_user``` and assign a password to it

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

Exit the postgres user session by typing ```exit```

## Step 2. Adding Postgresql Database to Synapse

Edit the homeserver.yaml file

```bash
vi ~/.synapse/homeserver.yaml
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

We need to make a dumb change to the pg_hba.conf cus idk why. Something is up with the way authentication is being handled.

edit pg_hba.conf

```bash
sudo vi /var/lib/pgsql/data/pg_hba.conf
```

Find this line

```
local   	all            all                              peer
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

### Step 3. Start Synapse and Create a new user

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
## Step 4. Configuring nginx

Edit nginx config file

```bash
sudo vi /etc/nginx/nginx.conf
```

Find ```server{``` and ammend it to match the following 

```
server{
	# File upload limit. Currently set to match synapse limit
	client_max_body_size 10M;
	
	# Server name, match this to the domain name you set running dependencyinstall.sh
      	server_name example.com www.example.com;

        # Log location. Change to match server_name
      	access_log /var/log/nginx/example.com.access_log main;
      	error_log /var/log/nginx/example.com info;

      	# This is where we put the files we want on our site
       	root /usr/share/nginx/html;



      	# Here's where it gets interesting: This will send any path that starts
      	# with /_matrix to our Synapse!

      	location /_matrix {
      	proxy_pass http://localhost:8008;
     	}
}
```

Verify the syntax of the edited ```nginx.conf```

```
sudo nginx -t
```

If no errors, reload nginx

```
sudo systemctl reload nginx
```

### Step 5. Let's Encrypt!

Before you start this step, make sure your router is forwarding port 80 and 443 from your servers IP address. Check https://portforward.com/ for more information

Use certbot to fetch a certificate

```
sudo certbot --nginx -d example.com -d www.example.com
```

Automate certbot with ```crontab```

```
sudo crontab -e
```

Your text editor will open the default crontab which is an empty text file at this point. Paste in the following line, then save and close it:

```
. . .
15 3 * * * /usr/bin/certbot renew --preferred-challenges http --quiet
```

The ```15 3 * * *``` part of this line means “run the following command at 3:15 am, every day”. You may choose any time.

The renew command for Certbot will check all certificates installed on the system and update any that are set to expire in less than thirty days. –quiet tells Certbot not to output information or wait for user input.

cron will now run this command daily. All installed certificates will be automatically renewed and reloaded when they have thirty days or less before they expire.


