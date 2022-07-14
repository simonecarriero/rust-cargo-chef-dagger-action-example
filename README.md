# Rust cargo-chef dagger action example

Example of Rust project using the [cargo-chef dagger action](https://github.com/simonecarriero/rust-cargo-chef-dagger-action)

## Build
* [install dagger](https://docs.dagger.io/)
* run `dagger do build`

## Run
* run `docker run app`

## Known issues
If you're using [colima](https://github.com/abiosoft/colima), the socket path is in `~/.colima/docker.sock` instead of `/var/run/docker.sock`.
You may change it in [dagger.cue](dagger.cue) or create a symlink with `sudo ln -s ~/.colima/docker.sock /var/run/docker.sock`.
