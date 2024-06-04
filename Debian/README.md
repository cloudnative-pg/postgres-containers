# Debian-based Container Images

This folder contains the `Dockerfile` manifests needed to build Debian-based
PostgreSQL operand container images for use with CloudNativePG.

The images are based on the official [PostgreSQL images on
DockerHub](https://hub.docker.com/_/postgres).

The folder includes:

- Directories for each supported PostgreSQL version.
- [Image catalog
  files](https://cloudnative-pg.io/documentation/current/image_catalog/) for
each Debian version.
- Templates for the main `Dockerfile` and the beta version `Dockerfile`
  (typically identical, except for some extensions that are not ready for the
  new major release of PostgreSQL).
- The `requirements.in` file required to build Barman Cloud images. (Note: This
  file will be removed once a Barman Cloud plugin supporting CNPG-I is
  distributed.)
- The main update script.

## Adding a New Beta Version

To add a new beta version, follow these steps:

1. Create a new issue in the ["postgres-containers" project](https://github.com/cloudnative-pg/postgres-containers)
   with the title "Add PostgreSQL XX beta1 images".
2. Clone the `postgres-containers` repository.
3. Create a new branch named after the issue ID (e.g., `dev/YYY`).
4. Create the `Debian/XX/` directory.
5. Identify the latest Debian version name (e.g., `bookworm`).
6. Run `Debian/update.sh XX -d bookworm` which will create a
   `.versions.json` file into the `Debian/XX/bookworm/` directory.
7. Add the new directory to your commit and push the changes.
8. Run the `Automatic updates` action on the branch and wait for it to complete
   (this will add a commit to the branch).
9. Submit a pull request.


## Troubleshooting

### Common issues

* Error while running `update.sh`

```
sed: can't read requirements.txt: No such file or directory
cat: requirements.txt: No such file or directory
rm: cannot remove 'requirements.txt': No such file or directory
```

If a similar error appears, the reason is that you are missing the
`pip-compile` utility that's needed to build the python requirements
for Barman Cloud. (Note: This requirement will be removed once a
Barman Cloud plugin supporting CNPG-I is distributed.)
