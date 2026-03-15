apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  # name must match the spec fields below: <plural>.<group>
  name: volumemirrors.storage.example.com
spec:
  group: storage.example.com
  versions:
    - name: v1alpha1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                sourceVolumeId:
                  type: string
                destinationZone:
                  type: string
                replicationMode:
                  type: string
                  enum: ["Synchronous", "Asynchronous"]
              required: ["sourceVolumeId", "destinationZone"]
            status:
              type: object
              properties:
                phase:
                  type: string
                lastSyncedTime:
                  type: string
                  format: date-time
      # This enables the /status subresource used in Challenge 3
      subresources:
        status: {}
      additionalPrinterColumns:
        - name: Status
          type: string
          jsonPath: .status.phase
        - name: Age
          type: string
          jsonPath: .metadata.creationTimestamp
  scope: Namespaced
  names:
    plural: volumemirrors
    singular: volumemirror
    kind: VolumeMirror
    shortNames:
    - vmirror




/*
1. The OpenAPI v3 Schema
This is where you define the "types" for your Go structs. When you use tools like controller-gen, it reads this YAML (or your Go comments) to ensure that users can't submit invalid data (like an incorrect enum value).

2. The Status Subresource
Notice the subresources: status: {} line. As discussed in the coding challenge, this is critical. It allows your Go controller to update the status without needing permission to modify the spec.

3. Additional Printer Columns
This is a "pro-tip" feature. By adding these, when a user runs kubectl get vmirror, they will see custom columns like Status and Age directly in the terminal output, rather than just the name.

How to use this in Go
In a real interview, they might ask: "How do you make Go understand this YAML?"

Define Structs: Create a Go struct that mirrors the spec and status fields.

Code Generation: Use the K8s Code Generator (or Kubebuilder) to create "DeepCopy" methods. Kubernetes requires these so it can safely clone objects in memory.

Register with Scheme: Tell your Go client about this new "GroupVersion" so it knows how to serialize and deserialize the data.


*/
