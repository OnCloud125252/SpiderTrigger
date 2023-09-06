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

	log.Fatal(http.ListenAndServe(":"+port, nil))
	fmt.Println("Server listening on port " + port + " ...")
	fmt.Println("Auto deploy path: /auto-deploy")
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

		composeUp := exec.Command("./builder.sh", "GIT_REPO="+payload.Repository.CloneURL, "GIT_BRANCH="+payload.Repository.DefaultBranch, "ID="+strconv.Itoa(payload.Repository.ID))
		composeUp.Stdout = os.Stdout
		composeUp.Stderr = os.Stderr
		composeUpError := composeUp.Run()
		if composeUpError != nil {
			fmt.Fprint(w, "Failed to deploy: "+composeUpError.Error())
			http.Error(w, "Failed to deploy: "+composeUpError.Error(), http.StatusInternalServerError)
			return
		}

		fmt.Fprint(w, "Deployment successful")
	} else {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
}
