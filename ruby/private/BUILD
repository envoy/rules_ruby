load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

exports_files([
    "bundle_install/bundle_install.cmd.tpl",
    "bundle_install/bundle_install.sh.tpl",
    "bundle_install/prepare_bundle_path.rb.tpl",
    "gem_build/gem_builder.rb.tpl",
    "gem_install/gem_install.cmd.tpl",
    "gem_install/gem_install.sh.tpl",
])

bzl_library(
    name = "binary",
    srcs = ["binary.bzl"],
    visibility = ["//ruby:__subpackages__"],
    deps = [
        ":library",
        ":providers",
    ],
)

bzl_library(
    name = "gem_build",
    srcs = ["gem_build.bzl"],
    visibility = ["//ruby:__subpackages__"],
    deps = [
        ":library",
        ":providers",
    ],
)

bzl_library(
    name = "gem_push",
    srcs = ["gem_push.bzl"],
    visibility = ["//ruby:__subpackages__"],
    deps = [
        ":binary",
        ":library",
    ],
)

bzl_library(
    name = "library",
    srcs = ["library.bzl"],
    visibility = ["//ruby:__subpackages__"],
    deps = [":providers"],
)

bzl_library(
    name = "test",
    srcs = ["test.bzl"],
    visibility = ["//ruby:__subpackages__"],
    deps = [
        ":binary",
        ":library",
    ],
)

bzl_library(
    name = "toolchain",
    srcs = ["toolchain.bzl"],
    visibility = ["//ruby:__subpackages__"],
    deps = [
        ":download",
        "//ruby/private/toolchain:repository_proxy",
    ],
)

bzl_library(
    name = "bundle_fetch",
    srcs = ["bundle_fetch.bzl"],
    visibility = ["//ruby:__subpackages__"],
    deps = ["//ruby/private/bundle_fetch:gemfile_lock_parser"],
)

bzl_library(
    name = "bundle_install",
    srcs = ["bundle_install.bzl"],
    visibility = ["//ruby:__subpackages__"],
    deps = [
        ":gem_install",
        ":providers",
    ],
)

bzl_library(
    name = "gem",
    srcs = ["gem.bzl"],
    visibility = ["//ruby:__subpackages__"],
    deps = [":providers"],
)

bzl_library(
    name = "gem_install",
    srcs = ["gem_install.bzl"],
    visibility = ["//ruby:__subpackages__"],
    deps = [":providers"],
)

bzl_library(
    name = "bundle",
    srcs = ["bundle.bzl"],
    visibility = ["//ruby:__subpackages__"],
)

bzl_library(
    name = "download",
    srcs = ["download.bzl"],
    visibility = ["//ruby:__subpackages__"],
)

bzl_library(
    name = "providers",
    srcs = ["providers.bzl"],
    visibility = ["//ruby:__subpackages__"],
)

bzl_library(
    name = "utils",
    srcs = ["utils.bzl"],
    visibility = ["//ruby:__subpackages__"],
)
