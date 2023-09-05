package main

import (
	"encoding/json"
	"fmt"
	"github.com/google/uuid"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/exec"
)

var port string = "8000"

type Payload struct {
	Repository struct {
		CloneURL      string `json:"clone_url"`
		DefaultBranch string `json:"default_branch"`
	} `json:"repository"`
}

func main() {
	http.HandleFunc("/auto-deploy", payloadHandler)

	fmt.Println("Server listening on port " + port + "...")
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

func payloadHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == "POST" {
		body, err := ioutil.ReadAll(r.Body)
		if err != nil {
			http.Error(w, "Failed to read request body", http.StatusInternalServerError)
			return
		}
		defer r.Body.Close()

		var payload Payload
		err = json.Unmarshal(body, &payload)
		if err != nil {
			http.Error(w, "Failed to parse JSON body", http.StatusBadRequest)
			return
		}

		var UUID string = uuid.New().String()

		fmt.Println("Clone URL:", payload.Repository.CloneURL)
		fmt.Println("Default Branch:", payload.Repository.DefaultBranch)
		fmt.Println("UUID:", UUID)

		os.Setenv("__GIT_REPO__", payload.Repository.CloneURL)
		os.Setenv("__GIT_BRANCH__", payload.Repository.DefaultBranch)
		os.Setenv("__UUID__", UUID)

		exec.Command("docker", "volume", "create", "auto-deploy-"+UUID)
		exec.Command("docker-compose", "up")
	} else {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
}
