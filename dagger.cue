package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
	"universe.dagger.io/docker/cli"
	"github.com/simonecarriero/rust-cargo-chef-dagger-action/cargochef"
)

dagger.#Plan & {

	client: {
		filesystem: ".": read: contents: dagger.#FS
		network: "unix:///var/run/docker.sock": connect: dagger.#Socket
	}

	actions: {

		cargochefBuild: cargochef.#Build & {
			projectDirectory: client.filesystem.".".read.contents
			rustDockerImage:  "rust:1.62.0-slim"
			workdir:          "/app"
			cargoBuildArgs: ["--release", "--bin", "app"]
		}

		runtime: docker.#Build & {
			steps: [
				docker.#Pull & {
					source: "debian:bullseye-slim"
				},
				docker.#Set & {
					config: workdir: "/app"
				},
				docker.#Copy & {
					contents: cargochefBuild.output.rootfs
					source:   "/app/target/release/app"
					dest:     "/usr/local/bin"
				},
				docker.#Set & {
					config: entrypoint: ["/usr/local/bin/app"]
				},
			]
		}

		build: cli.#Load & {
			image: runtime.output
			host:  client.network."unix:///var/run/docker.sock".connect
			tag:   "app"
		}
	}
}
