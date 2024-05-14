-- Execute Docker artifact release script according to build scoped DOCKER_DEPLOY_ENV

let Prelude = ../External/Prelude.dhall
let B = ../External/Buildkite.dhall

let B/If = B.definitions/commandStep/properties/if/Type

let Command = ./Base.dhall
let Size = ./Size.dhall

let Profiles = ../Constants/Profiles.dhall
let BuildFlags = ../Constants/BuildFlags.dhall

let Cmd = ../Lib/Cmds.dhall

let DockerLogin = ../Command/DockerLogin/Type.dhall


let ReleaseSpec = {
  Type = {
    deps : List Command.TaggedKey.Type,
    network: Text,
    service: Text,
    version: Text,
    branch: Text,
    repo: Text,
    deb_codename: Text,
    deb_release: Text,
    deb_version: Text,
    deb_profile: Profiles.Type,
    build_flags: BuildFlags.Type,
    extra_args: Text,
    step_key: Text,
    `if`: Optional B/If
  },
  default = {
    deps = [] : List Command.TaggedKey.Type,
    network = "devnet",
    version = "\\\${MINA_DOCKER_TAG}",
    service = "\\\${MINA_SERVICE}",
    branch = "\\\${BUILDKITE_BRANCH}",
    repo = "\\\${BUILDKITE_REPO}",
    deb_codename = "bullseye",
    deb_release = "\\\${MINA_DEB_RELEASE}",
    deb_version = "\\\${MINA_DEB_VERSION}",
    deb_profile = Profiles.Type.Standard,
    build_flags = BuildFlags.Type.None,
    extra_args = "",
    step_key = "daemon-standard-docker-image",
    `if` = None B/If
  }
}

let generateStep = \(spec : ReleaseSpec.Type) ->

    let commands : List Cmd.Type =
    [
        Cmd.run (
          "export MINA_DEB_CODENAME=${spec.deb_codename} && source ./buildkite/scripts/export-git-env-vars.sh && ./scripts/release-docker.sh " ++
              "--service ${spec.service} --version ${spec.version} --network ${spec.network} --branch ${spec.branch} --deb-codename ${spec.deb_codename} --deb-release ${spec.deb_release} --deb-version ${spec.deb_version} --deb-profile '${Profiles.lowerName spec.deb_profile} --deb-build-flag ${BuildFlags.to spec.build_flags}' --repo ${spec.repo} --extra-args \\\"${spec.extra_args}\\\""
        )
    ]

    in

    Command.build
      Command.Config::{
        commands  = commands,
        label = "Docker: ${spec.step_key}",
        key = spec.step_key,
        target = Size.XLarge,
        docker_login = Some DockerLogin::{=},
        depends_on = spec.deps,
        `if` = spec.`if`
      }

in

{ generateStep = generateStep, ReleaseSpec = ReleaseSpec }
