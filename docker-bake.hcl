variable "TAG_FROM_GIT_SHA" {
  default = "latest"
}
variable "TAG_FROM_GIT_REF_NAME" {
  default = "latest"
}
// only CI should push images and caches
// you *could* push from a local machine in an emergency,
// by setting this to "true" in the `docker buildx bake` command
variable "CAN_PUSH" {
  default = false
}
// workarounds for missing multi-node registry cache, tracked in #218
variable "ARCH" {
  default = "linux/amd64"
}
variable "CAN_CACHE" {
  default = false
}

// every image should be tagged with sha and ref name
// both default to "latest" when unset, so it's the same in that case
function "compose_tags_field" {
  params = [image_name_stage]
  result = [
    "${REGISTRY_PREFIX_CI}/${IMAGE_OWNER}/${IMAGE_NAME_ROOT}/${image_name_stage}:${TAG_FROM_GIT_SHA}",
    "${REGISTRY_PREFIX_CI}/${IMAGE_OWNER}/${IMAGE_NAME_ROOT}/${image_name_stage}:${TAG_FROM_GIT_REF_NAME}",
    "${REGISTRY_PREFIX_PRIMARY}/${IMAGE_OWNER}/${IMAGE_NAME_ROOT}/${image_name_stage}:${TAG_FROM_GIT_SHA}",
    "${REGISTRY_PREFIX_PRIMARY}/${IMAGE_OWNER}/${IMAGE_NAME_ROOT}/${image_name_stage}:${TAG_FROM_GIT_REF_NAME}"
  ]
}

// workaround for missing multi-node registry cache, tracked in #218
// should also cache to other registries, tracked in #219
function "compose_cache_to_field" {
  params = [image_name_stage]
  result = flatten([concat([
    "${CAN_CACHE}" ?
      "type=registry,ref=${REGISTRY_PREFIX_CI}/${IMAGE_OWNER}/${IMAGE_NAME_ROOT}/${image_name_stage}/cache/${ARCH}:${TAG_FROM_GIT_REF_NAME},mode=max" :
      "type=inline"
  ])])
}

// caches first in the below order are tried first
// 1) try the git ref in question
// 2) try main as the backup source
// 3) cache fail (no problem, just gets rebuild)
// notice that caching from some branch locally may lead to a cache miss on GHCR
// because some local branch may not exist on GHCR
function "compose_cache_from_field" {
  params = [image_name_stage]
  // should also cache from other registries, tracked in #219
  result = [
    "type=registry,ref=${REGISTRY_PREFIX_CI}/${IMAGE_OWNER}/${IMAGE_NAME_ROOT}/${image_name_stage}/cache/linux/arm64:${TAG_FROM_GIT_REF_NAME}",
    "type=registry,ref=${REGISTRY_PREFIX_CI}/${IMAGE_OWNER}/${IMAGE_NAME_ROOT}/${image_name_stage}/cache/linux/amd64:${TAG_FROM_GIT_REF_NAME}",
    "type=registry,ref=${REGISTRY_PREFIX_CI}/${IMAGE_OWNER}/${IMAGE_NAME_ROOT}/${image_name_stage}/cache/linux/arm64:${DEFAULT_BRANCH}",
    "type=registry,ref=${REGISTRY_PREFIX_CI}/${IMAGE_OWNER}/${IMAGE_NAME_ROOT}/${image_name_stage}/cache/linux/amd64:${DEFAULT_BRANCH}"
  ]
}

group "default" {
  targets = [
    "builder",
    "developer",
    "runner"
  ]
}

group "devcontainer" {
  targets = [
    "developer",
    "rstudio"
  ]
}

// get nice labels from the github context
// tags are enot, but should also be taken from here, tracked in #220
target "docker-metadata-action" {}

target "default" {
  inherits = [
    "docker-metadata-action"
  ]
  dockerfile = "onbuild.Dockerfile"
  secret = ["id=GH_TOKEN"]
  // multiplatform build does not work with output docker
  // see https://github.com/docker/buildx/issues/59
  platforms = or(CAN_PUSH, CAN_CACHE) ? ["linux/amd64,linux/arm64"] : []
  output = or(CAN_PUSH, CAN_CACHE) ? ["type=registry"] : ["type=docker"]
}

target "runner" {
  inherits = [
    "default"
  ]
  target = "runner"
  cache-from = compose_cache_from_field("runner")
  cache-to = compose_cache_to_field("runner")
  tags = compose_tags_field("runner")
}

target "builder" {
  inherits = [
    "default"
  ]
  target = "builder"
  cache-from = compose_cache_from_field("builder")
  cache-to = compose_cache_to_field("builder")
  tags = compose_tags_field("builder")
}

target "developer" {
  inherits = [
    "default"
  ]
  target = "developer"
  cache-from = compose_cache_from_field("developer")
  cache-to = compose_cache_to_field("developer")
  tags = compose_tags_field("developer")
}

target "rstudio" {
  inherits = [
    "default"
  ]
  target = "rstudio"
  cache-from = compose_cache_from_field("rstudio")
  cache-to = compose_cache_to_field("rstudio")
  tags = compose_tags_field("rstudio")
}
