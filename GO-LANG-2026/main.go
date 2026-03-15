package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"path/filepath"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/util/homedir"
)

// Key Components Explained:
// - rest.InClusterConfig(): Uses service account credentials mounted at
//   /var/run/secrets/kubernetes.io/serviceaccount/ when this binary runs in-cluster.
// - clientcmd.BuildConfigFromFlags: Parses local ~/.kube/config so you can test
//   against live clusters during development before deploying.
// - context.Context: Required by modern client-go API calls and enables timeout/
//   cancellation patterns for unresponsive API servers.
// - The Clientset: kubernetes.NewForConfig(config) returns the primary typed
//   interface (CoreV1 for Pods/Nodes, AppsV1 for Deployments, etc.).

func main() {
	// Define the kubeconfig flag for local development.
	var kubeconfig *string
	if home := homedir.HomeDir(); home != "" {
		kubeconfig = flag.String("kubeconfig", filepath.Join(home, ".kube", "config"), "(optional) absolute path to the kubeconfig file")
	} else {
		kubeconfig = flag.String("kubeconfig", "", "absolute path to the kubeconfig file")
	}
	flag.Parse()

	// First try in-cluster config, then fall back to local kubeconfig.
	config, err := rest.InClusterConfig()
	if err != nil {
		fmt.Println("Not running in-cluster, falling back to local kubeconfig...")
		config, err = clientcmd.BuildConfigFromFlags("", *kubeconfig)
		if err != nil {
			fmt.Printf("Error building kubeconfig: %s\n", err.Error())
			os.Exit(1)
		}
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		fmt.Printf("Error creating clientset: %s\n", err.Error())
		os.Exit(1)
	}

	// context.Background() satisfies modern client-go context requirements.
	ctx := context.Background()
	pods, err := clientset.CoreV1().Pods("default").List(ctx, metav1.ListOptions{})
	if err != nil {
		fmt.Printf("Error listing pods: %s\n", err.Error())
		os.Exit(1)
	}

	fmt.Printf("Success! Found %d pods in the 'default' namespace.\n", len(pods.Items))
	for _, pod := range pods.Items {
		fmt.Printf("- %s\n", pod.Name)
	}
}
