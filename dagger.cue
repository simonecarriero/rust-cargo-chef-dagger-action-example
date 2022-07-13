package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
	"universe.dagger.io/docker/cli"
)

dagger.#Plan & {

	client: {
		filesystem: ".": read: contents: dagger.#FS
		network: "unix:///var/run/docker.sock": connect: dagger.#Socket
	}

	actions: {

		chef: docker.#Build & {
			steps: [
				docker.#Pull & {
					source: "rust:1.62.0-slim"
				},
				docker.#Run & {
					command: {
						name: "cargo"
						args: ["install", "cargo-chef"]
					}
				},
				docker.#Set & {
					config: workdir: "/app"
				},
			]
		}

		planner: docker.#Build & {
			steps: [
				chef,
				docker.#Copy & {
					contents: client.filesystem.".".read.contents
					dest:     "."
				},
				docker.#Run & {
					command: {
						name: "cargo"
						args: ["chef", "prepare", "--recipe-path", "recipe.json"]
					}
				},
			]
		}

		builder: docker.#Build & {
			steps: [
				chef,
				docker.#Copy & {
					contents: planner.output.rootfs
					source:   "/app/recipe.json"
					dest:     "recipe.json"
				},
				docker.#Run & {
					command: {
						name: "cargo"
						args: ["chef", "cook", "--release", "--recipe-path", "recipe.json"]
					}
				},
				docker.#Copy & {
					contents: client.filesystem.".".read.contents
					source:   "."
					dest:     "."
				},
				docker.#Run & {
					command: {
						name: "cargo"
						args: ["build", "--release", "--bin", "app"]
					}
				},
			]
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
					contents: builder.output.rootfs
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
