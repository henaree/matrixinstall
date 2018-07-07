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

TODO:

- Enter instructions for Firewall ports, nginx, Postgresql database setup and matrix useage creation.



