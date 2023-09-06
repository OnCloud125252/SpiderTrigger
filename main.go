package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strconv"
)

var port string = "8000"

type Payload struct {
	Repository struct {
		ID            int    `json:"id"`
		CloneURL      string `json:"clone_url"`
		DefaultBranch string `json:"default_branch"`
	} `json:"repository"`
}

func main() {
	http.HandleFunc("/auto-deploy", payloadHandler)

	fmt.Println("Server listening on port " + port + " ...")
	fmt.Println("Auto deploy path: /auto-deploy")
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

		if payload.Repository.CloneURL == "" {
			http.Error(w, "Missing CloneURL in payload", http.StatusBadRequest)
			return
		}

		if payload.Repository.DefaultBranch == "" {
			http.Error(w, "Missing DefaultBranch in payload", http.StatusBadRequest)
			return
		}

		RepoURL := payload.Repository.CloneURL
		DefaultBranch := payload.Repository.DefaultBranch
		RepoID := strconv.Itoa(payload.Repository.ID)
		go func() {
			composeUp := exec.Command("./builder.sh", "REPO_URL="+RepoURL, "DEFAULT_BRANCH="+DefaultBranch, "REPO_ID="+RepoID)
			composeUp.Stdout = os.Stdout
			composeUp.Stderr = os.Stderr
			composeUpError := composeUp.Run()
			if composeUpError != nil {
				fmt.Println("Deployment failed for "+RepoID+": ", composeUpError)
			} else {
				fmt.Println("Deployment for " + RepoID + " successful")
			}
		}()

		fmt.Fprint(w, "Deployment for "+RepoID+" started")
	} else {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
}
