package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"os/signal"
	"syscall"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/watch"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

func main() {
	// 1. Setup connection (Standard boilerplate)
	kubeconfig := flag.String("kubeconfig", os.Getenv("HOME")+"/.kube/config", "path to kubeconfig")
	flag.Parse()
	config, _ := clientcmd.BuildConfigFromFlags("", *kubeconfig)
	clientset, _ := kubernetes.NewForConfig(config)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// 2. Handle OS signals for graceful shutdown
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	// 3. Initialize the Watcher
	namespace := "default"
	watcher, err := clientset.CoreV1().ConfigMaps(namespace).Watch(ctx, metav1.ListOptions{
		// You could use a label selector here to watch specific ConfigMaps
		// LabelSelector: "app=myapp",
	})
	if err != nil {
		fmt.Printf("Error starting watch: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Watching ConfigMaps in namespace: %s...\n", namespace)

	// 4. Consume the Event Channel
	go func() {
		for event := range watcher.ResultChan() {
			// The event contains the Type (ADDED, MODIFIED, DELETED) and the Object
			switch event.Type {
			case watch.Modified:
				fmt.Printf("ConfigMap modified! Triggering reload logic...\n")
				// In a real app, you would cast the object to access its data:
				// cm := event.Object.(*corev1.ConfigMap)
			case watch.Deleted:
				fmt.Printf("Warning: A ConfigMap was deleted.\n")
			case watch.Error:
				fmt.Printf("Error event received.\n")
			}
		}
	}()

	<-sigCh
	fmt.Println("Shutting down watcher...")
}
