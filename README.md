# scirate-jobs 

This is an elm app+hasura database backend that implements part of the 'jobs'
functionality on SciRate.

## Hacking locally

### Tools

Local development is best done via
[nix](https://nixos.org/guides/install-nix.html), as well as the following
tools (installed outside of nix):

- [direnv](https://direnv.net/)
- [logody](https://github.com/sordina/logody)
- [docker](https://www.docker.com/get-started) and [docker-compose](https://docs.docker.com/compose/install/)

### Docker-compose note

In order to use the `docker-compose` command, you'll need to decide if you
want a host-provided database (on your computer) or a docker-provided one. If
in doubt, use the docker-provided one, so just symlink that as your main
compose file:

```
ln -s docker-compose-docker-postgres.yaml docker-compose.yaml
```


### Env vars

You'll need the following environment variables set, in order to run
everything:

```
export POSTGRES_PASSWORD=...
export HASURA_GRAPHQL_ADMIN_SECRET=...
export HASURA_GRAPHQL_JWT_SECRET=...
export HASURA_GRAPHQL_DATABASE_URL=...
export HASURA_GRAPHQL_ENABLE_CONSOLE=true
export SCIRATE_ROOT_DIR=...
```

Using `direnv` you can put these in `.envrc` and then do `direnv allow` and
everything will work!

Once you have the tools above installed and the environment variables set all
setup you can jump into a nix-shell:

```
nix-shell
```

and then you have the following commands:

- `elm reactor` to run the elm reactor dev webserver,
- `localBuild` to compile the Elm into the `public` folder,
- `releaseBuild` to compile and compress and copy it to your copy of SciRate
- `hasura ...` to run hasura cli commands!


To spin up hasura and the reactor server, we can use `logody` like so:

```
logody
```

this spins up a docker-managed postgres database, the hasura console (if you
configured your env var as such), the hasura graphql endpoint, and the elm
reactor webserver.

Then, the services are running here:
- Hasura: <http://localhost:8080>,
- Elm Reactor: <http://localhost:8001>

The final step will be to put your own `JWT` tokens in the html pages in the
`public` folder. (This is a bit hacky and could be cleaned up.)


# FAQ

- **Q: Why hasura?**
- A: I didn't want to mess with the SciRate database, so I thought
     the easiest way to maintain and clean separation.

- **Q: Why Elm?**
- A: It's fun!
