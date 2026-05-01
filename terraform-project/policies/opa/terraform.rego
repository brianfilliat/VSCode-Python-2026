package terraform.training

deny[msg] {
  resource := input.resource_changes[_]
  resource.change.after.tags
  not resource.change.after.tags.environment
  msg := sprintf("%s must include an environment tag", [resource.address])
}

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "local_file"
  endswith(resource.change.after.filename, ".secret")
  msg := sprintf("%s must not write files ending in .secret", [resource.address])
}
